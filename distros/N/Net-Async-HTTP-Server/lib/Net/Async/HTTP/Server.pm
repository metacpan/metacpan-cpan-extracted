#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2020 -- leonerd@leonerd.org.uk

package Net::Async::HTTP::Server;

use strict;
use warnings;
use base qw( IO::Async::Listener );
IO::Async::Listener->VERSION( '0.61' );

our $VERSION = '0.13';

use Carp;

use Net::Async::HTTP::Server::Protocol;
use Net::Async::HTTP::Server::Request;

use Metrics::Any 0.05 '$metrics',
   strict      => 1,
   name_prefix => [qw( http server )];

$metrics->make_gauge( requests_in_flight =>
   description => "Count of the number of requests received that have not yet been completed",
   # no labels
);
$metrics->make_counter( requests  =>
   description => "Number of HTTP requests received",
   labels      => [qw( method )],
);
$metrics->make_counter( responses =>
   description => "Number of HTTP responses served",
   labels      => [qw( method code )],
);
$metrics->make_timer( request_duration =>
   description => "Duration of time spent processing requests",
   # no labels
);
$metrics->make_distribution( response_bytes =>
   description => "The size in bytes of responses sent",
   units       => "bytes",
   # no labels
);

=head1 NAME

C<Net::Async::HTTP::Server> - serve HTTP with C<IO::Async>

=head1 SYNOPSIS

 use Net::Async::HTTP::Server;
 use IO::Async::Loop;

 use HTTP::Response;

 my $loop = IO::Async::Loop->new();

 my $httpserver = Net::Async::HTTP::Server->new(
    on_request => sub {
       my $self = shift;
       my ( $req ) = @_;

       my $response = HTTP::Response->new( 200 );
       $response->add_content( "Hello, world!\n" );
       $response->content_type( "text/plain" );
       $response->content_length( length $response->content );

       $req->respond( $response );
    },
 );

 $loop->add( $httpserver );

 $httpserver->listen(
    addr => { family => "inet6", socktype => "stream", port => 8080 },
 )->get

 $loop->run;

=head1 DESCRIPTION

This module allows a program to respond asynchronously to HTTP requests, as
part of a program based on L<IO::Async>. An object in this class listens on a
single port and invokes the C<on_request> callback or subclass method whenever
an HTTP request is received, allowing the program to respond to it.

For accepting HTTP connections via L<PSGI> and L<Plack>, see also
L<Plack::Handler::Net::Async::HTTP::Server>.

=head2 Metrics

I<Since version 0.11.>

This module reports basic metrics about received requests and sent responses
via L<Metrics::Any>.

=cut

=head1 EVENTS

=head2 on_request $req

Invoked when a new HTTP request is received. It will be passed a
L<Net::Async::HTTP::Server::Request> object.

=cut

=head1 PARAMETERS

The following named parameters may be passed to C<new> or C<configure>:

=head2 request_class => STRING

Gives the name of the class that C<make_request> will construct. This is
provided as an alternative to overriding the C<make_request> method, for the
case where no other methods need overriding or other behaviour changed.

=cut

=head1 METHODS

As a small subclass of L<IO::Async::Listener>, this class does not provide many
new methods of its own. The superclass provides useful methods to control the
basic operation of this server.

Specifically, see the L<IO::Async::Listener/listen> method on how to actually
bind the server to a listening socket to make it accept requests.

=cut

sub _init
{
   my $self = shift;
   my ( $params ) = @_;

   $params->{handle_class} = "Net::Async::HTTP::Server::Protocol";

   $params->{request_class} ||= "Net::Async::HTTP::Server::Request";

   $self->SUPER::_init( $params );
}

sub configure
{
   my $self = shift;
   my %params = @_;

   foreach (qw( on_request request_class )) {
      $self->{$_} = delete $params{$_} if exists $params{$_};
   }

   $self->SUPER::configure( %params );
}

sub _add_to_loop
{
   my $self = shift;

   $self->can_event( "on_request" ) or croak "Expected either a on_request callback or an ->on_request method";

   $self->SUPER::_add_to_loop( @_ );
}

sub on_accept
{
   my $self = shift;
   my ( $conn ) = @_;

   $conn->configure(
      on_closed => sub {
         my $conn = shift;
         $conn->on_closed();

         $conn->remove_from_parent;
      },
   );

   $self->add_child( $conn );

   return $conn;
}

=head2 make_request

   $request = $server->make_request( @args )

Invoked by the protocol stream handler to create a new request object
representing an incoming request. This is provided as a method for subclasses
to overload, if they wish to represent requests with subclasses of the basic
request representation.

=cut

sub make_request
{
   my $self = shift;
   return $self->{request_class}->new( @_ );
}

sub _received_request
{
   my $self = shift;
   my ( $request ) = @_;

   if( $metrics ) {
      $metrics->inc_gauge( requests_in_flight => );

      $metrics->inc_counter( requests => [ method => $request->method ] );
      $self->{request_received_timestamp}{$request} = $self->loop->time;
   }

   $self->invoke_event( on_request => $request );
}

sub _done_request
{
   my $self = shift;
   my ( $request ) = @_;

   if( $metrics ) {
      my $received_timestamp = delete $self->{request_received_timestamp}{$request};

      $metrics->dec_gauge( requests_in_flight => );

      $metrics->inc_counter( responses => [ method => $request->method, code => $request->response_status_code ] );
      $metrics->report_timer( request_duration => $self->loop->time - $received_timestamp );
      $metrics->report_distribution( response_bytes => $request->bytes_written );
   }
}

=head1 TODO

=over 2

=item *

Don't use L<HTTP::Message> objects as underlying implementation

=item *

Consider how to do streaming request inbound

=item *

Lots more testing

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
