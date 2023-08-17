#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use Test::Metrics::Any;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);
$loop->add( $http );

my $peersock;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;

   $args{host}    eq "host0" or die "Expected $args{host} eq host0";
   $args{service} eq "80"    or die "Expected $args{service} eq 80";

   ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
   $self->set_handle( $selfsock );

   return Future->done( $self );
};

{
   # Do a request
   my $f = $http->do_request(
      method => "GET",
      uri    => URI->new( "http://host0" ),
   );

   wait_for { defined $peersock };

   is_metrics( {
      "http_client_requests_in_flight"  => 1,
   }, 'Metrics show a request in flight' );

   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   my $wrotelen = $peersock->syswrite(
      "HTTP/1.1 200 OK$CRLF" .
      "Content-Length: 12$CRLF" .
      $CRLF .
      "Hello, world" );

   wait_for { $f->is_ready };
   $f->get;

   is_metrics( {
      "http_client_requests_in_flight"  => 0,
      "http_client_requests method:GET" => 1,
      "http_client_responses method:GET code:200" => 1,
      "http_client_request_duration_total" => Test::Metrics::Any::positive,
      "http_client_response_bytes_total" => $wrotelen, # ensure every byte is accounted for
   }, 'Metrics are created for a request/response cycle' );
}

done_testing;
