#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use IO::Async::Loop;
use IO::Async::Test;

use Net::Async::HTTP::Server::PSGI;

my $CRLF = "\x0d\x0a";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $received_env;

# Create an application sending 2 of the same header keys
# See also
#   https://rt.cpan.org/Ticket/Display.html?id=148426

my $server = Net::Async::HTTP::Server::PSGI->new(
   app => sub {
      # Simplest PSGI app
      $received_env = shift;
      return [
         200,
         [
            "Content-Type" => "text/plain",
            "X-test" => "test1",
            "X-test" => "test2",
         ],
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

$C->write(
   "GET / HTTP/1.1$CRLF" .
   $CRLF
);

my $buffer = "";
wait_for_stream { $buffer =~ m/$CRLF$CRLF/ } $C => $buffer;

# We expect the headers to have both X-Test values
like( $buffer,
   qr/${CRLF}X-Test: test1${CRLF}X-Test: test2${CRLF}/,
   'Server can set the same header twice'
);

done_testing;
