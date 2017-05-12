#!/usr/bin/perl

use strict;
use warnings;

# Test flag parsing for cisco traceroutes.

use Test::More tests => 6;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_host(2, 1), "10.12.0.1",
   "hop 2, query 1 host is 10.12.0.1");
is($tr->hop_query_stat(2, 1), TRACEROUTE_UNREACH_NET,
   "hop 2, query 1 stat is TRACEROUTE_UNREACH_NET");

is($tr->hop_query_host(2, 2), "10.12.0.1",
   "hop 2, query 2 host is 10.12.0.1");
is($tr->hop_query_stat(2, 2), TRACEROUTE_UNREACH_NET,
   "hop 2, query 2 stat is TRACEROUTE_UNREACH_NET");

is($tr->hop_query_host(2, 3), "10.12.0.1",
   "hop 2, query 3 host is 10.12.0.1");
is($tr->hop_query_stat(2, 3), TRACEROUTE_UNREACH_NET,
   "hop 2, query 3 stat is TRACEROUTE_UNREACH_NET");

__END__

Type escape sequence to abort.
Tracing the route to 192.148.252.10

  1 10.12.0.1 0 msec 0 msec 0 msec
  2 10.12.0.1 !N  !N  !N
