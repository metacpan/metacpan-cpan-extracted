#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

plan tests => 2;

my $t = Test::Statsd->new({
  binary => $ENV{STATSD_BINARY} || qq{$^X $Bin/../../bin/statsd},
  config => $ENV{STATSD_CONFIG} || qq{$Bin/../config/testConfig.js},
});

$t->start_statsd();

my $test_value = 100;
my $counter = "a_test_value,category=web,severity=high";
$t->send_udp(localhost=>40001, "${counter}:${test_value}|c");

# Will wait until it receives the graphite flush
my $stats = $t->wait_and_collect_flush_data();
ok($stats, "Should receive some data");

diag($stats);

$t->stop_statsd();
$stats = $t->hashify($stats);

is($stats->{"stats.counters.${counter}.count"} => 100,
  "Counter key name with tags is preserved correctly");
