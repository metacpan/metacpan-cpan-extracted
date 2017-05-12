#!/usr/bin/perl

use strict;
use warnings;

# Cisco ipv6 traceroute with icmp flags in it.

use Test::More tests => 5;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_queries(12), 3, "Hop 12 has 3 queries");
is($tr->hop_query_stat(12, 1), TRACEROUTE_UNREACH_FILTER_PROHIB,
   "Hop 12, query 1 status is TRACEROUTE_UNREACH_FILTER_PROHIB");
is($tr->hop_query_host(12, 1), "2001:420:80:7:219:7FF:FEA8:A400",
   "Hop 12, query 1 host is 2001:420:80:7:219:7FF:FEA8:A400");
is($tr->hop_query_stat(12, 2), TRACEROUTE_UNREACH_FILTER_PROHIB,
   "Hop 12, query 2 status is TRACEROUTE_UNREACH_FILTER_PROHIB");
is($tr->hop_query_stat(12, 3), TRACEROUTE_UNREACH_FILTER_PROHIB,
   "Hop 12, query 3 status is TRACEROUTE_UNREACH_FILTER_PROHIB");

__END__

Type escape sequence to abort.
Tracing the route to 2001:420:80:1::5

  1 2001:470:8917:9:2D0:B7FF:FE5E:7F36 0 msec 0 msec 0 msec
  2 2001:470:1F06:177::1 24 msec 32 msec 36 msec
  3 2001:470:0:5D::1 20 msec 20 msec 32 msec
  4 2001:470:0:10E::1 96 msec 108 msec 104 msec
  5 2001:470:0:18D::1 92 msec 92 msec 100 msec
  6 2001:470:0:2D::1 184 msec 116 msec 104 msec
  7 2001:470:0:43::2 200 msec 260 msec 188 msec
  8 2001:470:1F02:AB::2 92 msec 172 msec 96 msec
  9 2001:420:80:8::1 104 msec 96 msec 108 msec
 10 2001:420:80:6:C67D:4FFF:FE8B:E2C0 96 msec 100 msec 100 msec
 11 2001:420:80:7:219:7FF:FEA8:A400 100 msec 96 msec 100 msec
 12 2001:420:80:7:219:7FF:FEA8:A400 !A  !A  !A
