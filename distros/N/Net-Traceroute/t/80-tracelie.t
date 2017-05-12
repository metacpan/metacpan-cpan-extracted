#!/usr/bin/perl

# Exercise the ability to call traceroute through a pipe.  We use a
# mock vesion of traceroute that returns a constant result.
# This doesn't do much to exercise the peculiar timing issues that
# traceroute can generate with its bursty output.

use strict;
use warnings;

use Test::More;
use Net::Traceroute;
require "t/testlib.pl";

os_must_unixexec();
plan tests => 3;

my $tr = Net::Traceroute->new(
   trace_program => "./t/tracelie",
   host => "128.52.32.80"
   );

is($tr->hops(), 10, "hop count is 10");
is($tr->hop_query_host(1, 1), "66.92.73.1", "first hop is 66.2.73.1");
is($tr->hop_query_host(10, 1), "128.52.32.80", "last hop is 128.52.32.80");
