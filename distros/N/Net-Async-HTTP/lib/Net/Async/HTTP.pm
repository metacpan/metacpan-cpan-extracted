#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2015 -- leonerd@leonerd.org.uk

package Net::Async::HTTP;

use strict;
use warnings;
use base qw( IO::Async::Notifier );

our $VERSION = '0.41';

our $DEFAULT_UA = "Perl + " . __PACKAGE__ . "/$VERSION";
our $DEFAULT_MAXREDIR = 3;
our $DEFAULT_MAX_IN_FLIGHT = 4;
our $DEFAULT_MAX_CONNS_PER_HOST = $ENV{NET_ASYNC_HTTP_MAXCONNS} // 1;

use Carp;

use Net::Async::HTTP::Connection;

use HTTP::Request;
use HTTP::Request::Common qw();
use URI;

use IO::Async::Stream 0.59;
use IO::Async::Loop 0.59; # ->connect( handle ) ==> $stream

use Future 0.28; # ->set_label
use Future::Utils 0.16 qw( repeat );

use Scalar::Util qw( blessed reftype );
use List::Util 1.29 qw( first pairs );
use Socket qw( SOCK_STREAM IPPROTO_IP IP_TOS );
BEGIN {
   if( $Socket::VERSION >= '2.010' ) {
      Socket->import(qw( IPTOS_LOWDELAY IPTOS_THROUGHPUT IPTOS_RELIABILITY IPTOS_MINCOST ));
   }
   else {
      # These are portable constants, set in RFC 1349
      require constant;
      constant->import({
         IPTOS_LOWDELAY    => 0x10,
         IPTOS_THROUGHPUT  => 0x08,
         IPTOS_RELIABILITY => 0x04,
         IPTOS_MINCOST     => 0x02,
      });
   }
}

use constant HTTP_PORT  => 80;
use constant HTTPS_PORT => 443;

use constant READ_LEN  => 64*1024; # 64 KiB
use constant WRITE_LEN => 64*1024; # 64 KiB

use Struct::Dumb 0.07;  # equallity operator overloading
struct Ready => [qw( future connecting )];

=head1 NAME

C<Net::Async::HTTP> - use HTTP with C<IO::Async>

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::HTTP;
 use URI;

 my $loop = IO::Async::Loop->new();

 my $http = Net::Async::HTTP->new();

 $loop->add( $http );

 my ( $response ) = $http->do_request(
    uri => URI->new( "http://www.cpan.org/" ),
 )->get;

 print "Front page of http://www.cpan.org/ is:\n";
 print $response->as_string;

=head1 DESCRIPTION

This object class implements an asynchronous HTTP user agent. It sends
requests to servers, returning L<Future> instances to yield responses when
they are received. The object supports multiple concurrent connections to
servers, and allows multiple requests in the pipeline to any one connection.
Normally, only one such object will be needed per program to support any
number of requests.

As well as using futures the module also supports a callback-based interface.

This module optionally supports SSL connections, if L<IO::Async::SSL> is
installed. If so, SSL can be requested either by passing a URI with the
C<https> scheme, or by passing a true value as the C<SSL> parameter.

=head2 Connection Pooling

There are three ways in which connections to HTTP server hosts are managed by
this object, controlled by the value of C<max_connections_per_host>. This
controls when new connections are established to servers, as compared to
waiting for existing connections to be free, as new requests are made to them.

They are:

=over 2

=item max_connections_per_host = 1

This is the default setting. In this mode, there will be one connection per
host on which there are active or pending requests. If new requests are made
while an existing one is outstanding, they will be queued to wait for it.

If pipelining is active on the connection (because both the C<pipeline> option
is true and the connection is known to be an HTTP/1.1 server), then requests
will be pipelined into the connection awaiting their response. If not, they
will be queued awaiting a response to the previous before sending the next.

=item max_connections_per_host > 1

In this mode, there can be more than one connection per host. If a new request
is made, it will try to re-use idle connections if there are any, or if they
are all busy it will create a new connection to the host, up to the configured
limit.

=item max_connections_per_host = 0

In this mode, there is no upper limit to the number of connections per host.
Every new request will try to reuse an idle connection, or else create a new
one if all the existing ones are busy.

=back

These modes all apply per hostname / server port pair; they do not affect the
behaviour of connections made to differing hostnames, or differing ports on
the same hostname.

=cut

sub _init
{
   my $self = shift;

   $self->{connections} = {}; # { "$host:$port" } -> [ @connections ]

   $self->{read_len}  = READ_LEN;
   $self->{write_len} = WRITE_LEN;

   $self->{max_connections_per_host} = $DEFAULT_MAX_CONNS_PER_HOST;

   $self->{ssl_params} = {};
}

sub _remove_from_loop
{
   my $self = shift;

   foreach my $conn ( map { @$_ } values %{ $self->{connections} } ) {
      $conn->close;
   }

   $self->SUPER::_remove_from_loop( @_ );
}

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 user_agent => STRING

A string to set in the C<User-Agent> HTTP header. If not supplied, one will
be constructed that declares C<Net::Async::HTTP> and the version number.

=head2 max_redirects => INT

Optional. How many levels of redirection to follow. If not supplied, will
default to 3. Give 0 to disable redirection entirely.

=head2 max_in_flight => INT

Optional. The maximum number of in-flight requests to allow per host when
pipelining is enabled and supported on that host. If more requests are made
over this limit they will be queued internally by the object and not sent to
the server until responses are received. If not supplied, will default to 4.
Give 0 to disable the limit entirely.

=head2 max_connections_per_host => INT

Optional. Controls the maximum number of connections per hostname/server port
pair, before requests will be queued awaiting one to be free. Give 0 to
disable the limit entirely. See also the L</Connection Pooling> section
documented above.

Currently, if not supplied it will default to 1. However, it has been found in
practice that most programs will raise this limit to something higher, perhaps
3 or 4. Therefore, a future version of this module may set a higher value.

To test if your application will handle this correctly, you can set a
different default by setting an environment variable:

 $ NET_ASYNC_HTTP_MAXCONNS=3 perl ...

=head2 timeout => NUM

Optional. How long in seconds to wait before giving up on a request. If not
supplied then no default will be applied, and no timeout will take place.

=head2 stall_timeout => NUM

Optional. How long in seconds to wait after each write or read of data on a
socket, before giving up on a request. This may be more useful than
C<timeout> on large-file operations, as it will not time out provided that
regular progress is still being made.

=head2 proxy_host => STRING

=head2 proxy_port => INT

Optional. Default values to apply to each C<request> method.

=head2 cookie_jar => HTTP::Cookies

Optional. A reference to a L<HTTP::Cookies> object. Will be used to set
cookies in requests and store them from responses.

=head2 pipeline => BOOL

Optional. If false, disables HTTP/1.1-style request pipelining.

=head2 family => INT

=head2 local_host => STRING

=head2 local_port => INT

=head2 local_addrs => ARRAY

=head2 local_addr => HASH or ARRAY

Optional. Parameters to pass on to the C<connect> method used to connect
sockets to HTTP servers. Sets the socket family and local socket address to
C<bind()> to. For more detail, see the documentation in
L<IO::Async::Connector>.

=head2 fail_on_error => BOOL

Optional. Affects the behaviour of response handling when a C<4xx> or C<5xx>
response code is received. When false, these responses will be processed as
other responses and yielded as the result of the future, or passed to the
C<on_response> callback. When true, such an error response causes the future
to fail, or the C<on_error> callback to be invoked.

The HTTP response and request objects will be passed as well as the code and
message, and the failure name will be C<http>.

 ( $code_message, "http", $response, $request ) = $f->failure

 $on_error->( "$code $message", $response, $request )

=head2 read_len => INT

=head2 write_len => INT

Optional. Used to set the reading and writing buffer lengths on the underlying
C<IO::Async::Stream> objects that represent connections to the server. If not
define, a default of 64 KiB will be used.

=head2 ip_tos => INT or STRING

Optional. Used to set the C<IP_TOS> socket option on client sockets. If given,
should either be a C<IPTOS_*> constant, or one of the string names
C<lowdelay>, C<throughput>, C<reliability> or C<mincost>. If undefined or left
absent, no option will be set.

=head2 decode_content => BOOL

Optional. If true, incoming responses that have a recognised
C<Content-Encoding> are handled by the module, and decompressed content is
passed to the body handling callback or returned in the C<HTTP::Response>. See
L</CONTENT DECODING> below for details of which encoding methods are
recognised. When this option is enabled, outgoing requests also have the
C<Accept-Encoding> header added to them if it does not already exist.

Currently the default is false, because this behaviour is new, but it may
default to true in a later version. Applications which care which behaviour
applies should set this to a defined value to ensure it doesn't change.

=head2 SSL_*

Additionally, any parameters whose names start with C<SSL_> will be stored and
passed on requests to perform SSL requests. This simplifies configuration of
common SSL parameters.

=head2 require_SSL => BOOL

Optional. If true, then any attempt to make a request that does not use SSL
(either by calling C<request>, or as a result of a redirection) will
immediately fail.

=cut

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( user_agent max_redirects max_in_flight max_connections_per_host
      timeout stall_timeout proxy_host proxy_port cookie_jar pipeline
      family local_host local_port local_addrs local_addr fail_on_error
      read_len write_len decode_content require_SSL ))
   {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   foreach ( grep { m/^SSL_/ } keys %params ) {
      $self->{ssl_params}{$_} = delete $params{$_};
   }

   if( exists $params{ip_tos} ) {
      # TODO: This conversion should live in IO::Async somewhere
      my $ip_tos = delete $params{ip_tos};
      $ip_tos = IPTOS_LOWDELAY    if defined $ip_tos and $ip_tos eq "lowdelay";
      $ip_tos = IPTOS_THROUGHPUT  if defined $ip_tos and $ip_tos eq "throughput";
      $ip_tos = IPTOS_RELIABILITY if defined $ip_tos and $ip_tos eq "reliability";
      $ip_tos = IPTOS_MINCOST     if defined $ip_tos and $ip_tos eq "mincost";
      $self->{ip_tos} = $ip_tos;
   }

   $self->SUPER::configure( %params );

   defined $self->{user_agent}    or $self->{user_agent}    = $DEFAULT_UA;
   defined $self->{max_redirects} or $self->{max_redirects} = $DEFAULT_MAXREDIR;
   defined $self->{max_in_flight} or $self->{max_in_flight} = $DEFAULT_MAX_IN_FLIGHT;
   defined $self->{pipeline}      or $self->{pipeline}      = 1;
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

When returning a Future, the following methods all indicate HTTP-level errors
using the Future failure name of C<http>. If the error relates to a specific
response it will be included. The original request is also included.

 $f->fail( $message, "http", $response, $request )

=cut

sub connect_connection
{
   my $self = shift;
   my %args = @_;

   my $conn = delete $args{conn};

   my $host = delete $args{host};
   my $port = delete $args{port};

   my $on_error  = $args{on_error};

   if( $args{SSL} ) {
      require IO::Async::SSL;
      IO::Async::SSL->VERSION( '0.12' ); # 0.12 has ->connect(handle) bugfix

      push @{ $args{extensions} }, "SSL";
   }

   my $f = $conn->connect(
      host     => $host,
      service  => $port,
      family   => ( $args{family} || $self->{family} || 0 ),
      ( map { defined $self->{$_} ? ( $_ => $self->{$_} ) : () }
         qw( local_host local_port local_addrs local_addr ) ),

      %args,
   )->on_done( sub {
      my ( $stream ) = @_;
      $stream->configure(
         notifier_name => "$host:$port,fd=" . $stream->read_handle->fileno,
      );

      # Defend against ->setsockopt doing silly things like detecting SvPOK()
      $stream->read_handle->setsockopt( IPPROTO_IP, IP_TOS, $self->{ip_tos}+0 ) if defined $self->{ip_tos};

      $stream->ready;
   })->on_fail( sub {
      $on_error->( $conn, "$host:$port - $_[0] failed [$_[-1]]" );
   });

   $f->on_ready( sub { undef $f } ); # intentionally cycle
}

sub get_connection
{
   my $self = shift;
   my %args = @_;

   my $loop = $self->get_loop or croak "Cannot ->get_connection without a Loop";

   my $host = $args{host};
   my $port = $args{port};

   my $key = "$host:$port";
   my $conns = $self->{connections}{$key} ||= [];
   my $ready_queue = $self->{ready_queue}{$key} ||= [];

   # Have a look to see if there are any idle connected ones first
   foreach my $conn ( @$conns ) {
      $conn->is_idle and $conn->read_handle and return Future->done( $conn );
   }

   my $ready = $args{ready};
   $ready or push @$ready_queue, $ready =
      Ready( $self->loop->new_future->set_label( "[ready $host:$port]" ), 0 );

   my $f = $ready->future;

   my $max = $self->{max_connections_per_host};
   if( $max and @$conns >= $max ) {
      return $f;
   }

   my $conn = Net::Async::HTTP::Connection->new(
      notifier_name => "$host:$port,connecting",
      ready_queue   => $ready_queue,
      ( map { $_ => $self->{$_} }
         qw( max_in_flight pipeline read_len write_len decode_content ) ),

      on_closed => sub {
         my $conn = shift;
         my $http = $conn->parent;

         $conn->remove_from_parent;
         @$conns = grep { $_ != $conn } @$conns;

         if( my $next = first { !$_->connecting } @$ready_queue ) {
            # Requeue another connection attempt as there's still more to do
            $http->get_connection( %args, ready => $next );
         }
      },
   );

   $self->add_child( $conn );
   push @$conns, $conn;

   $ready->connecting = $self->connect_connection( %args,
      conn => $conn,
      on_error => sub {
         my $conn = shift;

         $f->fail( @_ ) unless $f->is_cancelled;

         $conn->remove_from_parent;
         @$conns = grep { $_ != $conn } @$conns;
         @$ready_queue = grep { $_ != $ready } @$ready_queue;

         if( my $next = first { !$_->connecting } @$ready_queue ) {
            # Requeue another connection attempt as there's still more to do
            $self->get_connection( %args, ready => $next );
         }
      },
   )->on_cancel( sub {
      $conn->remove_from_parent;
      @$conns = grep { $_ != $conn } @$conns;
   });

   return $f;
}

=head2 $response = $http->do_request( %args )->get

Send an HTTP request to a server, returning a L<Future> that will yield the
response. The request may be represented by an L<HTTP::Request> object, or a
L<URI> object, depending on the arguments passed.

The following named arguments are used for C<HTTP::Request>s:

=over 8

=item request => HTTP::Request

A reference to an C<HTTP::Request> object

=item host => STRING

Hostname of the server to connect to

=item port => INT or STRING

Optional. Port number or service of the server to connect to. If not defined,
will default to C<http> or C<https> depending on whether SSL is being used.

=item family => INT

Optional. Restricts the socket family for connecting. If not defined, will
default to the globally-configured value in the object.

=item SSL => BOOL

Optional. If true, an SSL connection will be used.

=back

The following named arguments are used for C<URI> requests:

=over 8

=item uri => URI or STRING

A reference to a C<URI> object, or a plain string giving the request URI. If
the scheme is C<https> then an SSL connection will be used.

=item method => STRING

Optional. The HTTP method. If missing, C<GET> is used.

=item content => STRING or ARRAY ref

Optional. The body content to use for C<PUT> or C<POST> requests. If this is a
plain scalar instead of an ARRAY ref, it will not be form encoded. In this
case, a C<content_type> field must also be supplied to describe it.

=item content_type => STRING

The type of non-form data C<content>.

=item user => STRING

=item pass => STRING

Optional. If both are given, the HTTP Basic Authorization header will be sent
with these details.

=item headers => ARRAY|HASH

Optional. If provided, contains additional HTTP headers to set on the
constructed request object. If provided as an ARRAY reference, it should
contain an even-sized list of name/value pairs.

=item proxy_host => STRING

=item proxy_port => INT

Optional. Override the hostname or port number implied by the URI.

=back

For either request type, it takes the following arguments:

=over 8

=item request_body => STRING | CODE | Future

Optional. Allows request body content to be generated by a future or
callback, rather than being provided as part of the C<request> object. This
can either be a plain string, a C<CODE> reference to a generator function, or
a future.

As this is passed to the underlying L<IO::Async::Stream> C<write> method, the
usual semantics apply here. If passed a C<CODE> reference, it will be called
repeatedly whenever it's safe to write. The code should should return C<undef>
to indicate completion. If passed a C<Future> it is expected to eventually
yield the body value.

As with the C<content> parameter, the C<content_type> field should be
specified explicitly in the request header, as should the content length
(typically via the L<HTTP::Request> C<content_length> method). See also
F<examples/PUT.pl>.

=item expect_continue => BOOL

Optional. If true, sets the C<Expect> request header to the value
C<100-continue> and does not send the C<request_body> parameter until a
C<100 Continue> response is received from the server. If an error response is
received then the C<request_body> code, if present, will not be invoked.

=item on_ready => CODE

Optional. A callback that is invoked once a socket connection is established
with the HTTP server, but before the request is actually sent over it. This
may be used by the client code to inspect the socket, or perform any other
operations on it. This code is expected to return a C<Future>; only once that
has completed will the request cycle continue. If it fails, that failure is
propagated to the caller.

 $f = $on_ready->( $connection )

=item on_redirect => CODE

Optional. A callback that is invoked if a redirect response is received,
before the new location is fetched. It will be passed the response and the new
URL.

 $on_redirect->( $response, $location )

=item on_body_write => CODE

Optional. A callback that is invoked after each successful C<syswrite> of the
body content. This may be used to implement an upload progress indicator or
similar. It will be passed the total number of bytes of body content written
so far (i.e. excluding bytes consumed in the header).

 $on_body_write->( $written )

=item max_redirects => INT

Optional. How many levels of redirection to follow. If not supplied, will
default to the value given in the constructor.

=item timeout => NUM

=item stall_timeout => NUM

Optional. Overrides the object's configured timeout values for this one
request. If not specified, will use the configured defaults.

On a timeout, the returned future will fail with either C<timeout> or
C<stall_timeout> as the operation name.

 ( $message, "timeout" ) = $f->failure

=back

=head2 $http->do_request( %args )

When not returning a future, the following extra arguments are used as
callbacks instead:

=over 8

=item on_response => CODE

A callback that is invoked when a response to this request has been received.
It will be passed an L<HTTP::Response> object containing the response the
server sent.

 $on_response->( $response )

=item on_header => CODE

Alternative to C<on_response>. A callback that is invoked when the header of a
response has been received. It is expected to return a C<CODE> reference for
handling chunks of body content. This C<CODE> reference will be invoked with
no arguments once the end of the request has been reached, and whatever it
returns will be used as the result of the returned C<Future>, if there is one.

 $on_body_chunk = $on_header->( $header )

    $on_body_chunk->( $data )
    $response = $on_body_chunk->()

=item on_error => CODE

A callback that is invoked if an error occurs while trying to send the request
or obtain the response. It will be passed an error message.

 $on_error->( $message )

If this is invoked because of a received C<4xx> or C<5xx> error code in an
HTTP response, it will be invoked with the response and request objects as
well.

 $on_error->( $message, $response, $request )

=back

=cut

sub _do_one_request
{
   my $self = shift;
   my %args = @_;

   my $host    = delete $args{host};
   my $port    = delete $args{port};
   my $request = delete $args{request};

   my $stall_timeout = $args{stall_timeout} // $self->{stall_timeout};

   $self->prepare_request( $request );

   if( $self->{require_SSL} and not $args{SSL} ) {
      return Future->fail( "Non-SSL request is not allowed with 'require_SSL' set",
         http => undef, $request );
   }

   return $self->get_connection(
      host => $args{proxy_host} || $self->{proxy_host} || $host,
      port => $args{proxy_port} || $self->{proxy_port} || $port,
      ( defined $args{family} ? ( family => $args{family} ) : () ),
      SSL  => $args{SSL},
      %{ $self->{ssl_params} },
      ( map { m/^SSL_/ ? ( $_ => $args{$_} ) : () } keys %args ),
   )->then( sub {
      my ( $conn ) = @_;
      $args{on_ready} ? $args{on_ready}->( $conn )->then_done( $conn )
                      : Future->done( $conn )
   })->then( sub {
      my ( $conn ) = @_;

      return $conn->request(
         request => $request,
         stall_timeout => $stall_timeout,
         %args,
      );
   } );
}

sub _should_redirect
{
   my ( $response ) = @_;

   # Should only redirect if we actually have a Location header
   return 0 unless $response->is_redirect and defined $response->header( "Location" );

   my $req_method = $response->request->method;
   # Should only redirect GET or HEAD requests
   return $req_method eq "GET" || $req_method eq "HEAD";
}

sub _do_request
{
   my $self = shift;
   my %args = @_;

   my $host = $args{host};
   my $port = $args{port};
   my $ssl  = $args{SSL};

   my $on_header = delete $args{on_header};

   my $redirects = defined $args{max_redirects} ? $args{max_redirects} : $self->{max_redirects};

   my $request = $args{request};
   my $response;
   my $reqf;
   # Defeat prototype
   my $future = &repeat( $self->_capture_weakself( sub {
      my $self = shift;
      my ( $previous_f ) = @_;

      if( $previous_f ) {
         my $previous_response = $previous_f->get;
         $args{previous_response} = $previous_response;

         my $location = $previous_response->header( "Location" );

         if( $location =~ m{^http(?:s?)://} ) {
            # skip
         }
         elsif( $location =~ m{^/} ) {
            my $hostport = ( $port != HTTP_PORT ) ? "$host:$port" : $host;
            $location = "http://$hostport" . $location;
         }
         else {
            return Future->fail( "Unrecognised Location: $location", http => $previous_response, $request );
         }

         my $loc_uri = URI->new( $location );
         unless( $loc_uri ) {
            return Future->fail( "Unable to parse '$location' as a URI", http => $previous_response, $request );
         }

         $self->debug_printf( "REDIRECT $loc_uri" );

         $args{on_redirect}->( $previous_response, $location ) if $args{on_redirect};

         %args = $self->_make_request_for_uri( $loc_uri, %args );
         $request = $args{request};

         undef $host; undef $port; undef $ssl;
      }

      my $uri = $request->uri;
      if( defined $uri->scheme and $uri->scheme =~ m/^http(s?)$/ ) {
         $host = $uri->host if !defined $host;
         $port = $uri->port if !defined $port;
         $ssl = ( $uri->scheme eq "https" );
      }

      defined $host or croak "Expected 'host'";
      defined $port or $port = ( $ssl ? HTTPS_PORT : HTTP_PORT );

      return $reqf = $self->_do_one_request(
         host => $host,
         port => $port,
         SSL  => $ssl,
         %args,
         on_header => $self->_capture_weakself( sub {
            my $self = shift;
            ( $response ) = @_;

            return $on_header->( $response ) unless $response->is_redirect;

            # Consume and discard the entire body of a redirect
            return sub {
               return if @_;
               return $response;
            };
         } ),
      );
   } ),
   while => sub {
      my $f = shift;
      return 0 if $f->failure or $f->is_cancelled;
      return _should_redirect( $response ) && $redirects--;
   } );

   if( $self->{fail_on_error} ) {
      $future = $future->then_with_f( sub {
         my ( $f, $resp ) = @_;
         my $code = $resp->code;

         if( $code =~ m/^[45]/ ) {
            my $message = $resp->message;
            $message =~ s/\r$//; # HTTP::Message bug

            return Future->fail( "$code $message", http => $resp, $request );
         }

         return $f;
      });
   }

   return $future;
}

sub do_request
{
   my $self = shift;
   my %args = @_;

   if( my $uri = delete $args{uri} ) {
      %args = $self->_make_request_for_uri( $uri, %args );
   }
   elsif( !defined $args{request} ) {
      croak "Require either 'uri' or 'request' argument";
   }

   if( $args{on_header} ) {
      # ok
   }
   elsif( $args{on_response} or defined wantarray ) {
      $args{on_header} = sub {
         my ( $response ) = @_;
         return sub {
            if( @_ ) {
               $response->add_content( @_ );
            }
            else {
               return $response;
            }
         };
      }
   }
   else {
      croak "Expected 'on_response' or 'on_header' as CODE ref or to return a Future";
   }

   my $on_error = delete $args{on_error};
   my $timeout = defined $args{timeout} ? $args{timeout} : $self->{timeout};

   my $future = $self->_do_request( %args );

   if( defined $timeout ) {
      $future = Future->wait_any(
         $future,
         $self->loop->timeout_future( after => $timeout )
                    ->transform( fail => sub { "Timed out", timeout => } ),
      );
   }

   $future->on_done( $self->_capture_weakself( sub {
      my $self = shift;
      my $response = shift;
      $self->process_response( $response );
   } ) );

   $future->on_fail( sub {
      my ( $message, $name, @rest ) = @_;
      $on_error->( $message, @rest );
   }) if $on_error;

   if( my $on_response = delete $args{on_response} ) {
      $future->on_done( sub {
         my ( $response ) = @_;
         $on_response->( $response );
      });
   }

   # DODGY HACK:
   # In void context we'll lose reference on the ->wait_any Future, so the
   # timeout logic will never happen. So lets purposely create a cycle by
   # capturing the $future in on_done/on_fail closures within itself. This
   # conveniently clears them out to drop the ref when done.
   return $future if defined wantarray;

   $future->on_ready( sub { undef $future } );
}

sub _make_request_for_uri
{
   my $self = shift;
   my ( $uri, %args ) = @_;

   if( !ref $uri ) {
      $uri = URI->new( $uri );
   }
   elsif( blessed $uri and !$uri->isa( "URI" ) ) {
      croak "Expected 'uri' as a URI reference";
   }

   my $method = delete $args{method} || "GET";

   $args{host} = $uri->host;
   $args{port} = $uri->port;

   my $request;

   if( $method eq "POST" ) {
      defined $args{content} or croak "Expected 'content' with POST method";

      # Lack of content_type didn't used to be a failure condition:
      ref $args{content} or defined $args{content_type} or
         carp "No 'content_type' was given with 'content'";

      # This will automatically encode a form for us
      $request = HTTP::Request::Common::POST( $uri, Content => $args{content}, Content_Type => $args{content_type} );
   }
   else {
      $request = HTTP::Request->new( $method, $uri );
      if( defined $args{content} ) {
         defined $args{content_type} or carp "No 'content_type' was given with 'content'";

         $request->content( $args{content} );
         $request->content_type( $args{content_type} // "" );
      }
   }

   $request->protocol( "HTTP/1.1" );
   $request->header( Host => $uri->host );

   my $headers = $args{headers};
   if( $headers and reftype $headers eq "ARRAY" ) {
      $request->header( @$_ ) for pairs @$headers;
   }
   elsif( $headers and reftype $headers eq "HASH" ) {
      $request->header( $_, $headers->{$_} ) for keys %$headers;
   }

   my ( $user, $pass );

   if( defined $uri->userinfo ) {
      ( $user, $pass ) = split( m/:/, $uri->userinfo, 2 );
   }
   elsif( defined $args{user} and defined $args{pass} ) {
      $user = $args{user};
      $pass = $args{pass};
   }

   if( defined $user and defined $pass ) {
      $request->authorization_basic( $user, $pass );
   }

   $args{request} = $request;

   return %args;
}

=head2 $response = $http->GET( $uri, %args )->get

=head2 $response = $http->HEAD( $uri, %args )->get

=head2 $response = $http->PUT( $uri, $content, %args )->get

=head2 $response = $http->POST( $uri, $content, %args )->get

Convenient wrappers for using the C<GET>, C<HEAD>, C<PUT> or C<POST> methods
with a C<URI> object and few if any other arguments, returning a C<Future>.

Remember that C<POST> with non-form data (as indicated by a plain scalar
instead of an C<ARRAY> reference of form data name/value pairs) needs a
C<content_type> key in C<%args>.

=cut

sub GET
{
   my $self = shift;
   my ( $uri, @args ) = @_;
   return $self->do_request( method => "GET", uri => $uri, @args );
}

sub HEAD
{
   my $self = shift;
   my ( $uri, @args ) = @_;
   return $self->do_request( method => "HEAD", uri => $uri, @args );
}

sub PUT
{
   my $self = shift;
   my ( $uri, $content, @args ) = @_;
   return $self->do_request( method => "PUT", uri => $uri, content => $content, @args );
}

sub POST
{
   my $self = shift;
   my ( $uri, $content, @args ) = @_;
   return $self->do_request( method => "POST", uri => $uri, content => $content, @args );
}

=head1 SUBCLASS METHODS

The following methods are intended as points for subclasses to override, to
add extra functionallity.

=cut

=head2 $http->prepare_request( $request )

Called just before the C<HTTP::Request> object is sent to the server.

=cut

sub prepare_request
{
   my $self = shift;
   my ( $request ) = @_;

   $request->init_header( 'User-Agent' => $self->{user_agent} ) if length $self->{user_agent};
   $request->init_header( "Connection" => "keep-alive" );

   $self->{cookie_jar}->add_cookie_header( $request ) if $self->{cookie_jar};
}

=head2 $http->process_response( $response )

Called after a non-redirect C<HTTP::Response> has been received from a server.
The originating request will be set in the object.

=cut

sub process_response
{
   my $self = shift;
   my ( $response ) = @_;

   $self->{cookie_jar}->extract_cookies( $response ) if $self->{cookie_jar};
}

=head1 CONTENT DECODING

If the required decompression modules are installed and available, compressed
content can be decoded. If the received C<Content-Encoding> is recognised and
the required module is available, the content is transparently decoded and the
decoded content is returned in the resulting response object, or passed to the
data chunk handler. In this case, the original C<Content-Encoding> header will
be deleted from the response, and its value will be available instead as
C<X-Original-Content-Encoding>.

The following content encoding types are recognised by these modules:

=over 4

=cut

=item * gzip (q=0.7) and deflate (q=0.5)

Recognised if L<Compress::Raw::Zlib> version 2.057 or newer is installed.

=cut

if( eval { require Compress::Raw::Zlib and $Compress::Raw::Zlib::VERSION >= 2.057 } ) {
   my $make_zlib_decoder = sub {
      my ( $bits ) = @_;
      my $inflator = Compress::Raw::Zlib::Inflate->new(
         -ConsumeInput => 0,
         -WindowBits => $bits,
      );
      sub {
         my $output;
         my $status = @_ ? $inflator->inflate( $_[0], $output )
                         : $inflator->inflate( "", $output, 1 );
         die "$status\n" if $status && $status != Compress::Raw::Zlib::Z_STREAM_END();
         return $output;
      };
   };

   # RFC1950
   __PACKAGE__->register_decoder(
      deflate => 0.5, sub { $make_zlib_decoder->( 15 ) },
   );

   # RFC1952
   __PACKAGE__->register_decoder(
      gzip => 0.7, sub { $make_zlib_decoder->( Compress::Raw::Zlib::WANT_GZIP() ) },
   );
}

=item * bzip2 (q=0.8)

Recognised if L<Compress::Bzip2> version 2.10 or newer is installed.

=cut

if( eval { require Compress::Bzip2 and $Compress::Bzip2::VERSION >= 2.10 } ) {
   __PACKAGE__->register_decoder(
      bzip2 => 0.8, sub {
         my $inflator = Compress::Bzip2::inflateInit();
         sub {
            return unless my ( $in ) = @_;
            my $out = $inflator->bzinflate( \$in );
            die $inflator->bzerror."\n" if !defined $out;
            return $out;
         };
      }
   );
}

=back

Other content encoding types can be registered by calling the following method

=head2 Net::Async::HTTP->register_decoder( $name, $q, $make_decoder )

Registers an encoding type called C<$name>, at the quality value C<$q>. In
order to decode this encoding type, C<$make_decoder> will be invoked with no
paramters, and expected to return a CODE reference to perform one instance of
decoding.

 $decoder = $make_decoder->()

This decoder will be invoked on string buffers to decode them until
the end of stream is reached, when it will be invoked with no arguments.

 $content = $decoder->( $encoded_content )
 $content = $decoder->() # EOS

=cut

{
   my %DECODERS; # {$name} = [$q, $make_decoder]

   sub register_decoder
   {
      shift;
      my ( $name, $q, $make_decoder ) = @_;

      $DECODERS{$name} = [ $q, $make_decoder ];
   }

   sub can_decode
   {
      shift;
      if( @_ ) {
         my ( $name ) = @_;

         return unless my $d = $DECODERS{$name};
         return $d->[1]->();
      }
      else {
         my @ds = sort { $DECODERS{$b}[0] <=> $DECODERS{$a}[0] } keys %DECODERS;
         return join ", ", map { "$_;q=$DECODERS{$_}[0]" } @ds;
      }
   }
}

=head1 EXAMPLES

=head2 Concurrent GET

The C<Future>-returning C<GET> method makes it easy to await multiple URLs at
once, by using the L<Future::Utils> C<fmap_void> utility 

 my @URLs = ( ... );

 my $http = Net::Async::HTTP->new( ... );
 $loop->add( $http );

 my $future = fmap_void {
    my ( $url ) = @_;
    $http->GET( $url )
         ->on_done( sub {
            my $response = shift;
            say "$url succeeded: ", $response->code;
            say "  Content-Type":", $response->content_type;
         } )
         ->on_fail( sub {
            my $failure = shift;
            say "$url failed: $failure";
         } );
 } foreach => \@URLs;

 $loop->await( $future );

=cut

=head1 SEE ALSO

=over 4

=item *

L<http://tools.ietf.org/html/rfc2616> - Hypertext Transfer Protocol -- HTTP/1.1

=back

=head1 SPONSORS

Parts of this code, or bugfixes to it were paid for by

=over 2

=item *

SocialFlow L<http://www.socialflow.com>

=item *

Shadowcat Systems L<http://www.shadow.cat>

=item *

NET-A-PORTER L<http://www.net-a-porter.com>

=item *

Cisco L<http://www.cisco.com>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
