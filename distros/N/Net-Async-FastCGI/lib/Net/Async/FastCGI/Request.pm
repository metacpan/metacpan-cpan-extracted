#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2005-2013 -- leonerd@leonerd.org.uk

package Net::Async::FastCGI::Request;

use strict;
use warnings;

use Carp;

use Net::FastCGI::Constant qw( :type :flag :protocol_status );
use Net::FastCGI::Protocol qw( 
   parse_params
   build_end_request_body
);

# The largest amount of data we can fit in a FastCGI record - MUST NOT
# be greater than 2^16-1
use constant MAXRECORDDATA => 65535;

use Encode qw( find_encoding );
use POSIX qw( EAGAIN );

our $VERSION = '0.25';

my $CRLF = "\x0d\x0a";

=head1 NAME

C<Net::Async::FastCGI::Request> - a single active FastCGI request

=head1 SYNOPSIS

 use Net::Async::FastCGI;
 use IO::Async::Loop;

 my $fcgi = Net::Async::FastCGI->new(
    on_request => sub {
       my ( $fcgi, $req ) = @_;

       my $path = $req->param( "PATH_INFO" );
       $req->print_stdout( "Status: 200 OK\r\n" .
                           "Content-type: text/plain\r\n" .
                           "\r\n" .
                           "You requested $path" );
       $req->finish();
    }
 );

 my $loop = IO::Async::Loop->new();

 $loop->add( $fcgi );

 $loop->run;

=head1 DESCRIPTION

Instances of this object class represent individual requests received from the
webserver that are currently in-progress, and have not yet been completed.
When given to the controlling program, each request will already have its
parameters and STDIN data. The program can then write response data to the
STDOUT stream, messages to the STDERR stream, and eventually finish it.

This module would not be used directly by a program using
C<Net::Async::FastCGI>, but rather, objects in this class are passed into the
C<on_request> event of the containing C<Net::Async::FastCGI> object.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $rec = $args{rec};

   my $self = bless {
      conn       => $args{conn},
      fcgi       => $args{fcgi},

      reqid      => $rec->{reqid},
      keepconn   => $rec->{flags} & FCGI_KEEP_CONN,

      stdin      => "",
      stdindone  => 0,
      params     => {},
      paramsdone => 0,

      stdout     => "",
      stderr     => "",

      used_stderr => 0,
   }, $class;

   $self->set_encoding( $args{fcgi}->_default_encoding );

   return $self;
}

sub write_record
{
   my $self = shift;
   my ( $rec ) = @_;

   return if $self->is_aborted;

   my $content = $rec->{content};
   my $contentlen = length( $content );
   if( $contentlen > MAXRECORDDATA ) {
      warn __PACKAGE__."->write_record() called with content longer than ".MAXRECORDDATA." bytes - truncating";
      $content = substr( $content, 0, MAXRECORDDATA );
   }

   $rec->{reqid} = $self->{reqid} unless defined $rec->{reqid};

   my $conn = $self->{conn};

   $conn->write_record( $rec, $content );

}

sub incomingrecord
{
   my $self = shift;
   my ( $rec ) = @_;

   my $type    = $rec->{type};

   if( $type == FCGI_PARAMS ) {
      $self->incomingrecord_params( $rec );
   }
   elsif( $type == FCGI_STDIN ) {
      $self->incomingrecord_stdin( $rec );
   }
   else {
      warn "$self just received unknown record type";
   }
}

sub _ready_check
{
   my $self = shift;

   if( $self->{stdindone} and $self->{paramsdone} ) {
      $self->{fcgi}->_request_ready( $self );
   }
}

sub incomingrecord_params
{
   my $self = shift;
   my ( $rec ) = @_;

   my $content = $rec->{content};
   my $len     = $rec->{len};

   if( $len ) {
      no warnings 'uninitialized';
      $self->{paramscontent} .= $content;
      return;
   }
   else {
      $self->{params} = parse_params( delete $self->{paramscontent} );
      $self->{paramsdone} = 1;
   }

   $self->_ready_check;
}

sub incomingrecord_stdin
{
   my $self = shift;
   my ( $rec ) = @_;

   my $content = $rec->{content};
   my $len     = $rec->{len};

   if( $len ) {
      $self->{stdin} .= $content;
   }
   else {
      $self->{stdindone} = 1;
   }

   $self->_ready_check;
}

=head1 METHODS

=cut

=head2 $hashref = $req->params

This method returns a reference to a hash containing a copy of the request
parameters that had been sent by the webserver as part of the request.

=cut

sub params
{
   my $self = shift;

   my %p = %{$self->{params}};

   return \%p;
}

=head2 $p = $req->param( $key )

This method returns the value of a single request parameter, or C<undef> if no
such key exists.

=cut

sub param
{
   my $self = shift;
   my ( $key ) = @_;

   return $self->{params}{$key};
}

=head2 $method = $req->method

Returns the value of the C<REQUEST_METHOD> parameter, or C<GET> if there is no
value set for it.

=cut

sub method
{
   my $self = shift;
   return $self->param( "REQUEST_METHOD" ) || "GET";
}

=head2 $script_name = $req->script_name

Returns the value of the C<SCRIPT_NAME> parameter.

=cut

sub script_name
{
   my $self = shift;
   return $self->param( "SCRIPT_NAME" );
}

=head2 $path_info = $req->path_info

Returns the value of the C<PATH_INFO> parameter.

=cut

sub path_info
{
   my $self = shift;
   return $self->param( "PATH_INFO" );
}

=head2 $path = $req->path

Returns the full request path by reconstructing it from C<script_name> and
C<path_info>.

=cut

sub path
{
   my $self = shift;

   my $path = join "", grep defined && length,
      $self->script_name,
      $self->path_info;
   $path = "/" if !length $path;

   return $path;
}

=head2 $query_string = $req->query_string

Returns the value of the C<QUERY_STRING> parameter.

=cut

sub query_string
{
   my $self = shift;
   return $self->param( "QUERY_STRING" ) || "";
}

=head2 $protocol = $req->protocol

Returns the value of the C<SERVER_PROTOCOL> parameter.

=cut

sub protocol
{
   my $self = shift;
   return $self->param( "SERVER_PROTOCOL" );
}

=head2 $req->set_encoding( $encoding )

Sets the character encoding used by the request's STDIN, STDOUT and STDERR
streams. This method may be called at any time to change the encoding in
effect, which will be used the next time C<read_stdin_line>, C<read_stdin>,
C<print_stdout> or C<print_stderr> are called. This encoding will remain in
effect until changed again. The encoding of a new request is determined by the
C<default_encoding> parameter of the containing C<Net::Async::FastCGI> object.
If the value C<undef> is passed, the encoding will be removed, and the above
methods will work directly on bytes instead of encoded strings.

=cut

sub set_encoding
{
   my $self = shift;
   my ( $encoding ) = @_;

   if( defined $encoding ) {
      my $codec = find_encoding( $encoding );
      defined $codec or croak "Unrecognised encoding '$encoding'";
      $self->{codec} = $codec;
   }
   else {
      undef $self->{codec};
   }
}

=head2 $line = $req->read_stdin_line

This method works similarly to the C<< <HANDLE> >> operator. If at least one
line of data is available then it is returned, including the linefeed, and
removed from the buffer. If not, then any remaining partial line is returned
and removed from the buffer. If no data is available any more, then C<undef>
is returned instead.

=cut

sub read_stdin_line
{
   my $self = shift;

   my $codec = $self->{codec};

   if( $self->{stdin} =~ s/^(.*[\r\n])// ) {
      return $codec ? $codec->decode( $1 ) : $1;
   }
   elsif( $self->{stdin} =~ s/^(.+)// ) {
      return $codec ? $codec->decode( $1 ) : $1;
   }
   else {
      return undef;
   }
}

=head2 $data = $req->read_stdin( $size )

This method works similarly to the C<read(HANDLE)> function. It returns the
next block of up to $size bytes from the STDIN buffer. If no data is available
any more, then C<undef> is returned instead. If $size is not defined, then it
will return all the available data.

=cut

sub read_stdin
{
   my $self = shift;
   my ( $size ) = @_;

   return undef unless length $self->{stdin};

   $size = length $self->{stdin} unless defined $size;

   my $codec = $self->{codec};

   # If $size is too big, substr() will cope
   my $bytes = substr( $self->{stdin}, 0, $size, "" );
   return $codec ? $codec->decode( $bytes ) : $bytes;
}

sub _print_stream
{
   my $self = shift;
   my ( $data, $stream ) = @_;

   while( length $data ) {
      # Send chunks of up to MAXRECORDDATA bytes at once
      my $chunk = substr( $data, 0, MAXRECORDDATA, "" );
      $self->write_record( { type => $stream, content => $chunk } );
   }
}

sub _flush_streams
{
   my $self = shift;

   if( length $self->{stdout} ) {
      $self->_print_stream( $self->{stdout}, FCGI_STDOUT );
      $self->{stdout} = "";
   }
   elsif( my $cb = $self->{stdout_cb} ) {
      $cb->();
   }

   if( length $self->{stderr} ) {
      $self->_print_stream( $self->{stderr}, FCGI_STDERR );
      $self->{stderr} = "";
   }
}

sub _needs_flush
{
   my $self = shift;
   return defined $self->{stdout_cb};
}

=head2 $req->print_stdout( $data )

This method appends the given data to the STDOUT stream of the FastCGI
request, sending it to the webserver to be sent to the client.

=cut

sub print_stdout
{
   my $self = shift;
   my ( $data ) = @_;

   my $codec = $self->{codec};

   $self->{stdout} .= $codec ? $codec->encode( $data ) : $data;

   $self->{conn}->_req_needs_flush( $self );
}

=head2 $req->print_stderr( $data )

This method appends the given data to the STDERR stream of the FastCGI
request, sending it to the webserver.

=cut

sub print_stderr
{
   my $self = shift;
   my ( $data ) = @_;

   my $codec = $self->{codec};

   $self->{used_stderr} = 1;
   $self->{stderr} .= $codec ? $codec->encode( $data ) : $data;

   $self->{conn}->_req_needs_flush( $self );
}

=head2 $req->stream_stdout_then_finish( $readfn, $exitcode )

This method installs a callback for streaming data to the STDOUT stream.
Whenever the output stream is otherwise-idle, the function will be called to
generate some more data to output. When this function returns C<undef> it
indicates the end of the stream, and the request will be finished with the
given exit code.

If this method is used, then care should be taken to ensure that the number of
bytes written to the server matches the number that was claimed in the
C<Content-Length>, if such was provided. This logic should be performed by the
containing application; C<Net::Async::FastCGI> will not track it.

=cut

sub stream_stdout_then_finish
{
   my $self = shift;
   my ( $readfn, $exitcode ) = @_;

   $self->{stdout_cb} = sub {
      my $data = $readfn->();

      if( defined $data ) {
         $self->print_stdout( $data );
      }
      else {
         delete $self->{stdout_cb};
         $self->finish( $exitcode );
      }
   };

   $self->{conn}->_req_needs_flush( $self );
}

=head2 $stdin = $req->stdin

Returns an IO handle representing the request's STDIN buffer. This may be read
from using the C<read> or C<readline> functions or the C<< <$stdin> >>
operator.

Note that this will be a tied IO handle, it will not be useable directly as an
OS-level filehandle.

=cut

sub stdin
{
   my $self = shift;

   return Net::Async::FastCGI::Request::TiedHandle->new(
      READ => sub { 
         $_[1] = $self->read_stdin( $_[2] );
         return defined $_[1] ? length $_[1] : 0;
      },
      READLINE => sub {
         return $self->read_stdin_line;
      },
   );
}

=head2 $stdout = $req->stdout

=head2 $stderr = $req->stderr

Returns an IO handle representing the request's STDOUT or STDERR streams
respectively. These may written to using C<print>, C<printf>, C<say>, etc..

Note that these will be tied IO handles, they will not be useable directly as
an OS-level filehandle.

=cut

sub _stdouterr
{
   my $self = shift;
   my ( $method ) = @_;

   return Net::Async::FastCGI::Request::TiedHandle->new(
      WRITE => sub { $self->$method( $_[1] ) },
   );
}

sub stdout
{
   return shift->_stdouterr( "print_stdout" );
}

sub stderr
{
   return shift->_stdouterr( "print_stderr" );
}

=head2 $req->finish( $exitcode )

When the request has been dealt with, this method should be called to indicate
to the webserver that it is finished. After calling this method, no more data
may be appended to the STDOUT stream. At some point after calling this method,
the request object will be removed from the containing C<Net::Async::FastCGI>
object, once all the buffered outbound data has been sent.

If present, C<$exitcode> should indicate the numeric status code to send to
the webserver. If absent, a value of C<0> is presumed.

=cut

sub finish
{
   my $self = shift;
   my ( $exitcode ) = @_;

   return if $self->is_aborted;

   $self->_flush_streams;

   # Signal the end of STDOUT
   $self->write_record( { type => FCGI_STDOUT, content => "" } );

   # Signal the end of STDERR if we used it
   $self->write_record( { type => FCGI_STDERR, content => "" } ) if $self->{used_stderr};

   $self->write_record( { type => FCGI_END_REQUEST, 
         content => build_end_request_body( $exitcode || 0, FCGI_REQUEST_COMPLETE )
   } );

   my $conn = $self->{conn};

   if( $self->{keepconn} ) {
      $conn->_removereq( $self->{reqid} );
   }
   else {
      $conn->close;
   }
}

=head2 $stdout = $req->stdout_with_close

Similar to the C<stdout> method, except that when the C<close> method is
called on the returned filehandle, the request will be finished by calling
C<finish>.

=cut

sub stdout_with_close
{
   my $self = shift;

   return Net::Async::FastCGI::Request::TiedHandle->new(
      WRITE => sub { $self->print_stdout( $_[1] ) },
      CLOSE => sub { $self->finish( 0 ) },
   );
}

sub _abort
{
   my $self = shift;
   $self->{aborted} = 1;

   my $conn = $self->{conn};
   $conn->_removereq( $self->{reqid} );

   delete $self->{stdout_cb};
}

=head2 $req->is_aborted

Returns true if the webserver has already closed the control connection. No
further work on this request is necessary, as it will be discarded.

It is not required to call this method; if the request is aborted then any
output will be discarded. It may however be useful to call just before
expensive operations, in case effort can be avoided if it would otherwise be
wasted.

=cut

sub is_aborted
{
   my $self = shift;
   return $self->{aborted};
}

=head1 HTTP::Request/Response Interface

The following pair of methods form an interface that allows the request to be
used as a source of L<HTTP::Request> objects, responding to them by sending
L<HTTP::Response> objects. This may be useful to fit it in to existing code
that already uses these.

=cut

=head2 $http_req = $req->as_http_request

Returns a new C<HTTP::Request> object that gives a reasonable approximation to
the request. Because the webserver has translated the original HTTP request
into FastCGI parameters, this may not be a perfect recreation of the request
as received by the webserver.

=cut

sub as_http_request
{
   my $self = shift;

   require HTTP::Request;

   my $params = $self->params;

   my $authority =
      ( $params->{HTTP_HOST} || $params->{SERVER_NAME} || "" ) . ":" .
      ( $params->{SERVER_PORT} || "80" );

   my $path = $self->path;
   my $query_string = $self->query_string;

   $path .= "?$query_string" if length $query_string;

   my $uri = URI->new( "http://$authority$path" )->canonical;

   my @headers;

   # Content-Type and Content-Length come specially
   push @headers, "Content-Type"   => $params->{CONTENT_TYPE}
      if exists $params->{CONTENT_TYPE};

   push @headers, "Content-Length" => $params->{CONTENT_LENGTH}
      if exists $params->{CONTENT_LENGTH};

   # Pull all the HTTP_FOO parameters as headers. These will be in all-caps
   # and use _ for word separators, but HTTP::Headers can cope
   foreach ( keys %$params ) {
      m/^HTTP_(.*)$/ and push @headers, $1 => $params->{$_};
   }

   my $content = $self->{stdin};

   my $req = HTTP::Request->new( $self->method, $uri, \@headers, $content );

   $req->protocol( $self->protocol );

   return $req;
}

=head2 $req->send_http_response( $resp )

Sends the given C<HTTP::Response> object as the response to this request. The
status, headers and content are all written out to the request's STDOUT stream
and then the request is finished with 0 as the exit code.

=cut

sub send_http_response
{
   my $self = shift;
   my ( $resp ) = @_;

   # (Fast)CGI suggests this is the way to report the status
   $resp->header( Status => $resp->code );

   my $topline = $resp->protocol . " " . $resp->status_line;

   $self->print_stdout( $topline . $CRLF );
   $self->print_stdout( $resp->headers_as_string( $CRLF ) );

   $self->print_stdout( $CRLF );

   $self->print_stdout( $resp->content );
   $self->finish( 0 );
}

package # hide from CPAN
   Net::Async::FastCGI::Request::TiedHandle;
use base qw( Tie::Handle );

use Symbol qw( gensym );

sub new
{
   my $class = shift;

   my $handle = gensym;
   tie *$handle, $class, @_;

   return $handle;
}

sub TIEHANDLE
{
   my $class = shift;
   return bless { @_ }, $class;
}

sub CLOSE    { shift->{CLOSE}->( @_ ) }
sub READ     { shift->{READ}->( @_ ) }
sub READLINE { shift->{READLINE}->( @_ ) }
sub WRITE    { shift->{WRITE}->( @_ ) }

=head1 EXAMPLES

=head2 Streaming A File

To serve contents of files on disk, it may be more efficient to use
C<stream_stdout_then_finish>:

 use Net::Async::FastCGI;
 use IO::Async::Loop;

 my $fcgi = Net::Async::FastCGI->new(
    on_request => sub {
       my ( $fcgi, $req ) = @_;

       open( my $file, "<", "/path/to/file" );
       $req->print_stdout( "Status: 200 OK\r\n" .
                           "Content-type: application/octet-stream\r\n" .
                           "\r\n" );

       $req->stream_stdout_then_finish(
          sub { read( $file, my $buffer, 8192 ) or return undef; return $buffer },
          0
       );
    }

 my $loop = IO::Async::Loop->new();

 $loop->add( $fcgi );

 $loop->run;

It may be more efficient again to instead use the C<X-Sendfile> feature of
certain webservers, which allows the webserver itself to serve the file
efficiently. See your webserver's documentation for more detail.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
