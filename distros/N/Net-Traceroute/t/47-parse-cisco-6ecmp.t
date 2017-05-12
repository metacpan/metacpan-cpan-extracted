#!/usr/bin/perl

use strict;
use warnings;

# Test parsing of cisco, ecmp over ipv6.

use Test::More tests => 13;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_queries(6), 3,
   "Hop 6 has 3 queries");

is($tr->hop_query_host(6, 1), "2001:4860::1:0:9FF",
   "Hop 6, query 1 host is 2001:4860::1:0:9FF");
is($tr->hop_query_time(6, 1), 32,
   "Hop 6, query 1 time is 32 msec");

is($tr->hop_query_host(6, 2), "2001:4860::1:0:5DC",
   "Hop 6, query 2 host is 2001:4860::1:0:5DC");
is($tr->hop_query_time(6, 2), 148,
   "Hop 6, query 2 time is 148 msec");

is($tr->hop_query_host(6, 3), "2001:4860::1:0:9FF",
   "Hop 6, query 3 host is 2001:4860::1:0:9FF");
is($tr->hop_query_time(6, 3), 32,
   "Hop 6, query 3 time is 32 msec");

is($tr->hop_query_host(9, 1), "2001:4860:0:1::8B",
   "Hop 9, query 1 host is 2001:4860:0:1::8B");
is($tr->hop_query_time(9, 1), 40,
   "Hop 9, query 1 time is 40 msec");

is($tr->hop_query_host(9, 2), "2001:4860:0:1::8F",
   "Hop 9, query 2 host is 2001:4860:0:1::8F");
is($tr->hop_query_time(9, 2), 52,
   "Hop 9, query 2 time is 52 msec");

is($tr->hop_query_host(9, 3), "2001:4860:0:1::8F",
   "Hop 9, query 3 host is 2001:4860:0:1::8F");
is($tr->hop_query_time(9, 3), 52,
   "Hop 9, query 3 time is 52 msec");

__END__

Type escape sequence to abort.
Tracing the route to 2001:4860:800E::6A

  1 2001:470:8917:9:2D0:B7FF:FE5E:7F36 4 msec 0 msec 4 msec
  2 2001:470:1F06:177::1 24 msec 24 msec 24 msec
  3 2001:470:0:5D::1 20 msec 24 msec 24 msec
  4 2001:504:F::27 32 msec 24 msec 24 msec
  5 2001:4860::1:0:755 24 msec 20 msec 116 msec
  6 2001:4860::1:0:9FF 32 msec
    2001:4860::1:0:5DC 148 msec
    2001:4860::1:0:9FF 32 msec
  7 2001:4860::1:0:7D9 44 msec
    2001:4860::1:0:82E 44 msec
    2001:4860::1:0:7D9 44 msec
  8 2001:4860::2:0:125 40 msec 44 msec 40 msec
  9 2001:4860:0:1::8B 40 msec
    2001:4860:0:1::8F 52 msec 52 msec
 10 2001:4860:800E::6A 44 msec 40 msec 40 msec
