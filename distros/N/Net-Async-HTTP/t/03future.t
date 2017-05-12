#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

{
   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $request = HTTP::Request->new(
      GET => "/some/path",
      [ Host => "myhost" ]
   );

   my $future = $http->do_request(
      host    => "myhost",
      request => $request,
   );

   ok( defined $future, '$future defined for request' );

   wait_for { $peersock };

   # Wait for the client to send its request
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Type: text/plain",
      "Content-Length: 12",
      "" ) . $CRLF .
      "Hello world!"
   );

   wait_for { $future->is_ready };

   my $response = $future->get;
   isa_ok( $response, "HTTP::Response", '$future->get for request' );

   is( $response->code, 200, '$response->code for request' );
}

{
   my $peersock;
   no warnings 'redefine';
   local *IO::Async::Handle::connect = sub {
      my $self = shift;
      my %args = @_;

      ( my $selfsock, $peersock ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";
      $self->set_handle( $selfsock );

      return Future->new->done( $self );
   };

   my $future = $http->do_request(
      method  => "GET",
      uri     => URI->new( "http://host0/some/path" ),
   );

   ok( defined $future, '$future defined for uri' );

   wait_for { $peersock };

   # Wait for the client to send its request
   my $request_stream = "";
   wait_for_stream { $request_stream =~ m/$CRLF$CRLF/ } $peersock => $request_stream;

   $peersock->syswrite( join( $CRLF,
      "HTTP/1.1 200 OK",
      "Content-Type: text/plain",
      "Content-Length: 12",
      "" ) . $CRLF .
      "Hello world!"
   );

   wait_for { $future->is_ready };

   my $response = $future->get;
   isa_ok( $response, "HTTP::Response", '$future->get for uri' );

   is( $response->code, 200, '$response->code for uri' );
}

done_testing;
