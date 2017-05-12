#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
use Test::Statsd;
use Test::More;

plan tests => 4;

my $t = Test::Statsd->new({
  binary => defined $ENV{STATSD_BINARY}
          ? $ENV{STATSD_BINARY}
          : qq{$^X $Bin/../../bin/statsd},
  # Make sure we use the special configuration needed for this test
  config => qq{$Bin/../config/deleteIdleButGauges.js},
});

my $test_value = 100;

# Receive data from the inner "graphite" AnyEvent TCP server
# We keep a number-of-flush state variable to understand
# when it's the first or second. On 2nd we shut down the server
# from the outside through the AnyEvent CondVar ($cv)
#
# We can't use the normal wait_and_collect_flush_data() flow
# because we need to wait for 2 flushes and can't shutdown
# the "fake" graphite daemon after the first flush.

my $flush = 1;

sub read_callback {
  my ($hdl, $cv, $stats) = @_;

  # First flush, gauge value is expected to be there
  if ($flush == 1) {
    diag("First flush. Test gauge should be there.");
    ok($stats, "Should receive some data\n$stats\n--------------------------");
    my $values = $t->hashify($stats);
    ok($values->{"stats.gauges.a_test_gauge"} == $test_value*1.0,
      "Got back the expected gauge value");
  }

  # Second flush, this time without a_test_gauge value, because
  # deleteIdleStats should have cleared it for us.
  elsif ($flush == 2) {
    diag("Second flush. deleteGauges=false should keep the test gauge.");
    ok($stats, "Should receive some data\n$stats\n--------------------------");
    my $values = $t->hashify($stats);
    ok(exists $values->{"stats.gauges.a_test_gauge"},
      "deleteGauges=false overrides deleteIdleStats=true");

    # Shutdown the server now. $cv is the inner AE::condvar
    $cv->send();
    # Destroying the handle will avoid a Broken Pipe sock error
    $hdl->destroy();
  }

  $flush++;
}

$t->start_statsd();
$t->send_udp(localhost=>40001, "a_test_gauge:${test_value}|g");

# Will wait until it receives the graphite flush,
# and run our callback when it does.
my $stats = $t->wait_and_collect_flush_data(undef, \&read_callback);

$t->stop_statsd();
