=head1 NAME

t/process-metrics.t - Net::Statsd::Server test suite

=head1 DESCRIPTION

Tests the statsd server metrics processing.
Checks that counter rates and various timer statistics
are calculated correctly, but more importantly, in the
same way as the javascript statsd.

These test cases have been converted from the original
Etsy's statsd metric processing tests.

=cut

use strict;
use warnings;
use Test::More;

use Net::Statsd::Server::Metrics;

plan tests => 35;

sub setup { #:Setup
  my $m = Net::Statsd::Server::Metrics->new({ prefixStats => 'statsd' });
  return $m;
}

sub counters_have_stats_count { #:Test(1)
  my $metrics = setup();
  $metrics->{counters}->{a} = 2;
  my $processed = $metrics->process(1000);
  is($processed->{counters}->{a}, 2,
    'Counter values are persistent');
}

sub counters_have_correct_rate { #:Test(1)
  my $metrics = setup();
  $metrics->{counters}->{a} = 2;
  my $processed = $metrics->process(100);
  is($processed->{counter_rates}->{a}, 20,
    'Counter rate for 100ms should multiply 10x');
}

sub gauges_are_recorded {
  my $metrics = setup();
  $metrics->{gauges}->{temperature} = 37.5;
  my $processed = $metrics->process(100);
  my $gauges_data = $processed->{gauges};
  is($gauges_data->{temperature}, 37.5,
    'Gauges data is recorded correctly');
}

sub timers_handle_empty {
  my $metrics = setup();
  $metrics->{timers}->{a} = [];
  my $processed = $metrics->process(100);
  # Original comment: "could be handled more cleanly"
  # My comment: why is counter_rates even tested, if
  #             we're dealing with a timer?
  is($processed->{counter_rates}->{a}, undef,
    q(Empty timer shouldn't cause problems));
}

sub timers_single_time {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};
  is($timer_data->{std}, 0,
    'Single timer value should show no variance');
  is($timer_data->{upper}, 100,
    'Upper value must be the only value there is');
  is($timer_data->{lower}, 100,
    'Lower value must be the only value there is');
  is($timer_data->{count}, 1,
    'We have supplied only one value so expect 1 back');
  is($timer_data->{sum}, 100,
    'Sum of one value must be that only value');
  is($timer_data->{mean}, 100,
    'Average of one value is the same value');
}

sub timers_multiple_times {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100, 200, 300];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};
  ok(abs($timer_data->{std} - 81.64965809277261) < 0.00001,
    'Variance is calculated correctly');
  is($timer_data->{upper}, 300,
    'Upper value of those supplied is the max (300)');
  is($timer_data->{lower}, 100,
    'Lower value of those supplied is the min (100)');
  is($timer_data->{count}, 3,
    'We have supplied 3 values, so we expect .count to be 3');
  is($timer_data->{sum}, 600,
    'Sum of the supplied timer data is calculated correctly');
  is($timer_data->{mean}, 200,
    'Mean of the supplied timer data is calculated correctly');
}

sub timers_single_time_single_percentile {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100];
  $metrics->{pctThreshold} = [90];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};
  is($timer_data->{mean_90}, 100,
    '90th percentile mean of 1 timer value is the same value');
  is($timer_data->{upper_90}, 100,
    '90th percentile upper value of 1 timer value is the same value');
  is($timer_data->{sum_90}, 100,
    '90th percentile sum of 1 timer value is the same value');
}

sub timers_single_time_multiple_percentiles {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100];
  $metrics->{pctThreshold} = [80, 90];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};
  is($timer_data->{mean_90}, 100,
    '90th percentile mean of 1 timer value is the same value');
  is($timer_data->{upper_90}, 100,
    '90th percentile upper value of 1 timer value is the same value');
  is($timer_data->{sum_90}, 100,
    '90th percentile sum of 1 timer value is the same value');
  is($timer_data->{mean_80}, 100,
    '80th percentile mean of 1 timer value is the same value');
  is($timer_data->{upper_80}, 100,
    '80th percentile upper value of 1 timer value is the same value');
  is($timer_data->{sum_80}, 100,
    '80th percentile sum of 1 timer value is the same value');
}

sub timers_multiple_times_single_percentiles {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100, 200, 300];
  $metrics->{pctThreshold} = [90];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};
  is($timer_data->{mean_90}, 200,
    '90th percentile mean of multiple timer values is calculated correctly');
  is($timer_data->{upper_90}, 300,
    '90th percentile upper value of multiple timer values is calculated correctly');
  is($timer_data->{sum_90}, 600,
    '90th percentile sum of multiple timer values is calculated correctly');
}

sub timers_multiple_times_multiple_percentiles {
  my $metrics = setup();
  $metrics->{timers}->{a} = [100, 200, 300];
  $metrics->{pctThreshold} = [90, 80];
  my $processed = $metrics->process(100);
  my $timer_data = $processed->{timer_data}->{a};

  # If the *_90 tests fail, there is a regression
  # in how we calculate the 90% threshold element
  # in the array, most probably because of the rounding
  is($timer_data->{mean_90}, 200,
    '90th percentile mean of multiple timer values is calculated correctly');
  is($timer_data->{upper_90}, 300,
    '90th percentile upper value of multiple timer values is calculated correctly');
  is($timer_data->{sum_90}, 600,
    '90th percentile sum of multiple timer values is calculated correctly');

  is($timer_data->{mean_80}, 150,
    '80th percentile mean of multiple timer values is calculated correctly');
  is($timer_data->{upper_80}, 200,
    '80th percentile upper value of multiple timer values is calculated correctly');
  is($timer_data->{sum_80}, 300,
    '80th percentile sum of multiple timer values is calculated correctly');
}

sub statsd_metrics_exist {
  my $metrics = setup();
  my $processed = $metrics->process(100);
  ok(defined $processed->{statsd_metrics}->{processing_time},
    '"statsd_metrics.processing_time" is always added to the metrics');
}

counters_have_stats_count();
counters_have_correct_rate();
gauges_are_recorded();
timers_handle_empty();
timers_single_time();
timers_multiple_times();
timers_single_time_single_percentile();
timers_single_time_multiple_percentiles();
timers_multiple_times_single_percentiles();
timers_multiple_times_multiple_percentiles();
statsd_metrics_exist();

# END
