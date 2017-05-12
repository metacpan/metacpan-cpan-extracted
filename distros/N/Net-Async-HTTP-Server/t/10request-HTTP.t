#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::Stream;

use Net::Async::HTTP::Server;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my @pending;
my $server = Net::Async::HTTP::Server->new(
   on_request => sub { push @pending, $_[1] },
);

ok( defined $server, 'defined $server' );

$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

{
   my $client = connect_client;

   $client->write(
      "GET /some/path?var=value HTTP/1.1$CRLF" .
      "User-Agent: unit-test$CRLF" .
      $CRLF
   );

   wait_for { @pending };

   my $req = ( shift @pending )->as_http_request;

   isa_ok( $req, "HTTP::Request" );

   is( $req->method, "GET", '$req->method' );
   is( $req->uri->path, "/some/path", '$req->uri->path' );
   is( $req->uri->query, "var=value", '$req->uri->query' );
   is( $req->protocol, "HTTP/1.1", '$req->protocol' );
   is( $req->header( "User-Agent" ), "unit-test", '$req->header' );
}

done_testing;
