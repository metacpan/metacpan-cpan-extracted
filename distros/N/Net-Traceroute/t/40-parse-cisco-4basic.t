#!/usr/bin/perl

use strict;
use warnings;

# Basic tests of ipv4 traceroute on a cisco.

use Test::More tests => 12;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hops(), 8, "has eight hops");
is($tr->hop_queries(1), 3, "hop 1 has 3 queries");

foreach my $q (1..3) {
    is($tr->hop_query_host(1, $q), "10.12.0.1", "hop 1, query $q is 10.12.0.1");
    is($tr->hop_query_stat(1, $q), TRACEROUTE_OK, "hop 1, query $q is TRACEROUTE_OK");
}

is($tr->hop_query_time(6, 1), 36, "correct time for hop 6, query 1");
is($tr->hop_query_time(6, 2), 32, "correct time for hop 6, query 2");
is($tr->hop_query_time(6, 3), 28, "correct time for hop 6, query 3");

is($tr->hop_query_host(8, 1), "192.148.252.10", "hop 8 is 192.148.252.10");

__END__

Type escape sequence to abort.
Tracing the route to 192.148.252.10

  1 10.12.0.1 0 msec 0 msec 0 msec
  2 66.92.73.1 24 msec 24 msec 20 msec
  3 69.17.83.201 24 msec 20 msec 20 msec
  4 198.32.160.61 24 msec 24 msec 24 msec
  5 72.52.92.45 20 msec 24 msec 24 msec
  6 72.52.92.86 36 msec 32 msec 28 msec
  7 64.71.128.254 28 msec 28 msec 32 msec
  8 192.148.252.10 24 msec 28 msec 24 msec
