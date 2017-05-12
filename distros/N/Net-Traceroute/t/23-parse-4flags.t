#!/usr/bin/perl

# Parse a traceroute that has ICMP flags in it.

use strict;
use warnings;

use Test::More tests => 2;

use Socket;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_stat(11, 1), TRACEROUTE_UNREACH_FILTER_PROHIB);
is($tr->hop_query_host(11, 2), "69.81.18.12");

# Note that this traceroute is drawn from a debian linux box.
__END__
traceroute to 69.81.18.12 (69.81.18.12), 30 hops max, 40 byte packets
 1  128.30.16.4  0.331 ms  0.398 ms  0.434 ms
 2  128.30.0.253  0.283 ms  0.361 ms  0.378 ms
 3  18.4.7.1  0.412 ms  0.493 ms  0.741 ms
 4  18.168.1.18  0.720 ms  0.807 ms  0.841 ms
 5  18.168.1.50  0.824 ms  1.010 ms  0.992 ms
 6  207.210.142.233  0.637 ms  0.638 ms  0.675 ms
 7  207.210.142.18  22.941 ms  23.127 ms  23.156 ms
 8  206.223.119.4  23.795 ms  23.789 ms  23.995 ms
 9  69.17.87.23  49.330 ms  49.103 ms  49.098 ms
10  69.17.83.202  51.892 ms  52.239 ms  52.875 ms
11  69.81.18.12  70.229 ms !X  77.290 ms !X  75.179 ms !X
