=head1 NAME

t/graphite.t - Net::Statsd::Server test suite

=head1 DESCRIPTION

Test the integration of statsd with Graphite.

=cut

use strict;
use warnings;
use Data::Dumper;
use Test::More;

use Net::Statsd::Server::Metrics;
use Net::Statsd::Server::Backend::Graphite;

plan tests => 2;

# Helper functions {{{

sub setup {
  my $config = shift || {};
  my $startup_time = time();
  my $graphite = Net::Statsd::Server::Backend::Graphite->new(
    $startup_time, $config
  );
  return $graphite;
}

sub process_metrics {
  my ($config, $metrics) = @_;
  my $m = Net::Statsd::Server::Metrics->new($config);
  if (exists $metrics->{counters}) {
    for (keys %{ $metrics->{counters} }) {
      $m->{counters}->{$_} = $metrics->{counters}->{$_};
    }
  }
  my $proc = $m->process(1000);
  return $proc;
}

sub flush_stats {
  my $test_case = shift;
  my $time = time();
  my $config = {
    graphite => { legacyNamespace => 0 },
    prefixStats => 'statsd',
  };
  my $g = setup($config);
  my $metrics = process_metrics($config, $test_case);
  my $stats = $g->flush_stats($time, $metrics);
  #diag($g->stats_to_string($stats));
  return $stats;
}

# }}}

# Test cases {{{

sub connect_and_get_empty_metrics {
  my $stats = flush_stats({});
  my $numStats;
  for (@{ $stats }) {
    if ($_->{stat} eq "stats.statsd.numStats") {
      $numStats = $_;
      last;
    }
  }
  ok($numStats,
    'statsd.numStats metric is present');
  is($numStats->{value}, 2,
    'Two statsd metrics should be output');
}

# }}}

connect_and_get_empty_metrics();
