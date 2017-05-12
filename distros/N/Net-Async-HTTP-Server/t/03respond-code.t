#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;
use IO::Async::Loop;

use IO::Async::Stream;
use HTTP::Response;

use Net::Async::HTTP::Server;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my @pending;
my $server = Net::Async::HTTP::Server->new(
   on_request => sub { shift; push @pending, $_[0] },
);

$loop->add( $server );

sub connect_client
{
   my ( $S1, $S2 ) = IO::Async::OS->socketpair( undef, "stream" );
   $server->on_accept( Net::Async::HTTP::Server::Protocol->new( handle => $S2 ) );
   return $S1;
}

{
   my $client = connect_client;

   $client->write( "GET /chunked HTTP/1.1$CRLF$CRLF" );

   wait_for { @pending };
   my $request = shift @pending;

   $request->write( "HTTP/1.1 200 OK$CRLF" .
      "Content-Type: text/plain$CRLF" .
      $CRLF
   );

   my @data = ("Hello, ", "world!", $CRLF );
   $request->write( sub {
      return shift @data;
   } );

   $request->done;

   my $buffer = "";
   my $header;
   wait_for_stream { $buffer =~ s/(^.*$CRLF$CRLF)//s or return 0; $header = $1; 1; } $client => $buffer;

   is( $header,
       "HTTP/1.1 200 OK$CRLF" .
       "Content-Type: text/plain$CRLF" .
       $CRLF,
       'Response header' );

   wait_for_stream { $buffer =~ m/$CRLF/ } $client => $buffer;

   is( $buffer,
       "Hello, world!$CRLF",
       'body content in $buffer' );
}

done_testing;
