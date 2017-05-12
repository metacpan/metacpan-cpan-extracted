#!/usr/bin/perl

# Parse a traceroute with equal-cost, multipath hops in it.
# More than one address will appear in a single line.

use strict;
use warnings;

use Test::More tests => 9;

use Socket;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_host(6, 1), "192.205.37.73", "Hop 6, query 1 is 192.205.37.73");
is($tr->hop_query_host(6, 2), "192.205.37.69", "Hop 6, query 2 is 192.205.37.69");
is($tr->hop_query_host(6, 3), "192.205.37.69", "Hop 6, query 1 is 192.205.37.69");

is($tr->hop_query_time(6, 1), 19.120, "Hop 6, query 1 time is correct");
is($tr->hop_query_time(6, 2), 21.108, "Hop 6, query 2 time is correct");
is($tr->hop_query_time(6, 3), 21.833, "Hop 6, query 3 time is correct");

is($tr->hop_query_host(11, 1), "12.130.0.170", "Hop 12, query 1 is 12.130.0.170");
is($tr->hop_query_host(11, 2), "12.130.0.174", "Hop 12, query 2 is 12.130.0.174");
is($tr->hop_query_host(11, 3), "12.130.0.170", "Hop 12, query 3 is 12.130.0.170");

__END__
 1  66.92.73.1  25.518 ms  21.853 ms  23.096 ms
 2  69.17.83.201  44.478 ms  21.338 ms  21.118 ms
 3  166.90.136.33  19.119 ms  20.112 ms  20.383 ms
 4  4.68.97.30  25.262 ms  20.623 ms  19.634 ms
 5  4.68.16.17  21.048 ms  22.342 ms  21.111 ms
 6  192.205.37.73  19.120 ms 192.205.37.69  21.108 ms  21.833 ms
 7  12.122.130.18  28.245 ms  26.277 ms  26.318 ms
 8  12.122.31.126  28.174 ms  28.983 ms  27.037 ms
 9  12.122.145.29  27.717 ms  26.768 ms  27.287 ms
10  12.122.254.14  28.717 ms  27.262 ms  26.585 ms
11  12.130.0.170  28.374 ms 12.130.0.174  26.768 ms 12.130.0.170  26.506 ms
12  12.130.9.196  27.715 ms  29.823 ms  29.365 ms
