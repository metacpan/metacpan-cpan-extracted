#!perl

use warnings;
use strict;

use Test::More;
use Test::Differences;

use Prometheus::Tiny;
use Prometheus::Tiny::Shared;
use File::Temp qw(tmpnam);
use Data::Random qw(rand_chars);

plan skip_all => "set PTS_STRESS_TEST=1 to run stress tests"
  unless $ENV{PTS_STRESS_TEST};

my @values = map {
  scalar rand_chars(set => 'alphanumeric', size => 10);
} (1..10_000);

for my $max (
  100,
  500,
  1_000,
  5_000,
  10_000,
  50_000,
  100_000,
  500_000,
  1_000_000,
  5_000_000,
  10_000_000,
) {
  my $p = Prometheus::Tiny->new;

  my $ps = Prometheus::Tiny::Shared->new(
    share_file => scalar tmpnam(),
  );

  my @metrics = map {
    my $metric = "metric_$_";
    $p->declare($metric, help => "some metric $_", type => 'counter');
    $ps->declare($metric, help => "some metric $_", type => 'counter');
    $metric;
  } (1..100);

  for (1..$max) {
    my $metric = $metrics[int(rand(scalar @metrics))];
    my $value  = $values[int(rand(scalar @values))];
    $p->inc($metric, { some_label => $value });
    $ps->inc($metric, { some_label => $value });
    #diag "done $_/$max iterations" if $_ % 10000 == 0;
  }

  eq_or_diff($p->format, $ps->format,
             "in-memory and cached metrics match ($max iterations)")
    or die "not running further tests\n";
}

done_testing;
