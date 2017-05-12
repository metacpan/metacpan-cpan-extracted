#!/usr/bin/perl

# Parse a traceroute that has a "*" in it.

use strict;
use warnings;

use Test::More tests => 11;

use Socket;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_stat(4, 1), TRACEROUTE_TIMEOUT, "Hop 4, query 1 is a timeout");
is($tr->hop_query_host(4, 1), inet_ntoa(INADDR_NONE), "Hop 4, query 1 is INADDR_NONE");
is($tr->hop_query_stat(4, 2), TRACEROUTE_OK, "Hop 4, query 2 is OK");
is($tr->hop_query_host(4, 0), "206.223.119.120", "Hop 4, query 0 is 206.223.119.120");
is($tr->hop_query_host(4, 2), "206.223.119.120", "Hop 4, query 2 is 206.223.119.120");
is($tr->hop_query_host(4, 3), "206.223.119.120", "Hop 4, query 3 is 206.223.119.120");
is($tr->hop_query_time(4, 2), 262.151, "Hop 4, query 2 time is correct");

is($tr->hop_query_stat(9, 1), TRACEROUTE_TIMEOUT, "Hop 9, query 1 is a timeout");
is($tr->hop_query_stat(9, 2), TRACEROUTE_TIMEOUT, "Hop 9, query 2 is a timeout");
is($tr->hop_query_stat(9, 3), TRACEROUTE_TIMEOUT, "Hop 9, query 3 is a timeout");
ok(!defined($tr->hop_query_stat(9, 0)), , "Hop 9, query 0 is undefined");

__END__
 1  66.92.73.1  29.216 ms  34.777 ms  23.062 ms
 2  69.17.83.201  19.124 ms  22.092 ms  19.860 ms
 3  69.17.87.24  44.491 ms  45.501 ms  46.231 ms
 4  * 206.223.119.120  262.151 ms  290.742 ms
 5  207.210.142.17  69.503 ms  68.633 ms  67.422 ms
 6  207.210.142.234  68.889 ms  68.660 ms  69.356 ms
 7  18.168.0.23  99.719 ms  71.103 ms  71.472 ms
 8  18.4.7.65  67.981 ms  67.483 ms  69.992 ms
 9  * * *
10  128.52.32.80  70.139 ms  68.373 ms  68.695 ms
