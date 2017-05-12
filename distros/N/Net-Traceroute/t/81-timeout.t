#!/usr/bin/perl

# Test the timeout functionality of the pipe interface.
# Uses a helper that spews traceroute output, but then waits.

use strict;
use warnings;

use Test::More;
use Net::Traceroute;
use Time::HiRes qw(time);
require "t/testlib.pl";

os_must_unixexec();
plan tests => 2;

my $start = time();

my $tr = Net::Traceroute->new(
   trace_program => "./t/waitroute",
   host => "128.52.32.80",
   timeout => 2,
   );

my $end = time();
my $delta = $end - $start;

TODO: {
    todo_skip "Test borked", 1;
    is($tr->stat(), TRACEROUTE_TIMEOUT, "Stat is TIMEOUT");
}
ok($delta < 3, "elapsed time $delta < 3");
