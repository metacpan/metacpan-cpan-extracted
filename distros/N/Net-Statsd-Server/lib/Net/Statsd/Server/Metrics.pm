# ABSTRACT: Provides metrics abstraction to a running statsd server

package Net::Statsd::Server::Metrics;
$Net::Statsd::Server::Metrics::VERSION = '0.20';
use 5.008;
use strict;
use Carp        ();
use Time::HiRes ();

sub new {
  my ($class, $config) = @_;
  $class = ref $class || $class;
  my $g_pref = $config->{prefixStats};
  if (! $g_pref) {
    Carp::croak("prefixStats is empty or invalid! (Metrics.new)");
  }

  my $self = {
    keyCounter => {},
    counters => {
      "${g_pref}.packets_received" => 0,
      "${g_pref}.bad_lines_seen"   => 0,
    },
    timers => {},
    gauges => {},
    sets => {},
    counter_rates => {},
    timer_data => {},
    pctThreshold => [ 90 ],
  };

  if (exists $config->{percentThreshold}
      && ref $config->{percentThreshold} eq "ARRAY") {
    $self->{pctThreshold} = $config->{percentThreshold};
  }

  bless $self, $class;
}

sub process {
  my ($self, $flush_interval) = @_;

  my $starttime = [Time::HiRes::gettimeofday];
  my $key;

  my $metrics = $self->as_hash;
  my $counters = $metrics->{counters};
  my $timers = $metrics->{timers};
  my $pctThreshold = $metrics->{pctThreshold};

  # Meta metrics added by statsd
  my $counter_rates = {};
  my $timer_data = {};
  my $statsd_metrics = {};

  # Calculate "per second" rate
  $flush_interval /= 1000;

  for my $key (keys %{ $counters }) {
    my $value = $counters->{$key};
    $counter_rates->{$key} = $value / $flush_interval;
  }

  # Calculate all requested
  # percentile values (90%, 95%, ...)
  for my $key (keys %{ $timers }) {

    my $current_timer_data = {};

    if (@{ $timers->{$key} } > 0) {

      # Sort timer samples by value
      my @values = @{ $timers->{$key} };
      @values = sort { $a <=> $b } @values;

      my $count = @values;
      my $min = $values[0];
      my $max = $values[$#values];

      # We don't want to iterate at all if there's just 1 value
      my $cumulativeValues = [ $min ];
      my $cumulSumSquaresValues = [ $min * $min ];

      for (my $i = 1; $i < $count; $i++) {
        my $cmlVal = $values[$i] + $cumulativeValues->[$i - 1];
        push @{ $cumulativeValues }, $values[$i] + $cumulativeValues->[$i - 1];
        push @{ $cumulSumSquaresValues }, ($values[$i] * $values[$i])
          + $cumulSumSquaresValues->[$i - 1];
      }

      my $sum = my $mean = $min;
      my $sumSquares = $min * $min;
      my $maxAtThreshold = $max;

      for my $pct (@{ $pctThreshold }) {

        my $numInThreshold = $count;

        if ($count > 1) {
          # Pay attention to the rounding: should behave the same
          # as etsy's statsd, that's using a Math.round(x).
          # int(x + 0.5) does this.
          $numInThreshold = int(($pct / 100 * $count) + 0.5);
          next if $numInThreshold == 0;

          if ($pct > 0) {
            $maxAtThreshold = $values[$numInThreshold - 1];
            $sum = $cumulativeValues->[$numInThreshold - 1];
            $sumSquares = $cumulSumSquaresValues->[$numInThreshold - 1];
          }
          else {
            $maxAtThreshold = $values[$count - $numInThreshold];
            $sum = $cumulativeValues->[$count - 1] - $cumulativeValues->[$count - $numInThreshold - 1];
            $sumSquares = $cumulSumSquaresValues->[$count - 1] - $cumulSumSquaresValues->[$count - $numInThreshold - 1];
          }
          $mean = $sum / $numInThreshold;
        }

        my $clean_pct = "" . $pct;
        $clean_pct =~ s{\.}{_}g;
        $clean_pct =~ s{-}{top}g;
        $current_timer_data->{"count_${clean_pct}"} = $numInThreshold;
        $current_timer_data->{"mean_${clean_pct}"} = $mean;
        $current_timer_data->{($pct > 0 ? "upper_" : "lower_") . $clean_pct} = $maxAtThreshold;
        $current_timer_data->{"sum_${clean_pct}"} = $sum;
        $current_timer_data->{"sum_squares_${clean_pct}"} = $sumSquares;
      }

      $sum = $cumulativeValues->[$count - 1];
      $sumSquares = $cumulSumSquaresValues->[$count - 1];
      $mean = $sum / $count;

      # Calculate standard deviation
      my $sumOfDiffs = 0;
      for (0 .. $count - 1) {
         $sumOfDiffs += ($values[$_] - $mean) ** 2;
      }
      my $stddev = sqrt($sumOfDiffs / $count);
      my $mid = int($count / 2);
      my $median = $count % 2
        ? $values[$mid]
        : ($values[$mid - 1] + $values[$mid]) / 2;

      $current_timer_data->{std} = $stddev;
      $current_timer_data->{upper} = $max;
      $current_timer_data->{lower} = $min;
      $current_timer_data->{count} = $count;
      $current_timer_data->{count_ps} = $count / $flush_interval;
      $current_timer_data->{sum} = $sum;
      $current_timer_data->{sum_squares} = $sumSquares;
      $current_timer_data->{mean} = $mean;
      $current_timer_data->{median} = $median;

    }
    else {
      $current_timer_data->{count} = 0;
      $current_timer_data->{count_ps} = 0;
    }

    $timer_data->{$key} = $current_timer_data;
  }

  # This is originally ms in statsd
  $statsd_metrics->{processing_time} = Time::HiRes::tv_interval($starttime) * 1000;

  # Add processed metrics to the metrics_hash
  $metrics->{counter_rates}  = $counter_rates;
  $metrics->{timer_data}     = $timer_data;
  $metrics->{statsd_metrics} = $statsd_metrics;

  return $metrics;
}

sub as_hash {
  my $self = $_[0];

  my %metrics = (
    counters => $self->{counters},
    timers   => $self->{timers},
    gauges   => $self->{gauges},
    pctThreshold => $self->{pctThreshold},
  );

  return \%metrics;
}

1;
