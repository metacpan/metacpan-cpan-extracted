#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
BEGIN {
   eval { require Net::Prometheus; Net::Prometheus->VERSION( '0.07_001' ) } or
      plan skip_all => "Net::Prometheus 0.07_001 is not available";
}

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

my $prom = Net::Prometheus->new;

# Now execute a request/response cycle; metrics should be incremented
{
   my $client = connect_client;

   $client->write( "GET /foo HTTP/1.1$CRLF" .
                   $CRLF );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $client => $buffer;
}

like( $prom->render,
   qr/^net_async_http_server_requests\{method="GET"\} 1/m,
   'Net::Prometheus contains HTTP server metrics' );

done_testing;
