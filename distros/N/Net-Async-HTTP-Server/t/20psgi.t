#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::HTTP::Server::PSGI;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $received_env;

my $server = Net::Async::HTTP::Server::PSGI->new(
   app => sub {
      # Simplest PSGI app
      $received_env = shift;
      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "Hello, world" ],
      ];
   },
);

ok( defined $server, 'defined $server' );

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
      # Simplest PSGI app
      $received_env = shift;
      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "Hello, world" ],
      ];
   } );

   $C->write(
      "GET / HTTP/1.1$CRLF" .
      "User-Agent: unittest$CRLF" .
      $CRLF
   );

   wait_for { defined $received_env };

   # Some keys are awkward, handle them first
   ok( defined(delete $received_env->{'psgi.input'}), "psgi.input exists" );
   ok( defined(delete $received_env->{'psgi.errors'}), "psgi.errors exists" );

   isa_ok( delete $received_env->{'psgix.io'}, "IO::Socket", 'psgix.io' );

   identical( delete $received_env->{'net.async.http.server'}, $server, "net.async.http.server is \$server" );
   can_ok( delete $received_env->{'net.async.http.server.req'}, "header" );
   identical( delete $received_env->{'io.async.loop'}, $loop, "io.async.loop is \$loop" );

   is_deeply( $received_env,
      {
         PATH_INFO       => "",
         QUERY_STRING    => "",
         REMOTE_ADDR     => "127.0.0.1",
         REMOTE_PORT     => $C->sockport,
         REQUEST_METHOD  => "GET",
         REQUEST_URI     => "/",
         SCRIPT_NAME     => "",
         SERVER_NAME     => "127.0.0.1",
         SERVER_PORT     => $server->read_handle->sockport,
         SERVER_PROTOCOL => "HTTP/1.1",

         HTTP_USER_AGENT => "unittest",

         'psgi.version'      => [1,0],
         'psgi.url_scheme'   => "http",
         'psgi.run_once'     => 0,
         'psgi.multiprocess' => 0,
         'psgi.multithread'  => 0,
         'psgi.streaming'    => 1,
         'psgi.nonblocking'  => 1,

         'psgix.input.buffered' => 1,
      },
      'received $env in PSGI app'
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Content-Length: 12",
         "Content-Type: text/plain",
         '' ) .
      "Hello, world";

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received ARRAY-written response' );
}

{
   undef $received_env;
   $C->write(
      "GET /path/here HTTP/1.1$CRLF" .
      "User-Agent: unittest$CRLF" .
      $CRLF
   );

   wait_for { defined $received_env };
   is( $received_env->{PATH_INFO}, "/path/here", 'PATH_INFO for non-root path' );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $C => $buffer;
}

{
   my $received_env;
   $server->configure( app => sub {
      my $env = $received_env = shift;
      my $input = delete $env->{'psgi.input'};

      my $content = "";
      while( $input->read( my $buffer, 1024 ) ) {
         $content .= $buffer;
      }

      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ "Input was: $content" ],
      ];
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      "Content-Length: 18$CRLF" .
      "Content-Type: text/plain$CRLF" .
      $CRLF .
      "Some data on STDIN"
   );

   my $expect = join( "", map "$_$CRLF",
         "HTTP/1.1 200 OK",
         "Content-Length: 29",
         "Content-Type: text/plain",
         '' ) .
      "Input was: Some data on STDIN";

   my $buffer = "";
   wait_for_stream { length $buffer >= length $expect } $C => $buffer;

   is( $buffer, $expect, 'Received ARRAY-written response with stdin reading' );

   is( $received_env->{CONTENT_LENGTH}, 18, '$env->{CONTENT_LENGTH}' );
   ok( !exists $received_env->{HTTP_CONTENT_LENGTH}, 'no HTTP_CONTENT_LENGTH' );

   is( $received_env->{CONTENT_TYPE}, "text/plain", '$env->{CONTENT_TYPE}' );
   ok( !exists $received_env->{HTTP_CONTENT_TYPE}, 'no HTTP_CONTENT_TYPE' );
}

# Warnings about undef body (RT98985)
{
   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join " ", @_ };

   $server->configure( app => sub {
      return [
         200,
         [ "Content-Type" => "text/plain" ],
         [ undef ],
      ];
   } );

   $C->syswrite(
      "GET / HTTP/1.1$CRLF" .
      $CRLF
   );

   my $buffer = "";
   wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $C => $buffer;

   like( $warnings, qr/undefined value in PSGI body/, 'undef in body yields warning' );
}

done_testing;
