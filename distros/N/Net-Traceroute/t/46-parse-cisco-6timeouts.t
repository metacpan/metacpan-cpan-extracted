#!/usr/bin/perl

use strict;
use warnings;

# Test timeouts for cisco ipv6 traceroute.

use Test::More tests => 15;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_queries(2), 3,
   "Hop 2 has 3 queries");
foreach my $query (1..3) {
    is($tr->hop_query_stat(2, $query), TRACEROUTE_TIMEOUT,
       "Hop 2, query $query stat is TRACEROUTE_TIMEOUT");
    is($tr->hop_query_host(2, $query), "255.255.255.255",
       "Hop 2, query $query host is 255.255.255.255");
}

is($tr->hop_queries(3), 3,
    "Hop 3 has 3 queries");

is($tr->hop_query_stat(3, 1), TRACEROUTE_TIMEOUT,
   "Hop 3, query 1 stat is TRACEROUTE_TIMEOUT");
is($tr->hop_query_host(3, 1), "255.255.255.255",
   "Hop 3, query 1 host is 255.255.255.255");
is($tr->hop_query_stat(3, 2), TRACEROUTE_TIMEOUT,
   "Hop 3, query 2 stat is TRACEROUTE_TIMEOUT");
is($tr->hop_query_host(3, 2), "255.255.255.255",
   "Hop 3, query 2 host is 255.255.255.255");

is($tr->hop_query_stat(3, 3), TRACEROUTE_OK,
   "Hop 3, query 3 stat is TRACEROUTE_OK");
is($tr->hop_query_host(3, 3), "2001:470:0:5D::1",
   "Hop 3, query 3 host is 2001:470:0:5D::1");
is($tr->hop_query_time(3, 3), 28,
   "Hop 3, query 3 time is 28 msec");

__END__

Type escape sequence to abort.
Tracing the route to 2001:4F8:0:2::D

  1 2001:470:8917:9:2D0:B7FF:FE5E:7F36 4 msec 0 msec 4 msec
  2  *  *  *
  3  *  *
    2001:470:0:5D::1 28 msec
  4 2001:470:0:36::1 28 msec 44 msec 36 msec
  5 2001:470:0:1B5::2 40 msec 40 msec 44 msec
  6 2001:470:0:CE::2 44 msec 44 msec 40 msec
  7 2001:500:61:6::1 44 msec 40 msec 44 msec
  8 2001:4F8:0:1::49:1 104 msec 124 msec 100 msec
  9 2001:4F8:0:2::D 100 msec 112 msec 120 msec
