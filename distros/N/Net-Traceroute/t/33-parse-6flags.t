#!/usr/bin/perl

# Parse a traceroute that has ICMP flags in it.

use strict;
use warnings;

use Test::More tests => 6;

use Socket;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_stat(11, 1), TRACEROUTE_UNREACH_FILTER_PROHIB,
   "hop 11, query 1 stat !P => FILTER_PROHIB");
is($tr->hop_query_host(11, 1), "2001:420:80:7:219:7ff:fea8:a400",
   "hop 11, query 1 is 2001:420:80:7:219:7ff:fea8:a400");
is($tr->hop_query_time(11, 1), 97.401,
   "hop 11, query 1 has correct time");

is($tr->hop_query_stat(11, 3), TRACEROUTE_UNREACH_FILTER_PROHIB,
   "hop 11, query 3 stat !P => FILTER_PROHIB");
is($tr->hop_query_host(11, 3), "2001:420:80:7:219:7ff:fea8:a400",
   "hop 11, query 3 is 2001:420:80:7:219:7ff:fea8:a400");
is($tr->hop_query_time(11, 3), 96.725,
   "hop 11, query 3 has correct time");

__END__
 1  2001:470:1f06:177::1  24.647 ms  26.4 ms  24.774 ms
 2  2001:470:0:5d::1  22.784 ms  21.811 ms  22.666 ms
 3  2001:470:0:10e::1  81.828 ms  93.557 ms  83.82 ms
 4  2001:470:0:18d::1  91.304 ms  96.888 ms  98.954 ms
 5  2001:470:0:2d::1  91.06 ms  121.751 ms  103.873 ms
 6  2001:470:0:43::2  92.725 ms  91.775 ms  92.697 ms
 7  2001:470:1f02:ab::2  95.527 ms  94.92 ms  95.466 ms
 8  2001:420:80:8::1  95.927 ms  96 ms  96.385 ms
 9  2001:420:80:6:c67d:4fff:fe8b:e2c0  99.028 ms  96.576 ms  97.183 ms
10  2001:420:80:7:219:7ff:fea8:a400  99.312 ms  99.683 ms  96.638 ms
11  2001:420:80:7:219:7ff:fea8:a400  97.401 ms !P  98.931 ms !P  96.725 ms !P
