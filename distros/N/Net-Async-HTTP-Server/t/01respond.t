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

ok( defined $server, 'defined $server' );

$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

{
   my $base_notifiers = $loop->notifiers;

   my $client = connect_client;

   is( scalar $loop->notifiers, $base_notifiers + 1, '$loop gains one Notifier after connect' );

   $client->write(
      "GET /path?var=value HTTP/1.1$CRLF" .
      "User-Agent: unit-test$CRLF" .
      $CRLF
   );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $client => $buffer;

   is( $buffer,
      "HTTP/1.1 200 OK$CRLF" .
      "Content-Length: 34$CRLF" .
      "Content-Type: text/plain$CRLF" .
      $CRLF .
      "Response to GET /path with 0 bytes",
      '$buffer from GET /' );

   is( $req->protocol, "HTTP/1.1", '$req->protocol' );
   is( $req->method, "GET", '$req->method' );
   is( $req->path, "/path", '$req->path' );

   is( $req->query_string, "var=value", '$req->query_string' );
   is_deeply( [ $req->query_form ], [ var => "value" ], '$req->query_form' );
   is_deeply( [ $req->query_param_names ], [qw( var )], '$req->query_param_names' );
   is( $req->query_param( "var" ), "value", '$req->query_param' );

   is( $req->header( "User-Agent" ), "unit-test", '$req->header' );

   is_deeply( [ $req->headers ],
              [ [ "User-Agent" => "unit-test" ] ],
              '$req->headers' );

   is( $req->response_status_line, "HTTP/1.1 200 OK", '$req->response_status_line' );
   is( $req->response_status_code, 200, '$req->response_status_code' );

   $client->close;

   $loop->loop_once( 0.01 ) for 1 .. 3;

   is( scalar $loop->notifiers, $base_notifiers, '$loop back to base level after $client->close' );
}

{
   my $client = connect_client;

   $client->write( "PUT /doc HTTP/1.1$CRLF" .
                   "Content-Type: text/plain$CRLF" .
                   "Content-Length: 13$CRLF" .
                   "$CRLF" .
                   "Hello, world!" );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $client => $buffer;

   is( $buffer,
      "HTTP/1.1 200 OK$CRLF" .
      "Content-Length: 34$CRLF" .
      "Content-Type: text/plain$CRLF" .
      $CRLF .
      "Response to PUT /doc with 13 bytes",
      '$buffer from PUT' );
}

{
   my $client = connect_client;

   $client->write( "GET / HTTP/1.0$CRLF$CRLF" );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $client => $buffer;

   ok( $client->read( my $tmp, 1 ) == 0, '$client no longer connected after HTTP/1.0 response' );
}

{
   my $client = connect_client;

   $client->write( "GET /one HTTP/1.1$CRLF$CRLF" .
                   "GET /two HTTP/1.1$CRLF$CRLF" );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF.*$CRLF$CRLF/s } $client => $buffer;

   is( $buffer,
       "HTTP/1.1 200 OK$CRLF" .
       "Content-Length: 33$CRLF" .
       "Content-Type: text/plain$CRLF" .
       $CRLF .
       "Response to GET /one with 0 bytes" .
    
       "HTTP/1.1 200 OK$CRLF" .
       "Content-Length: 33$CRLF" .
       "Content-Type: text/plain$CRLF" .
       $CRLF .
       "Response to GET /two with 0 bytes",
      '$buffer from two pipelined GETs' );
}

my @pending;
$server->configure(
   on_request => sub { shift; push @pending, $_[0] },
);

{
   my $client = connect_client;

   $client->write( "GET /three HTTP/1.1$CRLF$CRLF" .
                   "GET /four HTTP/1.1$CRLF$CRLF" );

   wait_for { @pending == 2 };

   my ( $first, $second ) = @pending;

   $second->write(
      "HTTP/1.1 200 OK$CRLF" .
      "Content-Length: 18$CRLF" .
      $CRLF .
      "Response to second"
   );
   $second->done;

   $first->write(
      "HTTP/1.1 200 OK$CRLF" .
      "Content-Length: 17$CRLF" .
      $CRLF .
      "Response to first"
   );
   $first->done;

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF.*$CRLF$CRLF/s } $client => $buffer;

   is( $buffer,
       "HTTP/1.1 200 OK$CRLF" .
       "Content-Length: 17$CRLF" .
       $CRLF .
       "Response to first" .
    
       "HTTP/1.1 200 OK$CRLF" .
       "Content-Length: 18$CRLF" .
       $CRLF .
       "Response to second",
      '$buffer from two pipelined GETs responded in reverse order' );
}

done_testing;
