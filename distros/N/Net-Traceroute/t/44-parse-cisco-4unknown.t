#!/usr/bin/perl

use strict;
use warnings;

# Tests against cisco's "?" flag.

use Test::More tests => 18;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_queries(2), 3, "Hop 2 has 3 queries");
for my $query (1..3) {
    ok(!defined($tr->hop_query_host(2, $query)),
       "Hop 2, query $query host is not defined");
    is($tr->hop_query_stat(2, $query), TRACEROUTE_UNKNOWN,
       "Hop 2, query $query stat is TRACEROUTE_UNKNOWN");
}

is($tr->hop_query_host(4, 1), "67.100.37.9",
   "Hop 4, query 1 is 67.100.37.9");
TODO: {
    local $TODO = "Unknowns aren't quite right yet";
    is($tr->hop_queries(4), 3, "Hop 4 has 3 queries");
    ok(!defined($tr->hop_query_host(4, 2)),
       "Hop 4, query 2 host is not defined");
    is($tr->hop_query_stat(4, 2), TRACEROUTE_UNKNOWN,
       "Hop 4, query 2 status is TRACEROUTE_UNKNOWN");
}

is($tr->hop_queries(5), 3, "Hop 5 has 3 queries");
ok(!defined($tr->hop_query_host(5, 1)),
   "Hop 5, query 1 host is not defined");
is($tr->hop_query_stat(5, 1), TRACEROUTE_UNKNOWN,
   "Hop 5, query 1 status is TRACEROUTE_UNKNOWN");
is($tr->hop_query_host(5, 2), "65.47.144.33",
   "Hop 5, query 2 host is 65.47.144.33");
is($tr->hop_query_time(5, 2), 12,
   "Hop 5, query 2 time is 12 msec");
is($tr->hop_query_host(5, 3), "65.47.144.33",
   "Hop 5, query 3 host is 65.47.144.33");
is($tr->hop_query_time(5, 3), 20,
   "Hop 5, query 3 time is 20 msec");

__END__

Type escape sequence to abort.
Tracing the route to 192.148.252.10

  1 10.12.0.1 0 msec 4 msec 0 msec
  2  ?  ?  ?
  3 192.168.4.37 20 msec 16 msec 20 msec
  4 67.100.37.9 12 msec ?  16 msec
  5  ?
    65.47.144.33 12 msec 20 msec
  6 216.156.7.13 16 msec 16 msec 16 msec
  7 216.156.0.25 20 msec 20 msec 24 msec
  8 207.88.13.41 24 msec 20 msec 76 msec
  9 206.111.13.94 28 msec 24 msec 24 msec
 10 72.52.92.86 28 msec 36 msec 36 msec
 11 64.71.128.254 28 msec 28 msec 24 msec
 12 192.148.252.10 28 msec 28 msec 32 msec
