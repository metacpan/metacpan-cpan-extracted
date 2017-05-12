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

   my $response = HTTP::Response->new( 200 );
   $response->content_type( "text/plain" );
   $response->content_length( 20 );

   $request->respond_chunk_header( $response );

   my $buffer = "";
   my $header;
   wait_for_stream { $buffer =~ s/(^.*$CRLF$CRLF)//s or return 0; $header = $1; 1; } $client => $buffer;

   is( $header,
       "HTTP/1.1 200 OK$CRLF" .
       "Transfer-Encoding: chunked$CRLF" .
       "Content-Length: 20$CRLF" .
       "Content-Type: text/plain$CRLF" .
       $CRLF,
       'Response header' );

   $request->write_chunk( "a" x 10 );

   my $chunk;
   wait_for_stream { $buffer =~ s/(^[[:xdigit:]]+$CRLF.*$CRLF)//s or return 0; $chunk = $1; 1; } $client => $buffer;

   is( $chunk,
       "A$CRLF" .
       "aaaaaaaaaa" . $CRLF,
       '$chunk from first respond_chunk' );

   # Must not write zero-byte chunks
   $request->write_chunk( "" );

   $request->write_chunk( "b" x 10 );

   wait_for_stream { $buffer =~ s/(^[[:xdigit:]]+$CRLF.*$CRLF)//s or return 0; $chunk = $1; 1; } $client => $buffer;

   is( $chunk,
       "A$CRLF" .
       "bbbbbbbbbb" . $CRLF,
       '$chunk from second respond_chunk' );

   $request->write_chunk_eof;

   wait_for_stream { $buffer =~ s/(0$CRLF.*$CRLF)//s or return 0; $chunk = $1; 1; } $client => $buffer;

   is( $chunk,
       "0$CRLF" . $CRLF,
       '$chunk from eof' );
}

{
   my $client = connect_client;

   $client->write( "GET /chunked HTTP/1.1$CRLF$CRLF" );

   wait_for { @pending };
   my $request = shift @pending;

   my $response = HTTP::Response->new( 200 );
   $response->content_type( "text/plain" );
   $response->content( "X" x 20 );

   $request->respond_chunk_header( $response );

   my $buffer = "";
   my $header;
   wait_for_stream { $buffer =~ s/(^.*?$CRLF$CRLF)//s or return 0; $header = $1; 1; } $client => $buffer;

   is( $header,
       "HTTP/1.1 200 OK$CRLF" .
       "Transfer-Encoding: chunked$CRLF" .
       "Content-Type: text/plain$CRLF" .
       $CRLF,
       'Response header' );

   my $chunk;
   wait_for_stream { $buffer =~ s/(^[[:xdigit:]]+$CRLF.*$CRLF)//s or return 0; $chunk = $1; 1; } $client => $buffer;

   is( $chunk,
       "14$CRLF" .
       "XXXXXXXXXXXXXXXXXXXX$CRLF",
       '$chunk initially' );

   $request->write_chunk_eof;

   wait_for_stream { $buffer =~ s/(0$CRLF.*$CRLF)//s or return 0; $chunk = $1; 1; } $client => $buffer;

   is( $chunk,
       "0$CRLF" . $CRLF,
       '$chunk from eof' );
}

done_testing;
