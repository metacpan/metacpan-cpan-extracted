#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

my $t = Test::Statsd->new({
  binary => $ENV{STATSD_BINARY} || qq{$^X $Bin/../../bin/statsd},
  config => $ENV{STATSD_CONFIG} || qq{$Bin/../config/testConfig.js},
});

$t->start_statsd();
$t->send_udp(localhost=>40001, "a_bad_test_value|z");
# Will wait until it receives the graphite flush
my $stats = $t->wait_and_collect_flush_data();
$t->stop_statsd();

ok($stats, "Should receive some data");

$stats = $t->hashify($stats);
ok(exists $stats->{"stats.statsd.numStats"},
  "Got back 'stats.statsd.numStats'");

is($stats->{"stats.statsd.numStats"} => 2,
  "There should only be two stats, since we sent a bad message");

is($stats->{"stats.counters.statsd.bad_lines_seen.count"} => 1,
  "Backend recognised our bad message bumping 'bad_lines_seen'");

done_testing;
