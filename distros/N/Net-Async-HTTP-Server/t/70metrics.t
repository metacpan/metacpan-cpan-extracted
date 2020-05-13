#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Metrics::Any;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::HTTP::Server;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $server = Net::Async::HTTP::Server->new(
   on_request => sub {
      my $self = shift;
      my ( $req ) = @_;

      my $content = "OK\n";

      $req->write( "HTTP/1.1 200 OK$CRLF" .
         "Content-Length: " . length( $content ) . $CRLF .
         "Content-Type: text/plain$CRLF" .
         $CRLF .
         $content
      );

      $req->done;
   },
);
$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

# Now execute a request/response cycle; metrics should be incremented
{
   my $client = connect_client;

   $client->write( "GET /foo HTTP/1.1$CRLF" .
                   $CRLF );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $client => $buffer;

   is_metrics( {
      "http_server_requests_in_flight"  => 0,
      "http_server_requests method:GET" => 1,
      "http_server_responses method:GET code:200" => 1,
      "http_server_response_bytes_total" => Test::Metrics::Any::positive,
   }, 'Metrics are created for a request/response cycle' );
}

done_testing;
