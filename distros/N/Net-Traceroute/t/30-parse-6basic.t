#!/usr/bin/perl

# Parse a basic traceroute6.

use strict;
use warnings;

use Test::More tests => 4;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_host(1, 1), "2001:470:1f06:177::1", "can extract first v6 addr");
is($tr->hop_query_time(1, 1), 27.047, "hop 1, query 1 time is correct");
is($tr->hop_query_time(1, 2), 23.471, "hop 1, query 2 time is correct");
is($tr->hop_query_host(8, 1), "2001:4f8:3:7:2e0:81ff:fe52:9a6b", "can extract last v6 addr");

__END__
 1  2001:470:1f06:177::1  27.047 ms  23.471 ms  25.256 ms
 2  2001:470:0:5d::1  25.026 ms  24.045 ms  24.046 ms
 3  2001:470:0:4e::1  45.484 ms  44.195 ms  45.763 ms
 4  2001:470:1:34::2  45.18 ms  47.433 ms  43.312 ms
 5  2001:500:71:6::1  46.941 ms  45.953 ms  62.494 ms
 6  2001:4f8:0:1::4a:1  100.9 ms  100.014 ms  103.981 ms
 7  2001:4f8:1b:1::8:2  100.119 ms  99.906 ms  100.206 ms
 8  2001:4f8:3:7:2e0:81ff:fe52:9a6b  98.68 ms  98.704 ms  98.183 ms
