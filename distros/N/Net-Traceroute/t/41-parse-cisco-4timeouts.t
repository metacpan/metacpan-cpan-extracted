#!/usr/bin/perl

use strict;
use warnings;

# Basic tests of ipv4 traceroute on a cisco.

use Socket;
use Test::More tests => 11;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_stat(3, 1), TRACEROUTE_TIMEOUT, "Hop 3, query 1 is a timeout");
is($tr->hop_query_stat(3, 2), TRACEROUTE_TIMEOUT, "Hop 3, query 2 is a timeout");
is($tr->hop_query_stat(3, 3), TRACEROUTE_TIMEOUT, "Hop 3, query 3 is a timeout");
ok(!defined($tr->hop_query_stat(3, 0)), "Hop 3, query 0 is undefined");

is($tr->hop_query_stat(5, 1), TRACEROUTE_TIMEOUT, "Hop 5, query 1 is a timeout");
is($tr->hop_query_host(5, 1), inet_ntoa(INADDR_NONE), "Hop 5, query 1 is INADDR_NONE");
is($tr->hop_query_stat(5, 2), TRACEROUTE_OK, "Hop 5, query 2 is OK");

is($tr->hop_query_host(5, 0), "206.223.119.120", "Hop 5, query 0 is 206.223.119.120");
is($tr->hop_query_host(5, 2), "206.223.119.120", "Hop 5, query 2 is 206.223.119.120");
is($tr->hop_query_time(5, 2), 252, "Hop 5, query 2 has correct time");

is($tr->hop_query_stat(5, 3), TRACEROUTE_TIMEOUT, "Hop 5, query 3 is a timeout");

__END__

Type escape sequence to abort.
Tracing the route to 128.52.32.80

  1 10.12.0.1 0 msec 0 msec 0 msec
  2 66.92.73.1 24 msec 24 msec 24 msec
  3  *  *  *
  4 69.17.87.24 44 msec 48 msec 48 msec
  5  *
    206.223.119.120 252 msec *
  6 207.210.142.17 80 msec 224 msec 172 msec
  7 207.210.142.234 72 msec 72 msec 68 msec
  8 18.168.0.23 72 msec 68 msec 72 msec
  9 18.4.7.65 72 msec 72 msec 72 msec
 10 128.30.0.254 72 msec 68 msec 72 msec
 11 128.52.32.80 72 msec 72 msec 68 msec
