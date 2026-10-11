use strict;
use warnings;
use Test::More;
use Statistics::CaseResampling ':all';

# SCR-01: Empty array handling without wild pointer deallocation / crashes
{
  my $r = resample([]);
  is_deeply($r, [], 'resample([]) returns empty array without crash');

  my $rm = resample_medians([], 10);
  is_deeply($rm, [], 'resample_medians([], 10) returns empty array without crash');

  my $rme = resample_means([], 10);
  is_deeply($rme, [], 'resample_means([], 10) returns empty array without crash');

  is(median([]), 0, 'median([]) returns 0 without crash');
  is(median_absolute_deviation([]), 0, 'median_absolute_deviation([]) returns 0 without crash');
  is(first_quartile([]), 0, 'first_quartile([]) returns 0 without crash');
  is(third_quartile([]), 0, 'third_quartile([]) returns 0 without crash');

  my ($l, $med, $u) = median_simple_confidence_limits([], 0.95);
  is($l, 0, 'median_simple_confidence_limits([]) lower is 0');
  is($med, 0, 'median_simple_confidence_limits([]) median is 0');
  is($u, 0, 'median_simple_confidence_limits([]) upper is 0');

  my ($l2, $st, $u2) = simple_confidence_limits_from_samples(0, [], 0.95);
  is($l2, 0, 'simple_confidence_limits_from_samples([]) lower is 0');
  is($st, 0, 'simple_confidence_limits_from_samples([]) stat is 0');
  is($u2, 0, 'simple_confidence_limits_from_samples([]) upper is 0');
}

# SCR-02: ithreads use-after-free and double-free protection
{
  use Config;
  SKIP: {
    skip 'This Perl does not support ithreads', 4 unless $Config{useithreads};
    require threads;

    my $t = threads->create(sub {
      my $sample = [1..10];
      my $res = resample($sample);
      return scalar(@$res);
    });
    my $res = $t->join();
    is($res, 10, 'thread executed resample successfully');

    my $main_res = resample([1..10]);
    is(scalar(@$main_res), 10, 'main thread executed resample after thread join without double-free');

    # Also test an explicit generator object under threads
    my $gen = Statistics::CaseResampling::RdGen::setup(12345);
    my $t2 = threads->create(sub {
      return 1;
    });
    $t2->join();
    ok(1, 'thread with explicit generator joined without double-free');
    my $val = $gen->genrand();
    ok($val >= 0 && $val < 1, 'explicit generator still valid in parent thread');
  }
}

# SCR-03: Quartile calculations for small arrays without out-of-bounds reads
{
  # n = 1
  is(first_quartile([10]), 10, 'first_quartile([10]) == 10');
  is(third_quartile([10]), 10, 'third_quartile([10]) == 10');
  is(median([10]), 10, 'median([10]) == 10');

  # n = 2
  is(first_quartile([10, 20]), 10, 'first_quartile([10, 20]) == 10');
  is(third_quartile([10, 20]), 20, 'third_quartile([10, 20]) == 20 (not OOB heap garbage)');
  is(median([10, 20]), 10, 'median([10, 20]) == 10');

  # n = 3
  is(first_quartile([10, 20, 30]), 10, 'first_quartile([10, 20, 30]) == 10');
  is(third_quartile([10, 20, 30]), 30, 'third_quartile([10, 20, 30]) == 30');
  is(median([10, 20, 30]), 20, 'median([10, 20, 30]) == 20');

  # n = 4
  is(first_quartile([10, 20, 30, 40]), 20, 'first_quartile([10, 20, 30, 40]) == 20');
  is(third_quartile([10, 20, 30, 40]), 40, 'third_quartile([10, 20, 30, 40]) == 40');
  is(median([10, 20, 30, 40]), 20, 'median([10, 20, 30, 40]) == 20');
}

# SCR-04: Confidence limits bounds clamping on extreme confidence levels
{
  # High confidence
  my ($l1, $m1, $u1) = median_simple_confidence_limits([1..50], 0.9999, 10);
  ok(defined $l1 && defined $m1 && defined $u1, 'median_simple_confidence_limits with 0.9999 conf returned values');

  my ($l2, $m2, $u2) = simple_confidence_limits_from_samples(5, [1..5], 0.9999);
  ok(defined $l2 && defined $m2 && defined $u2, 'simple_confidence_limits_from_samples with 0.9999 conf returned values');

  # Low confidence
  my ($l3, $m3, $u3) = median_simple_confidence_limits([1..50], 0.0001, 10);
  ok(defined $l3 && defined $m3 && defined $u3, 'median_simple_confidence_limits with 0.0001 conf returned values');

  my ($l4, $m4, $u4) = simple_confidence_limits_from_samples(5, [1..5], 0.0001);
  ok(defined $l4 && defined $m4 && defined $u4, 'simple_confidence_limits_from_samples with 0.0001 conf returned values');
}

# SCR-05: Validation of resample run counts
{
  eval { resample_medians([1..5], 0) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'resample_medians rejects runs = 0');

  eval { resample_medians([1..5], -1) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'resample_medians rejects runs = -1');

  eval { resample_means([1..5], 0) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'resample_means rejects runs = 0');

  eval { resample_means([1..5], -1) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'resample_means rejects runs = -1');

  eval { median_simple_confidence_limits([1..5], 0.95, 0) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'median_simple_confidence_limits rejects runs = 0');

  eval { median_simple_confidence_limits([1..5], 0.95, -1) };
  like($@, qr/Number of resample runs must be between 1 and 100000000/, 'median_simple_confidence_limits rejects runs = -1');
}

# SCR-06: select_kth error handling
{
  eval { select_kth([1..5], 0) };
  like($@, qr/Can't select 0th smallest element/, 'select_kth rejects kth = 0');

  eval { select_kth([1..5], 6) };
  like($@, qr/Can't select 6th smallest element/, 'select_kth rejects kth > nelem');

  eval { select_kth([], 1) };
  like($@, qr/Can't select 1th smallest element/, 'select_kth rejects kth on empty array');
}

# SCR-07: Standard deviation edge case guards & mean
{
  eval { sample_standard_deviation(10, []) };
  like($@, qr/Sample standard deviation requires at least 2 data points/, 'sample_standard_deviation rejects empty array');

  eval { sample_standard_deviation(10, [10]) };
  like($@, qr/Sample standard deviation requires at least 2 data points/, 'sample_standard_deviation rejects single-element array');

  eval { population_standard_deviation(10, []) };
  like($@, qr/Population standard deviation requires at least 1 data point/, 'population_standard_deviation rejects empty array');

  is(population_standard_deviation(10, [10]), 0, 'population_standard_deviation([10]) == 0');
  is(mean([]), 0, 'mean([]) == 0 without division by zero');
}

# SCR-08: median_absolute_deviation allocator safety
{
  is(median_absolute_deviation([5]), 0, 'MAD of single element is 0');
  is(median_absolute_deviation([1, 2, 3, 4, 5]), 1, 'MAD of [1..5] is 1');
}

# SCR-09: RdGen setup_array and buffer handling
{
  my $rnd = Statistics::CaseResampling::RdGen::setup_array(1, 2, 3, 4, 5);
  ok(defined $rnd, 'setup_array creates RdGen object');
  my $val = $rnd->genrand();
  ok($val >= 0 && $val < 1, 'genrand produces random number in [0, 1)');
}

done_testing();
