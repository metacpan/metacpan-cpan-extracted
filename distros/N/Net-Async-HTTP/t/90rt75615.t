#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
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

            my $response = ( $header =~ m{^GET /redir} )
               ? "HTTP/1.1 301 Moved Permanently$CRLF" .
                 "Content-Length: 0$CRLF" .
                 "Location: /moved$CRLF" .
                 "Connection: close$CRLF" .
                 "$CRLF"
               : "HTTP/1.1 200 OK$CRLF" .
                 "Content-Type: text/plain$CRLF" .
                 "Content-Length: 2$CRLF" .
                 "Connection: close$CRLF" .
                 "$CRLF" .
                 "OK";

            $self->write( $response );

            return 1;
         },
      );

      $loop->add( $stream );
   },

   on_listen_error => sub { die "Test failed early - $_[-1]" },
   on_resolve_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $port };

my $code = \&IO::Async::Handle::connect;
no warnings 'redefine';
local *IO::Async::Handle::connect = sub {
   my $self = shift;
   my %args = @_;
   $args{service} = $port if $args{service} eq '80';
   $code->($self, %args);
};

my $response;

my $req = HTTP::Request->new(GET => '/redir');
$req->protocol('HTTP/1.1');
$req->header(Host => '127.0.0.1');
$http->do_request(
   method => "GET",
   host => '127.0.0.1',
   request => $req,

   on_response => sub {
      $response = $_[0];
   },

   on_error => sub { die "Test failed early - $_[-1]" },
);

wait_for { defined $response };

is( $response->content_type, "text/plain", '$response->content_type' );
is( $response->content, "OK", '$response->content' );

done_testing;
