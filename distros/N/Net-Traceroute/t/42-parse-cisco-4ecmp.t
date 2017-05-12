#!/usr/bin/perl

use strict;
use warnings;

# Basic tests of ipv4 traceroute on a cisco.

use Test::More tests => 6;
use Net::Traceroute;
require "t/testlib.pl";

my $tr = parsefh(*DATA);

is($tr->hop_query_host(8, 1), "4.69.145.13", "hop 8, query 1 host is as expected");
is($tr->hop_query_time(8, 1), 64, "hop 8, query 1 time is as expected");

is($tr->hop_query_host(8, 2), "4.69.145.141", "hop 8, query 2 host is as expected");
is($tr->hop_query_time(8, 2), 56, "hop 8, query 2 time is as expected");

is($tr->hop_query_host(8, 3), "4.69.145.77", "hop 8, query 3 host is as expected");
is($tr->hop_query_time(8, 3), 59, "hop 8, query 3 time is as expected");

__END__

Type escape sequence to abort.
Tracing the route to 69.164.206.2

  1 10.12.0.1 0 msec 4 msec 0 msec
  2 66.92.73.1 24 msec 28 msec 24 msec
  3 69.17.83.201 20 msec 24 msec 20 msec
  4 166.90.136.33 24 msec 20 msec 24 msec
  5 4.68.97.62 28 msec 24 msec 36 msec
  6 4.69.148.37 24 msec 20 msec 24 msec
  7 4.69.137.121 56 msec 56 msec 68 msec
  8 4.69.145.13 64 msec
    4.69.145.141 56 msec
    4.69.145.77 59 msec
  9 4.59.32.30 56 msec 56 msec 60 msec
 10 70.87.253.10 56 msec
    70.87.255.42 56 msec
    70.87.253.26 56 msec
 11 70.87.253.122 60 msec
    70.87.255.122 60 msec *
 12 70.87.255.86 56 msec
    70.87.255.82 56 msec 60 msec
 13 67.18.7.90 60 msec *  60 msec
