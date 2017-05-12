#! /usr/bin/perl
# -*- perl -*-
# vim: ts=2 sw=2 filetype=perl expandtab

use strict;
use warnings;

use Test::More tests => 1;

use POE;
use POE::Component::Curl::Multi;
use POE::Component::Server::TCP;
use HTTP::Request::Common qw[GET];
use Socket;

POE::Component::Curl::Multi->spawn(
 Alias => 'ua',
 Timeout => 60,
);

# We are testing against a localhost server.
# Don't proxy, because localhost takes on new meaning.
BEGIN {
  delete $ENV{HTTP_PROXY};
  delete $ENV{http_proxy};
}

POE::Session->create(
   inline_states => {
    _start => sub {
      my ($kernel) = $_[KERNEL];

      $kernel->alias_set('Main');

      # Spawn discard TCP server
      POE::Component::Server::TCP->new (
        Alias       => 'Discard',
        Address     => '127.0.0.1',
        Port        => 0,
        ClientInput => sub {}, # discard
        Started     => sub {
          my ($kernel, $heap) = @_[KERNEL, HEAP];
          my $port = (sockaddr_in($heap->{listener}->getsockname))[0];
          $kernel->post('Main', 'set_port', $port);
        }
      );
    },
    set_port => sub {
      my ($kernel, $port) = @_[KERNEL, ARG0];

      my $url = "http://127.0.0.1:$port/";

      my $req = GET $url;
      $kernel->post(ua => request => response => $req);
      $kernel->delay( cancel_it => 10, $req );
    },
    response => sub {
      my ($kernel, $rspp) = @_[KERNEL, ARG1];
      my $rsp = $rspp->[0];

      $kernel->delay('no_response'); # Clear timer
      ok($rsp->code == 408, "received error " . $rsp->code . " (wanted 408)");
      $kernel->post(Discard => 'shutdown');
      $kernel->post(ua => 'shutdown');
    },
    no_response => sub {
      my $kernel = $_[KERNEL];
      fail("didn't receive error 408");
      $kernel->post(Discard => 'shutdown');
      $kernel->post(ua => 'shutdown');
    },
    cancel_it => sub {
      my ($kernel,$req) = @_[KERNEL,ARG0];
      $kernel->call(ua => cancel => $req);
      $kernel->delay( no_response => 10 );
    },
  }
);

POE::Kernel->run;
exit;
