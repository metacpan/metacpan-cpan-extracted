#!/usr/bin/env perl
# vim: ts=2 sw=2 expandtab

# Something in the request queue is discarding responses.
# Reported in https://rt.cpan.org/Ticket/Display.html?id=72055
#
# Losing a number of pings in the initial phase occurs when special
# conditions are meet:
#
# * Pings are sent to the same host.
# * Parallelism is 2 or more.
# * Al least 2 ping events are created in a row (initial pings).
#
# The number of lost pings: min( Parallelism, initial pings ) - 1.
#
# Correct behavior is for 1 response to be received, and the remaining
# N-1 requests to be forcibly timed out by subsequent duplicate
# requests.

use strict;
use warnings;

BEGIN {
  $| = 1;
  if ($> and ($^O ne 'VMS')) {
    print "1..0 # skipped: ICMP ping requires root privilege\n";
    exit 0;
  }
};

use Test::More tests => 2;

use POE qw( Component::Client::Ping );

POE::Component::Client::Ping->spawn(Parallelism => 10, OneReply => 1);

POE::Session->create(
  inline_states => {
    _start => sub {
      $_[HEAP]{got_answer} = $_[HEAP]{got_timeout} = $_[HEAP]{expected} = 0;

      # It's bad technique to send all the requets at once, but we're
      # doing this to expose a bug in the module's queuing logic.

      my @hosts = ( ('127.0.0.1') x 5 );
      foreach (@hosts) {
        ++$_[HEAP]{expected};
        $_[KERNEL]->post('pinger', 'ping', 'pong', $_);
      }
    },

    _stop => sub {
      is(
        $_[HEAP]{got_timeout}, $_[HEAP]{expected} - 1,
        "got the right number of timeouts"
      );
      is(
        $_[HEAP]{got_answer}, 1,
        "got the right number of answers"
      );
    },

    pong => sub {
      if (defined $_[ARG1]->[0]) {
        ++$_[HEAP]->{got_answer};
      }
      else {
        ++$_[HEAP]->{got_timeout};
      }
    },
  },
);

POE::Kernel->run;
