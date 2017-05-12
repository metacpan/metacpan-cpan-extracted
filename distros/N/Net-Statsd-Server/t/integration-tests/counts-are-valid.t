#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

plan tests => 4;

my $t = Test::Statsd->new({
  binary => $ENV{STATSD_BINARY} || qq{$^X $Bin/../../bin/statsd},
  config => $ENV{STATSD_CONFIG} || qq{$Bin/../config/testConfig.js},
});

$t->start_statsd();

my $test_value = 100;
$t->send_udp(localhost=>40001, "a_test_value:${test_value}|c");

# Will wait until it receives the graphite flush
my $stats = $t->wait_and_collect_flush_data();
ok($stats, "Should receive some data");

diag($stats);

$t->stop_statsd();
$stats = $t->hashify($stats);

is($stats->{"stats.statsd.numStats"} => 3,
  "Got the one metric that was fired");

my $flush_interval = 1000; # ms
my $expected_rate = ($test_value / ($flush_interval / 1000));

ok($stats->{"stats.counters.a_test_value.rate"} == $expected_rate,
  "Rate of counter is calculated according to flushInterval");

ok($stats->{"stats.counters.a_test_value.count"} == $test_value,
  "Counter cumulative value should be the sum of all values sent");
