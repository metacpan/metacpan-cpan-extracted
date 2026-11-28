use strict;
use warnings;
use Test::More;
use Statistics::CaseResampling ':all';

# Deterministic RNGs: one for generating synthetic samples, one for bootstrapping
my $sample_rng = Statistics::CaseResampling::RdGen::setup(987654);

sub rand_normal {
  my $u1 = $sample_rng->genrand();
  $u1 = 1e-12 if $u1 <= 0;
  my $u2 = $sample_rng->genrand();
  return sqrt(-2.0 * log($u1)) * cos(6.283185307179586 * $u2);
}

sub rand_exp1 {
  my $u = $sample_rng->genrand();
  $u = 1.0 - 1e-12 if $u >= 1.0;
  return -log(1.0 - $u);
}

my $trials = 200;
my $n      = 30;
my $runs   = 300;
my $conf   = 0.95;

local $Statistics::CaseResampling::Rnd
  = Statistics::CaseResampling::RdGen::setup(20261127);

# 1. Empirical 95% coverage on standard normal N(0, 1)
{
  my %hits = (
    median_exact       => 0,
    median_percentile  => 0,
    mean_simple        => 0,
    mean_percentile    => 0,
    mean_bca           => 0,
    mean_studentized   => 0,
  );

  for (1 .. $trials) {
    my @s = map { rand_normal() } (1 .. $n);

    my ($l_me, undef, $u_me) = median_exact_confidence_limits(\@s, $conf);
    $hits{median_exact}++ if $l_me <= 0 && 0 <= $u_me;

    my ($l_mp, undef, $u_mp) = median_percentile_confidence_limits(\@s, $conf, $runs);
    $hits{median_percentile}++ if $l_mp <= 0 && 0 <= $u_mp;

    my ($l_ms, undef, $u_ms) = simple_confidence_limits_from_samples(
      mean(\@s), resample_means(\@s, $runs), $conf
    );
    $hits{mean_simple}++ if $l_ms <= 0 && 0 <= $u_ms;

    my ($l_p, undef, $u_p) = mean_percentile_confidence_limits(\@s, $conf, $runs);
    $hits{mean_percentile}++ if $l_p <= 0 && 0 <= $u_p;

    my ($l_b, undef, $u_b) = mean_bca_confidence_limits(\@s, $conf, $runs);
    $hits{mean_bca}++ if $l_b <= 0 && 0 <= $u_b;

    my ($l_t, undef, $u_t) = mean_studentized_confidence_limits(\@s, $conf, $runs);
    $hits{mean_studentized}++ if $l_t <= 0 && 0 <= $u_t;
  }

  for my $k (sort keys %hits) {
    my $cov = $hits{$k} / $trials;
    cmp_ok($cov, '>=', 0.87, "N(0,1) 95% coverage for $k >= 0.87 (got $cov)");
    cmp_ok($cov, '<=', 1.00, "N(0,1) 95% coverage for $k <= 1.00 (got $cov)");
  }
}

# 2. Empirical 95% coverage and positivity on right-skewed Exponential(1)
{
  my $true_mean   = 1.0;
  my $true_median = log(2.0);
  my %hits = (
    median_exact     => 0,
    mean_bca         => 0,
    mean_studentized => 0,
  );
  my $nonnegative_percentile = 1;
  my $nonnegative_bca        = 1;

  for (1 .. $trials) {
    my @s = map { rand_exp1() } (1 .. $n);

    my ($l_me, undef, $u_me) = median_exact_confidence_limits(\@s, $conf);
    $hits{median_exact}++ if $l_me <= $true_median && $true_median <= $u_me;

    my ($l_p, undef, $u_p) = mean_percentile_confidence_limits(\@s, $conf, $runs);
    $nonnegative_percentile = 0 if $l_p < 0;

    my ($l_b, undef, $u_b) = mean_bca_confidence_limits(\@s, $conf, $runs);
    $hits{mean_bca}++ if $l_b <= $true_mean && $true_mean <= $u_b;
    $nonnegative_bca = 0 if $l_b < 0;

    my ($l_t, undef, $u_t) = mean_studentized_confidence_limits(\@s, $conf, $runs);
    $hits{mean_studentized}++ if $l_t <= $true_mean && $true_mean <= $u_t;
  }

  for my $k (sort keys %hits) {
    my $cov = $hits{$k} / $trials;
    cmp_ok($cov, '>=', 0.87, "Exp(1) 95% coverage for $k >= 0.87 (got $cov)");
    cmp_ok($cov, '<=', 1.00, "Exp(1) 95% coverage for $k <= 1.00 (got $cov)");
  }
  ok($nonnegative_percentile, 'Exp(1) mean_percentile_confidence_limits lower bound never negative');
  ok($nonnegative_bca, 'Exp(1) mean_bca_confidence_limits lower bound never negative');
}

done_testing();
