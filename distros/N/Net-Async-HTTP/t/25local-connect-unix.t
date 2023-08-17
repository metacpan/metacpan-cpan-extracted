#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;
use IO::Async::Test;
use IO::Async::Loop;

$^O eq "linux" or
   plan skip_all => "Abstract AF_UNIX paths only work on Linux";

use Net::Async::HTTP;

my $CRLF = "\x0d\x0a"; # because \r\n isn't portable

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my $http = Net::Async::HTTP->new(
   user_agent => "", # Don't put one in request headers
);

$loop->add( $http );

my $path;
$loop->listen(
   addr => { family => "unix", path => "\0" },

   on_listen => sub {
      $path = shift->hostpath;
   },

   on_stream => sub {
      my ( $stream ) = @_;

      $stream->configure(
         on_read => sub {
            my ( $self, $buffref ) = @_;
            return 0 unless $$buffref =~ m/$CRLF$CRLF/;

            $self->write( "HTTP/1.1 200 OK$CRLF" .
                          "Content-Type: text/plain$CRLF" .
                          "Connection: close$CRLF" .
                          "$CRLF" .
                          "OK" );

            $self->close_when_empty;

            return 0;
         },
      );

      $loop->add( $stream );
   },
)->get;

my $response = $http->do_request(
   family => "unix",
   proxy_path => $path,
   uri => "http://unixtest/",

   on_error => sub { die "Test failed early - $_[-1]" },
)->get;

is( $response->content_type, "text/plain", '$response->content_type' );
is( $response->content, "OK", '$response->content' );

done_testing;
