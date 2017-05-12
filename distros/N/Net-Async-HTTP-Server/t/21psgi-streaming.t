#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::HTTP::Server::PSGI;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $server = Net::Async::HTTP::Server::PSGI->new(
   app => sub {}, # Will be set per test
);

$loop->add( $server );

$server->listen(
   addr => { family => "inet", socktype => "stream", ip => "127.0.0.1" },
   on_listen_error => sub { die "Test failed early - $_[-1]" },
);

my $C = IO::Socket::INET->new(
   PeerHost => $server->read_handle->sockhost,
   PeerPort => $server->read_handle->sockport,
) or die "Cannot connect - $@";

{
   $server->configure( app => sub {
      my $env = shift;

      open my $body, "<", \"Here is a IO-like string";

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         $body,
      ];
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Transfer-Encoding: chunked",
         "Content-Type: text/plain",
         '' ) .
      "18$CRLF" . "Here is a IO-like string" . $CRLF .
      "0$CRLF$CRLF";

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received IO-written response in chunked encoding' );
}

{
   $server->configure( app => sub {
      my $env = shift;

      open my $body, "<", \( my $content = "Here is a IO-like string" );

      return [
         200,
         [ "Content-Length" => length $content,
           "Content-Type" => "text/plain" ],
         $body,
      ];
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Content-Length: 24",
         "Content-Type: text/plain",
         '' ) .
      "Here is a IO-like string";

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received IO-written response with explicit length' );
}

{
   my $responder;
   $server->configure( app => sub {
      my $env = shift;
      return sub { $responder = shift };
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   wait_for { defined $responder };

   is( ref $responder, "CODE", '$responder is a CODE ref' );

   $responder->(
      [ 200, [ "Content-Type" => "text/plain" ], [ "body from responder" ] ]
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Content-Length: 19",
         "Content-Type: text/plain",
         '' ) .
      "body from responder";

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received responder-written response' );
}

{
   my $responder;
   $server->configure( app => sub {
      my $env = shift;
      return sub { $responder = shift };
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   wait_for { defined $responder };

   is( ref $responder, "CODE", '$responder is a CODE ref' );

   my $writer = $responder->(
      [ 200, [ "Content-Type" => "text/plain" ] ]
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Transfer-Encoding: chunked",
         "Content-Type: text/plain",
         '' );

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received responder-written header' );

   $buffer =~ s/^.*$CRLF$CRLF//s;

   $writer->write( "Some body " );

   $expect = "A${CRLF}Some body $CRLF";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;
   is( $buffer, "A${CRLF}Some body $CRLF", 'Received partial streamed body chunk' );
   $buffer = "";

   $writer->write( "content here" );
   $writer->close;

   $expect = "C${CRLF}content here$CRLF" .
             "0${CRLF}${CRLF}";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received streamed body chunk and EOF' );
   $buffer = "";
}

{
   my $responder;
   $server->configure( app => sub {
      my $env = shift;
      return sub { $responder = shift };
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   wait_for { defined $responder };

   is( ref $responder, "CODE", '$responder is a CODE ref' );

   my $writer = $responder->(
      [ 200, [ "Content-Length" => 22, "Content-Type" => "text/plain" ] ]
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Content-Length: 22",
         "Content-Type: text/plain",
         '' );

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received responder-written header' );

   $buffer =~ s/^.*$CRLF$CRLF//s;

   $writer->write( "Some body " );

   $expect = "Some body ";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;
   is( $buffer, "Some body ", 'Received partial streamed body' );
   $buffer = "";

   $writer->write( "content here" );
   $writer->close;

   $expect = "content here";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received streamed body' );
   $buffer = "";
}

done_testing;
