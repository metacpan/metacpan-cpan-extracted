#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

plan tests => 5;

my $t = Test::Statsd->new({
  binary => $ENV{STATSD_BINARY} || qq{$^X $Bin/../../bin/statsd},
  config => $ENV{STATSD_CONFIG} || qq{$Bin/../config/testConfig.js},
});

$t->start_statsd();

my $test_value = 100;
$t->send_udp(localhost=>40001, "a_test_value:${test_value}|ms");

# Will wait until it receives the graphite flush
my $stats = $t->wait_and_collect_flush_data();
ok($stats, "Should receive some data");

diag($stats);

$t->stop_statsd();
$stats = $t->hashify($stats);

is($stats->{"stats.statsd.numStats"} => 3,
  "Got the one metric that was fired");

ok($stats->{"stats.timers.a_test_value.mean_90"} == $test_value,
  "stats.timers.a_test_value.mean_90 should be ${test_value}");

ok($stats->{"stats.timers.a_test_value.count"} == 1.0,
  "stats.timers.a_test_value.count is 1 since we got one value");

ok($stats->{"stats.timers.a_test_value.count_ps"} == 1.0,
  "stats.timers.a_test_value.count_ps is 1 since we got one value per second");
