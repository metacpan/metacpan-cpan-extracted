#!/usr/bin/perl

# Parse a traceroute full of wierd ipv6 addresses to stress the cheezy
# v6 address parser.  You will not see most of these addresses in a
# traceroute, but seems better safe than sorry.

use strict;
use warnings;

use Test::More tests => 9;
use Net::Traceroute;

require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_host(1, 1), "2002:c058:6301::1", "hop 1, boring address");
is($tr->hop_query_host(2, 1), "::1", "hop 2, localhost");
is($tr->hop_query_host(3, 1), "2::", "hop 3, leading bytes only");
is($tr->hop_query_host(4, 1), "::", "hop 4, in6addr_any");
is($tr->hop_query_host(5, 1), "::ffff:1.2.3.4", "hop 5, v4 mapped");
is($tr->hop_query_host(6, 1), "::1.2.3.4", "hop 6, v4 mapped");
is($tr->hop_query_host(7, 1), "dead:beef:8917:cafe:d00d:f00f:feed:f00b", "hop 7, fully expanded");
is($tr->hop_query_host(8, 1), "dead:beef:8917:cafe:d00d:f00f:10.7.91.152", "hop 8, expanded and v4 mapped");
is($tr->hop_query_host(9, 1), "2001:4860:b009::93", "hop 9, vanilla");

__END__
 1  2002:c058:6301::1  22.54 ms  22.481 ms  22.095 ms
 2  ::1  20.808 ms  23.063 ms  22.834 ms
 3  2::  24.019 ms  21.704 ms  21.923 ms
 4  ::  23.767 ms 2001:4860::1:0:755  23.029 ms 2001:4860::1:0:3be  23.817 ms
 5  ::ffff:1.2.3.4  30.173 ms  28.244 ms 2001:4860::1:0:5dc  29.486 ms
 6  ::1.2.3.4  40.747 ms 2001:4860::1:0:249f  62.25 ms 2001:4860::1:0:613  38.352 ms
 7  dead:beef:8917:cafe:d00d:f00f:feed:f00b  39.562 ms 2001:4860::31  43.566 ms 2001:4860::30  65.887 ms
 8  dead:beef:8917:cafe:d00d:f00f:10.7.91.152  38.801 ms 2001:4860:0:1::35  42.529 ms 2001:4860:0:1::37  47.7 ms
 9  2001:4860:b009::93  38.08 ms  38.072 ms  37.636 ms
