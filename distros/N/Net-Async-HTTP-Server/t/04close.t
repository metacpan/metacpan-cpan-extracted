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

my $req;
my $server = Net::Async::HTTP::Server->new(
   on_request => sub {
      my $self = shift;
      ( $req ) = @_;
   },
);

$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

# close during request headers
{
   my $client = connect_client;

   $client->write(
      "GET /path?var=value HTTP/1.1$CRLF"
   );
   $client->close;

   $loop->loop_once( 0.1 ) for 1 .. 3;

   pass( "Client close during request headers doesn't crash" );
}

# close during request body
{
   my $client = connect_client;

   $client->write(
      "GET /path?var=value HTTP/1.1$CRLF" .
      "Content-Length: 100$CRLF" .
      $CRLF
   );

   $loop->loop_once( 0.1 );

   $client->close;

   $loop->loop_once( 0.1 ) for 1 .. 3;

   pass( "Client close during request body doesn't crash" );
}

# close during response
{
   my $client = connect_client;

   $client->write(
      "GET /path?var=value HTTP/1.1$CRLF" .
      "User-Agent: unit-test$CRLF" .
      $CRLF
   );

   wait_for { defined $req };

   $client->close;

   wait_for { $req->is_closed };
   ok( $req->is_closed, '$req->is_closd true after EOF on stream' );

   $req->write( "HTTP/1.1 200 OK$CRLF" .
                "Content-Length: 0$CRLF" .
                $CRLF );
   $req->done;

   $loop->loop_once( 0.1 );

   pass( "Attempts to write to closed request do not fail" );
}

{
   my $client = connect_client;

   $client->write(
      "GET /path?var=value HTTP/1.1$CRLF" .
      "User-Agent: unit-test$CRLF" .
      $CRLF
   );

   wait_for { defined $req };

   $client->close;

   # Don't give it time to register this fact yet...

   $req->write( "HTTP/1.1 200 OK$CRLF" .
                "Content-Length: 0$CRLF" .
                $CRLF );
   $req->done;

   $loop->loop_once( 0.1 );

   pass( "Attempts to write to closed request do not fail" );
}

done_testing;
