#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::Stream;

unless( eval { require Net::Async::HTTP::Server } ) {
   plan skip_all => "Net::Async::HTTP::Server is not available";
}
unless( eval { require Net::Async::HTTP } ) {
   plan skip_all => "Net::Async::HTTP is not available";
}

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $server = Net::Async::HTTP::Server->new(
   on_request => sub {
      my $self = shift;
      my ( $req ) = @_;

      my $content = "Response to " . join " ", $req->method, $req->path, "with " . length( $req->body ) . " bytes";

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

$loop->add( my $client = Net::Async::HTTP->new );

my ( $host, $port );
$server->listen(
   addr => { family => "inet", socktype => "stream", ip => "127.0.0.1", port => 0 },
   on_listen => sub {
      my $socket = $_[0]->read_handle;
      $host = $socket->sockhost;
      $port = $socket->sockport;
   },
)->get;

my $response;

$client->do_request(
   uri => URI->new( "http://$host:$port/" ),
   on_response => sub {
      ( $response ) = @_;
   },
   on_error => sub { die "Test failed early - $_[-1]\n" },
);

wait_for { $response };

is( $response->code, 200, '$response->code' );
is( $response->content_type, "text/plain", '$response->content_type' );
is( $response->content, "Response to GET / with 0 bytes", '$response->content' );

done_testing;
