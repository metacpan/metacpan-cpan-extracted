#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Server::Request;

use strict;
use warnings;

our $VERSION = '0.13';

use Carp;

use URI;
use URI::QueryParam;

my $CRLF = "\x0d\x0a";

=head1 NAME

C<Net::Async::HTTP::Server::Request> - represents a single outstanding request

=head1 DESCRIPTION

Objects in this class represent a single outstanding request received by a
L<Net::Async::HTTP::Server> instance. It allows access to the data received
from the web client and allows responding to it.

=cut

sub new
{
   my $class = shift;
   my ( $conn, $request ) = @_;

   return bless {
      conn => $conn,
      req  => $request,

      pending => [],
      bytes_written => 0,
      is_done => 0,
      is_closed => 0,
   }, $class;
}

=head1 METHODS

=cut

=head2 is_closed

   $is_closed = $request->is_closed

Returns true if the underlying network connection for this request has already
been closed. If this is the case, the application is free to drop the request
object and perform no further processing on it.

=cut

sub _close
{
   my $self = shift;
   $self->{is_closed} = 1;
}

sub is_closed
{
   my $self = shift;
   return $self->{is_closed};
}

=head2 method

   $method = $request->method

Return the method name from the request header.

=cut

sub method
{
   my $self = shift;
   return $self->{req}->method;
}

=head2 path

   $path = $request->path

Return the path name from the request header.

=cut

sub path
{
   my $self = shift;
   return $self->{req}->uri->path;
}

=head2 query_string

   $query_string = $request->query_string

Return the query string from the request header.

=cut

sub query_string
{
   my $self = shift;
   return $self->{req}->uri->query;
}

=head2 query_form

   %params = $request->query_form

I<Since version 0.09.>

Return an even-sized list of name and value pairs that gives the decoded data
in the query string. This is the same format as the same-named method on
L<URI>.

=cut

sub query_form
{
   my $self = shift;
   return $self->{req}->uri->query_form;
}

=head2 query_param_names

   @names = $request->query_param_names

I<Since version 0.09.>

Return a list of the names of all the query parameters.

=cut

sub query_param_names
{
   my $self = shift;
   return $self->{req}->uri->query_param;
}

=head2 query_param

   $value = $request->query_param( $name )

   @values = $request->query_param( $name )

I<Since version 0.09.>

Return the value or values of a single decoded query parameter.

=cut

sub query_param
{
   my $self = shift;
   return $self->{req}->uri->query_param( @_ );
}

=head2 protocol

   $protocol = $request->protocol

Return the protocol version from the request header. This will be the full
string, such as C<HTTP/1.1>.

=cut

sub protocol
{
   my $self = shift;
   return $self->{req}->protocol;
}

=head2 header

   $value = $request->header( $key )

Return the value of a request header.

=cut

sub header
{
   my $self = shift;
   my ( $key ) = @_;
   return $self->{req}->header( $key );
}

=head2 headers

   @headers = $request->headers

Returns a list of 2-element C<ARRAY> refs containing all the request headers.
Each referenced array contains, in order, the name and the value.

=cut

sub headers
{
   my $self = shift;
   my @headers;

   $self->{req}->scan( sub {
      my ( $name, $value ) = @_;
      push @headers, [ $name, $value ];
   } );

   return @headers;
}

=head2 body

   $body = $request->body

Return the body content from the request as a string of bytes.

=cut

sub body
{
   my $self = shift;
   return $self->{req}->content;
}

# Called by NaHTTP::Server::Protocol
sub _write_to_stream
{
   my $self = shift;
   my ( $stream ) = @_;

   while( defined( my $next = shift @{ $self->{pending} } ) ) {
      $stream->write( $next,
         on_write => sub {
            $self->{bytes_written} += $_[1];
         },
         $self->protocol eq "HTTP/1.0" ?
            ( on_flush => sub { $stream->close } ) :
            (),
      );
   }

   # An empty ->write to ensure we capture the written byte count correctly
   $stream->write( "",
      on_write => sub {
         $self->{conn}->parent->_done_request( $self );
      }
   ) if $self->{is_done};

   return $self->{is_done};
}

=head2 write

   $request->write( $data )

Append more data to the response to be written to the client. C<$data> can
either be a plain string, or a C<CODE> reference to be used in the underlying
L<IO::Async::Stream>'s C<write> method.

=cut

sub write
{
   my $self = shift;
   my ( $data ) = @_;

   unless( defined $self->{response_status_line} ) {
      ( $self->{response_status_line} ) = split m/$CRLF/, $data;
   }

   return if $self->{is_closed};

   $self->{is_done} and croak "This request has already been completed";

   push @{ $self->{pending} }, $data;
   $self->{conn}->_flush_requests;
}

=head2 write_chunk

   $request->write_chunk( $data )

Append more data to the response in the form of an HTTP chunked-transfer
chunk. This convenience is a shortcut wrapper for prepending the chunk header.

=cut

sub write_chunk
{
   my $self = shift;
   my ( $data ) = @_;

   return if $self->{is_closed};
   return unless my $len = length $data; # Must not write zero-byte chunks

   $self->write( sprintf "%X$CRLF%s$CRLF", $len, $data );
}

=head2 done

   $request->done

Marks this response as completed.

=cut

sub done
{
   my $self = shift;

   return if $self->{is_closed};

   $self->{is_done} and croak "This request has already been completed";

   $self->{is_done} = 1;
   $self->{conn}->_flush_requests;
}

=head2 write_chunk_eof

   $request->write_chunk_eof

Sends the final EOF chunk and marks this response as completed.

=cut

sub write_chunk_eof
{
   my $self = shift;

   return if $self->{is_closed};

   $self->write( "0$CRLF$CRLF" );
   $self->done;
}

=head2 as_http_request

   $req = $request->as_http_request

Returns the data of the request as an L<HTTP::Request> object.

=cut

sub as_http_request
{
   my $self = shift;
   return $self->{req};
}

=head2 respond

   $request->respond( $response )

Respond to the request using the given L<HTTP::Response> object.

=cut

sub respond
{
   my $self = shift;
   my ( $response ) = @_;

   defined $response->protocol or
      $response->protocol( $self->protocol );

   $self->write( $response->as_string( $CRLF ) );
   $self->done;
}

=head2 respond_chunk_header

   $request->respond_chunk_header( $response )

Respond to the request using the given L<HTTP::Response> object to send in
HTTP/1.1 chunked encoding mode.

The headers in the C<$response> will be sent (which will be modified to set
the C<Transfer-Encoding> header). Each call to C<write_chunk> will send
another chunk of data. C<write_chunk_eof> will send the final EOF chunk and
mark the request as complete.

If the C<$response> already contained content, that will be sent as one chunk
immediately after the header is sent.

=cut

sub respond_chunk_header
{
   my $self = shift;
   my ( $response ) = @_;

   defined $response->protocol or
      $response->protocol( $self->protocol );
   defined $response->header( "Transfer-Encoding" ) or
      $response->header( "Transfer-Encoding" => "chunked" );

   my $content = $response->content;

   my $header = $response->as_string( $CRLF );
   # Trim any content from the header as it would need to be chunked
   $header =~ s/$CRLF$CRLF.*$/$CRLF$CRLF/s;

   $self->write( $header );

   $self->write_chunk( $response->content ) if length $response->content;
}

=head2 stream

   $stream = $request->stream

Returns the L<IO::Async::Stream> object representing this connection. Usually
this would be used for such things as inspecting the client's connection
address on the C<read_handle> of the stream. It should not be necessary to
directly perform IO operations on this stream itself.

=cut

sub stream
{
   my $self = shift;
   return $self->{conn};
}

=head2 response_status_line

   $status = $request->response_status_line

If a response header has been written by calling the C<write> method, returns
the first line of it.

=cut

sub response_status_line
{
   my $self = shift;
   return $self->{response_status_line};
}

=head2 response_status_code

   $code = $request->response_status_code

If a response header has been written by calling the C<write> method, returns
the status code from it.

=cut

sub response_status_code
{
   my $self = shift;
   my $line = $self->{response_status_line} or return undef;
   return +( split m/ /, $line )[1];
}

# For metrics
sub bytes_written
{
   my $self = shift;
   return $self->{bytes_written};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
