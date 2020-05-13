#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Server::PSGI;

use strict;
use warnings;

use Carp;

use base qw( Net::Async::HTTP::Server );

our $VERSION = '0.13';

use HTTP::Response;

my $CRLF = "\x0d\x0a";

=head1 NAME

C<Net::Async::HTTP::Server::PSGI> - use C<PSGI> applications with C<Net::Async::HTTP::Server>

=head1 SYNOPSIS

 use Net::Async::HTTP::Server::PSGI;
 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $httpserver = Net::Async::HTTP::Server::PSGI->new(
    app => sub {
       my $env = shift;

       return [
          200,
          [ "Content-Type" => "text/plain" ],
          [ "Hello, world!" ],
       ];
    },
 );

 $loop->add( $httpserver );

 $httpserver->listen(
    addr => { family => "inet6", socktype => "stream", port => 8080 },
 )->get;

 $loop->run;

=head1 DESCRIPTION

This subclass of L<Net::Async::HTTP::Server> allows an HTTP server to use a
L<PSGI> application to respond to requests. It acts as a gateway between the
HTTP connection from the web client, and the C<PSGI> application. Aside from
the use of C<PSGI> instead of the C<on_request> event, this class behaves
similarly to C<Net::Async::HTTP::Server>.

To handle the content length when sending responses, the PSGI implementation
may add a header to the response. When sending a plain C<ARRAY> of strings, if
a C<Content-Length> header is absent, the length will be calculated by taking
the total of all the strings in the array, and setting the length header. When
sending content from an IO reference or using the streaming responder C<CODE>
reference, the C<Transfer-Encoding> header will be set to C<chunked>, and all
writes will be performed as C<HTTP/1.1> chunks.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=over 8

=item app => CODE

Reference to the actual C<PSGI> application to use for responding to requests

=back

=cut

sub configure
{
   my $self = shift;
   my %args = @_;

   if( exists $args{app} ) {
      $self->{app} = delete $args{app};
   }

   $self->SUPER::configure( %args );
}

=head1 PSGI ENVIRONMENT

The following extra keys are supplied to the environment of the C<PSGI> app:

=over 8

=item C<psgix.io>

The actual L<IO::Socket> filehandle that the request was received on.

If the server is running under SSL for HTTPS, this will be an
L<IO::Socket::SSL> instance, so reading from or writing to it will happen in
cleartext.

=item C<net.async.http.server>

The C<Net::Async::HTTP::Server::PSGI> object serving the request

=item C<net.async.http.server.req>

The L<Net::Async::HTTP::Server::Request> object representing this particular
request

=item C<io.async.loop>

The L<IO::Async::Loop> object that the C<Net::Async::HTTP::Server::PSGI>
object is a member of.

=back

=cut

sub on_request
{
   my $self = shift;
   my ( $req ) = @_;

   # Much of this code stolen fro^W^Winspired by Plack::Handler::Net::FastCGI

   open my $stdin, "<", \$req->body;

   my $socket = $req->stream->read_handle;

   my $path_info = $req->path;
   $path_info = "" if $path_info eq "/";

   my %env = (
      SERVER_PORT         => $socket->sockport,
      SERVER_NAME         => $socket->sockhost,
      SERVER_PROTOCOL     => $req->protocol,
      SCRIPT_NAME         => '',
      PATH_INFO           => $path_info,
      QUERY_STRING        => $req->query_string // "",
      REMOTE_ADDR         => $socket->peerhost,
      REMOTE_PORT         => $socket->peerport,
      REQUEST_METHOD      => $req->method,
      REQUEST_URI         => $req->path,
      'psgi.version'      => [1,0],
      'psgi.url_scheme'   => "http",
      'psgi.input'        => $stdin,
      'psgi.errors'       => \*STDERR,
      'psgi.multithread'  => 0,
      'psgi.multiprocess' => 0,
      'psgi.run_once'     => 0,
      'psgi.nonblocking'  => 1,
      'psgi.streaming'    => 1,

      # Extensions
      'psgix.io'                  => $socket,
      'psgix.input.buffered'      => 1, # we're using a PerlIO scalar handle
      'net.async.http.server'     => $self,
      'net.async.http.server.req' => $req,
      'io.async.loop'             => $self->get_loop,
   );

   foreach ( $req->headers ) {
      my ( $name, $value ) = @$_;
      $name =~ s/-/_/g;
      $name = uc $name;

      # Content-Length and Content-Type don't get HTTP_ prefix
      $name = "HTTP_$name" unless $name =~ m/^CONTENT_(?:LENGTH|TYPE)$/;

      $env{$name} = $value;
   }

   my $resp = $self->{app}->( \%env );

   my $responder = sub {
      my ( $status, $headers, $body ) = @{ +shift };

      my $response = HTTP::Response->new( $status );
      $response->protocol( $req->protocol );

      my $has_content_length = 0;
      my $use_chunked_transfer;
      while( my ( $key, $value ) = splice @$headers, 0, 2 ) {
         $response->header( $key, $value );

         $has_content_length = 1 if $key eq "Content-Length";
         $use_chunked_transfer++ if $key eq "Transfer-Encoding" and $value eq "chunked";
      }

      if( !defined $body ) {
         croak "Responder given no body in void context" unless defined wantarray;

         unless( $has_content_length ) {
            $response->header( "Transfer-Encoding" => "chunked" );
            $use_chunked_transfer++;
         }

         $req->write( $response->as_string( $CRLF ) );

         return $use_chunked_transfer ?
            Net::Async::HTTP::Server::PSGI::ChunkWriterStream->new( $req ) :
            Net::Async::HTTP::Server::PSGI::WriterStream->new( $req );
      }
      elsif( ref $body eq "ARRAY" ) {
         unless( $has_content_length ) {
            my $len = 0;
            my $found_undef;
            $len += length( $_ // ( $found_undef++, "" ) ) for @$body;
            carp "Found undefined value in PSGI body" if $found_undef;

            $response->content_length( $len );
         }

         $req->write( $response->as_string( $CRLF ) );

         $req->write( $_ ) for @$body;
         $req->done;
      }
      else {
         unless( $has_content_length ) {
            $response->header( "Transfer-Encoding" => "chunked" );
            $use_chunked_transfer++;
         }

         $req->write( $response->as_string( $CRLF ) );

         if( $use_chunked_transfer ) {
            $req->write( sub {
               # We can't return the EOF chunk and set undef in one go
               # What we'll have to do is send the EOF chunk then clear $body,
               # which indicates end
               return unless defined $body;

               local $/ = \8192;
               my $buffer = $body->getline;

               # Form HTTP chunks out of it
               defined $buffer and
                  return sprintf( "%X$CRLF%s$CRLF", length $buffer, $buffer );

               $body->close;
               undef $body;
               return "0$CRLF$CRLF";
            } );
         }
         else {
            $req->write( sub {
               local $/ = \8192;
               my $buffer = $body->getline;

               defined $buffer and return $buffer;

               $body->close;
               return undef;
            } );
         }

         $req->done;
      }
   };

   if( ref $resp eq "ARRAY" ) {
      $responder->( $resp );
   }
   elsif( ref $resp eq "CODE" ) {
      $resp->( $responder );
   }
}

# Hide from indexer
package
   Net::Async::HTTP::Server::PSGI::WriterStream;

sub new
{
   my $class = shift;
   return bless [ @_ ], $class;
}

sub write { shift->[0]->write( $_[0] ) }
sub close { shift->[0]->done }

# Hide from indexer
package
   Net::Async::HTTP::Server::PSGI::ChunkWriterStream;

sub new
{
   my $class = shift;
   return bless [ @_ ], $class;
}

sub write { shift->[0]->write_chunk( $_[0] ) }
sub close { shift->[0]->write_chunk_eof }

=head1 SEE ALSO

=over 4

=item *

L<PSGI> - Perl Web Server Gateway Interface Specification

=item *

L<Plack::Handler::Net::Async::HTTP::Server> - HTTP handler for Plack using
L<Net::Async::HTTP::Server>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
