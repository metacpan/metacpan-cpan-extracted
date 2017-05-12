#!/usr/bin/perl

# Test a very basic ipv4 traceroute.  If this doesn't work, later
# tests probably won't either.

use strict;
use warnings;

use Test::More tests => 18;

use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hops(), 10, "has ten hops");
is($tr->hop_queries(1), 3, "hop 1 has 3 queries");

foreach my $q (1..3) {
    is($tr->hop_query_host(1, $q), "66.92.73.1", "hop 1, query $q is 66.92.73.1");
    is($tr->hop_query_stat(1, $q), TRACEROUTE_OK, "hop 1, query $q is TRACEROUTE_OK");
}

is($tr->hop_query_time(1, 0), 22.227, "hop 1, query 0 has correct time");
is($tr->hop_query_time(1, 1), 22.227, "hop 1, query 1 has correct time");
is($tr->hop_query_time(1, 2), 24.444, "hop 1, query 2 has correct time");
is($tr->hop_query_time(1, 3), 23.090, "hop 1, query 3 has correct time");

is($tr->hop_query_host(3, 1), "69.17.87.24", "hop 3, query 1 is 69.17.87.24");
is($tr->hop_query_time(3, 1), 47.690, "hop 3, query time is 47.690 ms");

is($tr->hop_query_host(10, 1),  "128.52.32.80", "hop 10, query 1 is 128.52.32.80");
is($tr->hop_query_time(10, 1), 71.539, "hop 10, query 1 has correct time");
is($tr->hop_query_time(10, 2), 68.564, "hop 10, query 2 has correct time");
is($tr->hop_query_time(10, 3), 69.101, "hop 10, query 3 has correct time");

__END__
 1  66.92.73.1  22.227 ms  24.444 ms  23.090 ms
 2  69.17.83.201  18.365 ms  21.828 ms  20.156 ms
 3  69.17.87.24  47.690 ms  46.479 ms  46.524 ms
 4  206.223.119.120  56.538 ms  76.455 ms  59.301 ms
 5  207.210.142.17  70.135 ms  69.110 ms  68.556 ms
 6  207.210.142.234  68.756 ms  69.293 ms  68.872 ms
 7  18.168.0.23  69.316 ms  71.269 ms  70.829 ms
 8  18.4.7.65  69.758 ms  69.793 ms  69.594 ms
 9  128.30.0.254  69.043 ms  68.092 ms  68.846 ms
10  128.52.32.80  71.539 ms  68.564 ms  69.101 ms
