#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Refcount;
use IO::Async::Test;
use IO::Async::Loop;

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

my $port;
$loop->listen(
   host    => "127.0.0.1",
   service => 0,
   socktype => "stream",

   on_listen => sub {
      $port = shift->sockport;
   },

   on_stream => sub {
      my ( $stream ) = @_;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref ) = @_;
            return 0 unless $$buffref =~ s/^(.*?)$CRLF$CRLF//s;

            my $header = $1;

            $self->write(
               "HTTP/1.1 200 OK$CRLF" .
               "Content-Type: text/plain$CRLF" .
               "Content-Length: 2$CRLF" .
               "Connection: close$CRLF" .
               "$CRLF" .
               "OK"
            );

            return 1;
         },
      );

      $loop->add( $stream );
   },
)->get;

my $on_body_chunk;

$http->do_request(
   method => "GET",
   host => "127.0.0.1",
   port => $port,
   request => HTTP::Request->new(GET => "/"),

   on_header => sub {
      my ( $header ) = @_;
      # Needs to be a real closure
      return $on_body_chunk = sub { $header = $header; 1 };
   },
)->get;

is_oneref( $on_body_chunk, '$on_body_chunk has refcount 1 before EOF' );

done_testing;
