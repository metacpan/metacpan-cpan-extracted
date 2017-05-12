#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

plan tests => 8;

my $t = Test::Statsd->new({
  binary => $ENV{STATSD_BINARY} || qq{$^X $Bin/../../bin/statsd},
  config => $ENV{STATSD_CONFIG} || qq{$Bin/../config/percentThreshold.js},
});

$t->start_statsd();

my @timer_values;
for (1..100) {
    push @timer_values, int rand(2000) + 1000;
}

my $mean = 0;
my $t0 = time();

for my $timer_value (@timer_values) {
  $t->send_udp(localhost=>40001, sprintf("read_latency:%.2f|ms", $timer_value));
  $mean += $timer_value;
}

my $elapsed = time() - $t0;
$elapsed = 1 if $elapsed < 1;
my $values_per_second = @timer_values / $elapsed;

$mean /= @timer_values;
diag("Expected mean value is $mean");

# Will wait until it receives the graphite flush
my $stats = $t->wait_and_collect_flush_data();
ok($stats, "Should receive some data");

diag($stats);

$t->stop_statsd();
$stats = $t->hashify($stats);

is($stats->{"stats.statsd.numStats"} => 3,
  "Got the one metric that was fired");

ok(! exists $stats->{"stats.timers.read_latency.mean_90"},
  "default percentThreshold of 90 is not there. Config is honoured correctly");

my $rl = "stats.timers.read_latency";
ok($stats->{"$rl.mean_95"} >= 1000,
  "$rl.mean_95 value was calculated (" . $stats->{"$rl.mean_95"} . ")");

ok($stats->{"$rl.mean_98"} >= $stats->{"${rl}.mean_95"},
  "$rl.mean_98 must be greater than mean_95 (" . $stats->{"$rl.mean_98"} . ")");

ok($stats->{"$rl.mean_99"} >= $stats->{"${rl}.mean_98"},
  "$rl.mean_99 must be greater than mean_98 (" . $stats->{"$rl.mean_99"} . ")");

ok($stats->{"$rl.count"} == @timer_values,
  "$rl.count corresponds to number of timer values");

ok($stats->{"$rl.count_ps"} == $values_per_second,
  "$rl.count_ps is correct as "
  . scalar(@timer_values) . " were sent during ${elapsed} seconds");
