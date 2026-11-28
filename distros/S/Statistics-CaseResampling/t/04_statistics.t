use strict;
use warnings;
use Config;
use Test::More;
use Statistics::CaseResampling ':all';

my $nan = 9**9**9 - 9**9**9;
my $inf = 9**9**9;

sub is_nan {
  my ($x) = @_;
  return defined($x) && $x != $x;
}

sub is_close {
  my ($got, $exp, $tol, $name) = @_;
  $tol = 1e-12 unless defined $tol;
  my $diff = abs($got - $exp);
  my $scale = abs($exp) > 1 ? abs($exp) : 1;
  ok($diff <= $tol * $scale, "$name (got=$got, exp=$exp)");
}

# 1. Default PRNG seeding across separate subprocesses
{
  my @blib = map { "-I$_" } grep { -d $_ } ('blib/lib', 'blib/arch');
  my $run_sub = sub {
    my @cmd = ($^X, @blib, '-MStatistics::CaseResampling=resample',
               '-e', 'print join(q{,}, @{resample([1..100])})');
    if ($^O eq 'MSWin32' && $] < 5.022) {
      my $qcmd = join(' ', map { qq{"$_"} } @cmd);
      return `$qcmd`;
    }
    open my $fh, '-|', @cmd or die "spawn $^X: $!";
    local $/;
    my $out = <$fh>;
    close $fh;
    return defined($out) ? $out : '';
  };
  my $out1 = $run_sub->();
  my $out2 = $run_sub->();
  ok(length($out1) > 0 && length($out2) > 0, 'subprocess resamples produced output');
  isnt($out1, $out2, 'default RNG produces distinct sequences across processes');
}

# 1b. OS entropy, fallback seeding, $! preservation, and high-bit setup_array
{
  $! = 2; # ENOENT-style sentinel value
  my $saved_errno = $! + 0;
  my @e1 = Statistics::CaseResampling::RdGen::_os_entropy(4);
  is($! + 0, $saved_errno, '_os_entropy preserves $!');
  my @e2 = Statistics::CaseResampling::RdGen::_os_entropy(4);
  if (@e1) {
    is(scalar(@e1), 4, '_os_entropy(4) returns 4 words');
    ok(join(',', @e1) ne join(',', @e2), 'successive _os_entropy(4) calls differ');
    ok(!grep({ $_ < 0 || $_ > 4294967295 || $_ != int($_) } @e1), '_os_entropy words are valid U32 integers');
  }
  else {
    pass('_os_entropy gracefully returns empty when unavailable (3 skipped)');
    pass('fallback handled');
    pass('fallback handled');
  }

  $! = $saved_errno;
  my $rng = Statistics::CaseResampling::_new_default_rng();
  is($! + 0, $saved_errno, '_new_default_rng preserves $!');
  ok(defined $rng, '_new_default_rng returns valid RdGen');

  my @fb1 = Statistics::CaseResampling::_fallback_seed();
  my @fb2 = Statistics::CaseResampling::_fallback_seed();
  is(scalar(@fb1), 6, '_fallback_seed returns 6 seed words');
  ok(!grep({ $_ < 0 || $_ > 4294967295 || $_ != int($_) } @fb1), '_fallback_seed words are valid U32 integers');
  isnt(join(',', @fb1), join(',', @fb2), 'consecutive _fallback_seed calls differ');

  my $fb_rng = Statistics::CaseResampling::RdGen::setup_array(@fb1);
  ok($fb_rng->genrand() >= 0 && $fb_rng->genrand() < 1, '_fallback_seed initializes RdGen cleanly');

  my $hi_rng = Statistics::CaseResampling::RdGen::setup_array(0xffffffff, 0x80000001, 0, 12345);
  my $hi_val = $hi_rng->genrand();
  ok($hi_val >= 0 && $hi_val < 1, 'setup_array handles unsigned 32-bit high-bit seeds');
}

# 2. Thread independence under ithreads
{
  SKIP: {
    skip 'This Perl does not support ithreads', 2 unless $Config{useithreads};
    require threads;

    my $t1 = threads->create(sub { return join(',', @{resample([1..100])}); });
    my $t2 = threads->create(sub { return join(',', @{resample([1..100])}); });
    my $r1 = $t1->join();
    my $r2 = $t2->join();
    ok(length($r1) > 0 && length($r2) > 0, 'threaded resamples produced output');
    isnt($r1, $r2, 'separate ithreads produce independent resamples');
  }
}

# 3. Fork safety for auto-seeded RNG vs deterministic explicit seed
{
  SKIP: {
    skip 'fork not reliable on MSWin32', 2 if $^O eq 'MSWin32';

    # Draw once in parent before fork to advance state
    my $pre = resample([1..100]);
    ok(scalar(@$pre) == 100, 'pre-fork resample succeeded');

    pipe(my $rfh, my $wfh) or die "pipe: $!";
    my $pid = fork();
    if (!defined $pid) {
      skip "fork failed: $!", 1;
    }
    elsif ($pid == 0) {
      close $rfh;
      print {$wfh} join(',', @{resample([1..100])}), "\n";
      close $wfh;
      CORE::exit(0);
    }
    else {
      close $wfh;
      my $child_res = <$rfh>;
      close $rfh;
      waitpid($pid, 0);
      chomp($child_res) if defined $child_res;
      my $parent_res = join(',', @{resample([1..100])});
      isnt($child_res, $parent_res, 'forked child auto-reseeds default RNG');
    }
  }

  # Explicit seed remains deterministic
  {
    local $Statistics::CaseResampling::Rnd
      = Statistics::CaseResampling::RdGen::setup(123456);
    my $a = resample([1..50]);
    $Statistics::CaseResampling::Rnd
      = Statistics::CaseResampling::RdGen::setup(123456);
    my $b = resample([1..50]);
    is_deeply($a, $b, 'explicitly seeded RNG remains deterministic');
  }
}

# 4. Unbiased resampling uniformity on non-power-of-2 size (n = 7)
{
  local $Statistics::CaseResampling::Rnd
    = Statistics::CaseResampling::RdGen::setup(42);
  my @counts = (0) x 7;
  my $sample = [0..6];
  for (1..7000) {
    my $r = resample($sample);
    $counts[$_]++ for @$r;
  }
  # Expected = 7000 per bucket, SD = sqrt(49000 * 1/7 * 6/7) ~= 77.46
  my $all_ok = 1;
  for my $c (@counts) {
    $all_ok = 0 if $c < 6500 || $c > 7500;
  }
  ok($all_ok, "unbiased resampling counts on n=7 within expected range (@counts)");
}

# 5. High-precision erf, erfinv, nsigma_to_alpha, alpha_to_nsigma
{
  is_close(approx_erf(0.5), 0.5204998778130465, 1e-13, 'approx_erf(0.5)');
  is_close(approx_erf(1e-8), 1.1283791670955126e-8, 1e-12, 'approx_erf(1e-8) avoids cancellation');
  is_close(approx_erf_inv(approx_erf(1e-8)), 1e-8, 1e-12, 'approx_erf_inv roundtrip near 0');
  is_close(approx_erf_inv(0.9999), 2.7510639057120566, 1e-12, 'approx_erf_inv(0.9999)');

  # Normal tail accuracy at 1..10 sigma
  is_close(nsigma_to_alpha(1.959963984540054), 0.05, 1e-12, 'nsigma_to_alpha(1.96) == 0.05');
  is_close(nsigma_to_alpha(3.0), 0.0026997960632601866, 1e-12, 'nsigma_to_alpha(3)');
  is_close(nsigma_to_alpha(5.0), 5.733031437583865e-7, 1e-12, 'nsigma_to_alpha(5)');
  is_close(nsigma_to_alpha(8.0), 1.2441921148543547e-15, 1e-11, 'nsigma_to_alpha(8)');
  cmp_ok(nsigma_to_alpha(10.0), '>', 0, 'nsigma_to_alpha(10) does not underflow to 0');
  is_close(nsigma_to_alpha(10.0), 1.523970604832105e-23, 1e-11, 'nsigma_to_alpha(10)');

  # Inverse tail accuracy including extreme alpha
  is_close(alpha_to_nsigma(0.05), 1.959963984540054, 1e-12, 'alpha_to_nsigma(0.05)');
  is_close(alpha_to_nsigma(1e-12), 7.1305068481713256, 1e-12, 'alpha_to_nsigma(1e-12)');
  is_close(alpha_to_nsigma(1e-50), 14.979477571624336, 1e-12, 'alpha_to_nsigma(1e-50)');
  is_close(nsigma_to_alpha(alpha_to_nsigma(1e-20)), 1e-20, 1e-11, 'roundtrip at alpha=1e-20');

  # Domain checks & boundary symmetry
  is_close(approx_erf_inv(0.0), 0.0, 1e-14, 'approx_erf_inv(0) == 0');
  is_close(approx_erf_inv(-0.5), -approx_erf_inv(0.5), 1e-14, 'approx_erf_inv odd symmetry');
  is_close(nsigma_to_alpha(0.0), 1.0, 1e-14, 'nsigma_to_alpha(0) == 1');
  is_close(alpha_to_nsigma(1.0), 0.0, 1e-14, 'alpha_to_nsigma(1) == 0');

  for my $bad_alpha (0, -0.1, 1.1, $nan) {
    eval { alpha_to_nsigma($bad_alpha) };
    ok($@, "alpha_to_nsigma rejects invalid alpha ($bad_alpha)");
  }
  for my $bad_nsigma (-0.1, $nan) {
    eval { nsigma_to_alpha($bad_nsigma) };
    ok($@, "nsigma_to_alpha rejects invalid nsigma ($bad_nsigma)");
  }
}

# 6. Deterministic NaN propagation and NaN domain validation
{
  my @perms = (
    [$nan, 1, 2, 3, 4],
    [1, $nan, 2, 3, 4],
    [1, 2, $nan, 3, 4],
    [1, 2, 3, $nan, 4],
    [1, 2, 3, 4, $nan],
    [4, 3, 2, 1, $nan],
  );
  my $nan_ok = 1;
  for my $p (@perms) {
    $nan_ok = 0 unless is_nan(median($p));
    $nan_ok = 0 unless is_nan(first_quartile($p));
    $nan_ok = 0 unless is_nan(third_quartile($p));
    $nan_ok = 0 unless is_nan(select_kth($p, 3));
    $nan_ok = 0 unless is_nan(quantile($p, 0.5));
    $nan_ok = 0 unless is_nan(median_absolute_deviation($p));
    my ($l, $m, $u) = median_exact_confidence_limits($p, 0.95);
    $nan_ok = 0 unless is_nan($l) && is_nan($m) && is_nan($u);
  }
  ok($nan_ok, 'NaN propagates deterministically across all input permutations');

  eval { approx_erf_inv($nan) };
  ok($@, 'approx_erf_inv rejects NaN');
  eval { quantile([1..5], $nan) };
  ok($@, 'quantile rejects NaN probability');
  eval { median_simple_confidence_limits([1..5], $nan) };
  ok($@, 'median_simple_confidence_limits rejects NaN confidence');
  eval { simple_confidence_limits_from_samples(3, [1..5], $nan) };
  ok($@, 'simple_confidence_limits_from_samples rejects NaN confidence');
  eval { basic_confidence_limits_from_samples(3, [1..5], $nan) };
  ok($@, 'basic_confidence_limits_from_samples rejects NaN confidence');
  eval { percentile_confidence_limits_from_samples(3, [1..5], $nan) };
  ok($@, 'percentile_confidence_limits_from_samples rejects NaN confidence');
  eval { bca_confidence_limits_from_samples(3, [1..5], [1..5], $nan) };
  ok($@, 'bca_confidence_limits_from_samples rejects NaN confidence');
  eval { median_percentile_confidence_limits([1..5], $nan) };
  ok($@, 'median_percentile_confidence_limits rejects NaN confidence');
  eval { median_exact_confidence_limits([1..5], $nan) };
  ok($@, 'median_exact_confidence_limits rejects NaN confidence');
}

# 7. Numerical stability: mean and standard deviations
{
  # Compensated mean avoids catastrophic cancellation
  my @cancel = (1e16, (1) x 1000, -1e16);
  is_close(mean(\@cancel), 1000 / 1002, 1e-12, 'Neumaier compensated mean avoids cancellation');
  my @cancel_big = (1e20, (1) x 1000, -1e20);
  is_close(mean(\@cancel_big), 1000 / 1002, 1e-12, 'Neumaier compensated mean avoids cancellation above 64-bit significand');
  my (undef, $m_bca, undef) = mean_bca_confidence_limits(\@cancel, 0.95, 20);
  is_close($m_bca, 1000 / 1002, 1e-12, 'cs_mean avoids cancellation in mean_bca_confidence_limits');

  # Overflow-safe mean for huge finite values
  is_close(mean([1e308, 1e308]), 1e308, 1e-14, 'mean([1e308, 1e308]) does not overflow to Inf');
  is_close(mean([-1e308, 1e308]), 0.0, 1e-14, 'mean([-1e308, 1e308]) is 0');

  # 1-arg and 2-arg standard deviations
  my $s = [2, 4, 4, 4, 5, 5, 7, 9];
  is_close(population_standard_deviation($s), 2.0, 1e-12, '1-arg population_standard_deviation');
  is_close(sample_standard_deviation($s), sqrt(32 / 7), 1e-12, '1-arg sample_standard_deviation');
  is_close(sample_standard_deviation(5.0, $s), sqrt(32 / 7), 1e-12, '2-arg sample_standard_deviation matches 1-arg');

  # Scaling avoids overflow and underflow
  my $huge = [1e200, 2e200, 3e200];
  is_close(sample_standard_deviation($huge), 1e200, 1e-12, 'sample_standard_deviation scales at 1e200 without overflow');
  my $tiny = [1e-200, 2e-200, 3e-200];
  is_close(sample_standard_deviation($tiny), 1e-200, 1e-12, 'sample_standard_deviation scales at 1e-200 without underflow');

  # Constant and Inf/NaN cases
  is(sample_standard_deviation([7, 7, 7]), 0, 'constant sample has 0 sample SD');
  is(population_standard_deviation([7]), 0, 'single-element population SD is 0');
  ok(is_nan(sample_standard_deviation([1, 2, $nan])), 'sample SD propagates NaN');
  ok(is_nan(sample_standard_deviation([1, 2, $inf])), '1-arg sample SD with +Inf returns NaN (Inf - Inf mean)');
  is(sample_standard_deviation(0, [1, 2, $inf]), $inf, '2-arg sample SD with finite mean and +Inf returns +Inf');

  eval { sample_standard_deviation(1, 2, [1, 2]) };
  ok($@, 'sample_standard_deviation rejects 3 args');
  eval { sample_standard_deviation('not_an_array') };
  ok($@, 'sample_standard_deviation rejects non-arrayref');
  eval { population_standard_deviation([]) };
  ok($@, '1-arg population_standard_deviation rejects empty array');
  eval { sample_standard_deviation([1]) };
  ok($@, '1-arg sample_standard_deviation rejects single-element array');

  # Reject undef and non-numeric values while accepting numeric strings and NaN/Inf
  for my $bad (undef, 'NA', '', '12abc', {}) {
    my $label = defined($bad) ? (ref($bad) || "'$bad'") : 'undef';
    eval { mean([1, $bad, 3]) };
    ok($@, "mean rejects $label");
    eval { median([1, $bad, 3]) };
    ok($@, "median rejects $label");
    eval { quantile([1, $bad, 3], 0.5) };
    ok($@, "quantile rejects $label");
    eval { resample([1, $bad, 3]) };
    ok($@, "resample rejects $label");
    eval { sample_standard_deviation([1, $bad, 3]) };
    ok($@, "sample_standard_deviation rejects $label");
    eval { population_standard_deviation([1, $bad, 3]) };
    ok($@, "population_standard_deviation rejects $label");
  }
  eval { sample_standard_deviation('NA', [1, 2, 3]) };
  ok($@, '2-arg sample_standard_deviation rejects non-numeric mean');
  eval { population_standard_deviation(undef, [1, 2, 3]) };
  ok($@, '2-arg population_standard_deviation rejects undef mean');

  is_close(mean(['-3.5', '1.5', ' 2.0 ']), 0.0, 1e-14, 'mean accepts numeric strings');
  is_close(median(['10', '2', '6']), 6.0, 1e-14, 'median accepts numeric strings');
  ok(is_nan(mean([$nan, 1, 2])), 'mean accepts and propagates NaN');
  is(mean([$inf, 1, 2]), $inf, 'mean accepts and propagates Inf');
}

# 8. quantile() Type 7 tests
{
  is_close(quantile([1, 2, 3, 4], 0.0), 1.0, 1e-14, 'quantile p=0');
  is_close(quantile([1, 2, 3, 4], 0.25), 1.75, 1e-14, 'quantile p=0.25 (n=4)');
  is_close(quantile([1, 2, 3, 4], 0.5), 2.5, 1e-14, 'quantile p=0.5 (even-n exact median)');
  is_close(quantile([1, 2, 3, 4], 0.75), 3.25, 1e-14, 'quantile p=0.75 (n=4)');
  is_close(quantile([1, 2, 3, 4], 1.0), 4.0, 1e-14, 'quantile p=1');
  is_close(quantile([40, 10, 30, 20, 50], 0.5), 30.0, 1e-14, 'quantile p=0.5 (unsorted odd)');
  is_close(quantile([42], 0.25), 42.0, 1e-14, 'quantile single element');

  # Reflection symmetry Q_p(-X) == -Q_{1-p}(X)
  my $x = [3.5, 1.2, 8.9, 2.4, 5.1, 7.7, 0.3, 6.6];
  my $neg_x = [map { -$_ } @$x];
  for my $p (0.1, 0.25, 0.5, 0.75, 0.9) {
    is_close(quantile($neg_x, $p), -quantile($x, 1.0 - $p), 1e-13, "quantile reflection symmetry p=$p");
  }

  eval { quantile([], 0.5) };
  ok($@, 'quantile rejects empty array');
  eval { quantile([1..5], -0.01) };
  ok($@, 'quantile rejects p < 0');
  eval { quantile([1..5], 1.01) };
  ok($@, 'quantile rejects p > 1');

  # Exact even-n median, MAD, and quartile symmetry
  is_close(median([0, 10]), 5.0, 1e-14, 'median([0, 10]) == 5');
  is_close(median_absolute_deviation([0, 10]), 5.0, 1e-14, 'MAD([0, 10]) == 5 (was 0 before)');
  is_close(median_absolute_deviation([1, 2, 3, 4]), 1.0, 1e-14, 'MAD([1, 2, 3, 4]) == 1');
  for my $arr ([1..7], [1..8], [3.5, 1.2, 8.9, 2.4, 5.1, 7.7]) {
    my $neg = [map { -$_ } @$arr];
    is_close(median($neg), -median($arr), 1e-13, 'median(-X) == -median(X) for n=' . scalar(@$arr));
    is_close(first_quartile($neg), -third_quartile($arr), 1e-13, 'Q1(-X) == -Q3(X) for n=' . scalar(@$arr));
  }
}

# 9. Two-sided percentile, basic, and BCa confidence limits from samples
{
  my $boot = [0..100]; # n=101 -> quantile(p) == 100*p exactly

  my ($pl, $ps, $pu) = percentile_confidence_limits_from_samples(50, $boot, 0.90);
  is_close($pl, 5.0, 1e-12, 'percentile 90% CI lower == 5');
  is($ps, 50, 'percentile 90% CI stat == 50');
  is_close($pu, 95.0, 1e-12, 'percentile 90% CI upper == 95');

  my ($pl95, $ps95, $pu95) = percentile_confidence_limits_from_samples(50, $boot, 0.95);
  is_close($pl95, 2.5, 1e-12, 'percentile 95% CI lower == 2.5');
  is_close($pu95, 97.5, 1e-12, 'percentile 95% CI upper == 97.5');

  # Low confidence (< 0.5) must NOT invert bounds
  my ($pl20, $ps20, $pu20) = percentile_confidence_limits_from_samples(50, $boot, 0.20);
  cmp_ok($pl20, '<=', $pu20, 'percentile 20% CI not inverted');
  is_close($pl20, 40.0, 1e-12, 'percentile 20% CI lower == 40');
  is_close($pu20, 60.0, 1e-12, 'percentile 20% CI upper == 60');

  # Basic bootstrap on asymmetric boot around stat=40
  my ($bl, $bs, $bu) = basic_confidence_limits_from_samples(40, $boot, 0.90);
  is_close($bl, 2*40 - 95.0, 1e-12, 'basic 90% CI lower == 2*stat - q_0.95');
  is($bs, 40, 'basic 90% CI stat == 40');
  is_close($bu, 2*40 - 5.0, 1e-12, 'basic 90% CI upper == 2*stat - q_0.05');

  my ($bl20, $bs20, $bu20) = basic_confidence_limits_from_samples(40, $boot, 0.20);
  cmp_ok($bl20, '<=', $bu20, 'basic 20% CI not inverted');

  # simple_confidence_limits_from_samples now uses two-sided alpha/2 + Type 7 interpolation
  my ($sl, $ss, $su) = simple_confidence_limits_from_samples(40, $boot, 0.90);
  is_close($sl, $bl, 1e-12, 'simple_confidence_limits_from_samples 90% CI lower matches basic');
  is($ss, 40, 'simple_confidence_limits_from_samples stat == 40');
  is_close($su, $bu, 1e-12, 'simple_confidence_limits_from_samples 90% CI upper matches basic');

  my ($sl20, $ss20, $su20) = simple_confidence_limits_from_samples(40, $boot, 0.20);
  cmp_ok($sl20, '<=', $su20, 'simple_confidence_limits_from_samples 20% CI not inverted');

  my ($msl, $msm, $msu) = median_simple_confidence_limits([1..21], 0.20, 200);
  cmp_ok($msl, '<=', $msu, 'median_simple_confidence_limits 20% CI not inverted');
  my ($msl0, $msm0, $msu0) = median_simple_confidence_limits([1..21], 0.0001, 200);
  cmp_ok($msl0, '<=', $msu0, 'median_simple_confidence_limits 0.0001 CI not inverted');

  # BCa: with unbiased symmetric boot (50% < stat) and symmetric jackknife (a=0),
  # BCa must match percentile CI
  my ($bcal, $bcas, $bcau) = bca_confidence_limits_from_samples(50, $boot, [49, 50, 51], 0.90);
  is_close($bcal, $pl, 1e-9, 'BCa matches percentile lower when z0=0, a=0');
  is($bcas, 50, 'BCa stat == 50');
  is_close($bcau, $pu, 1e-9, 'BCa matches percentile upper when z0=0, a=0');

  # BCa: skewed jackknife & biased boot shifts endpoints compared to percentile
  my ($bcal_s, undef, $bcau_s) = bca_confidence_limits_from_samples(60, $boot, [10, 50, 52, 53, 55], 0.90);
  cmp_ok($bcal_s, '>', $pl, 'BCa shifts lower bound upward under upward bias/skew');
  cmp_ok($bcau_s, '>', $pu, 'BCa shifts upper bound upward under upward bias/skew');
  cmp_ok($bcal_s, '<=', $bcau_s, 'BCa shifted bounds remain ordered');

  # BCa edge cases: zero-variance jackknife & constant bootstrap
  my ($bcal_z, undef, $bcau_z) = bca_confidence_limits_from_samples(50, $boot, [50, 50, 50], 0.90);
  is_close($bcal_z, $pl, 1e-9, 'BCa handles zero-variance jackknife cleanly');
  is_close($bcau_z, $pu, 1e-9, 'BCa handles zero-variance jackknife upper cleanly');

  my ($bcal_c, undef, $bcau_c) = bca_confidence_limits_from_samples(5, [5, 5, 5, 5], [5, 5, 5], 0.95);
  is($bcal_c, 5, 'BCa handles constant bootstrap lower');
  is($bcau_c, 5, 'BCa handles constant bootstrap upper');

  eval { percentile_confidence_limits_from_samples(0, [], 0.95) };
  ok($@, 'percentile_confidence_limits_from_samples rejects empty array');
  eval { basic_confidence_limits_from_samples(0, [], 0.95) };
  ok($@, 'basic_confidence_limits_from_samples rejects empty array');
  eval { bca_confidence_limits_from_samples(0, [], [1], 0.95) };
  ok($@, 'bca_confidence_limits_from_samples rejects empty boot');
  eval { bca_confidence_limits_from_samples(0, [1], [], 0.95) };
  ok($@, 'bca_confidence_limits_from_samples rejects empty jackknife');
}

# 10. median_exact_confidence_limits & median_percentile_confidence_limits
{
  # n = 1
  my ($l1, $m1, $u1) = median_exact_confidence_limits([7], 0.95);
  is($l1, 7, 'exact median CI n=1 lower');
  is($m1, 7, 'exact median CI n=1 median');
  is($u1, 7, 'exact median CI n=1 upper');

  # n = 2, conf = 0.5 -> P(X_(1) <= med <= X_(2)) = 2/4 = 0.5
  my ($l2, $m2, $u2) = median_exact_confidence_limits([20, 10], 0.5);
  is($l2, 10, 'exact median CI n=2 lower');
  is($m2, 15, 'exact median CI n=2 exact median');
  is($u2, 20, 'exact median CI n=2 upper');

  # n = 6, conf = 0.95 -> k=1 (1..6, cov=62/64=0.96875)
  my ($l6, $m6, $u6) = median_exact_confidence_limits([6, 4, 1, 5, 2, 3], 0.95);
  is($l6, 1, 'exact median CI n=6 conf=0.95 lower == 1');
  is_close($m6, 3.5, 1e-14, 'exact median CI n=6 median == 3.5');
  is($u6, 6, 'exact median CI n=6 conf=0.95 upper == 6');

  # n = 9, conf = 0.95 -> k=2 (2..8, cov=492/512=0.9609375)
  my ($l9, $m9, $u9) = median_exact_confidence_limits([9, 3, 7, 1, 5, 8, 2, 6, 4], 0.95);
  is($l9, 2, 'exact median CI n=9 conf=0.95 lower == 2');
  is($m9, 5, 'exact median CI n=9 median == 5');
  is($u9, 8, 'exact median CI n=9 conf=0.95 upper == 8');

  # n = 9, conf = 0.80 -> k=3 (3..7, cov=420/512=0.8203125)
  my ($l9_80, $m9_80, $u9_80) = median_exact_confidence_limits([1..9], 0.80);
  is($l9_80, 3, 'exact median CI n=9 conf=0.80 lower == 3');
  is($m9_80, 5, 'exact median CI n=9 conf=0.80 median == 5');
  is($u9_80, 7, 'exact median CI n=9 conf=0.80 upper == 7');

  # n = 20, conf = 0.95 -> k=6 (6..15, cov=1 - 2*sum_{j=0..5} C(20,j)/2^20 = 0.9586...)
  my ($l20, $m20, $u20) = median_exact_confidence_limits([reverse 1..20], 0.95);
  is($l20, 6, 'exact median CI n=20 conf=0.95 lower == 6');
  is_close($m20, 10.5, 1e-14, 'exact median CI n=20 median == 10.5');
  is($u20, 15, 'exact median CI n=20 conf=0.95 upper == 15');

  # median_percentile_confidence_limits
  my ($mpl, $mpm, $mpu) = median_percentile_confidence_limits([1..20], 0.95, 2000);
  is_close($mpm, 10.5, 1e-14, 'median_percentile_confidence_limits uses exact even-n median');
  cmp_ok($mpl, '<=', $mpm, 'median_percentile_confidence_limits lower <= median');
  cmp_ok($mpm, '<=', $mpu, 'median_percentile_confidence_limits median <= upper');
  cmp_ok($mpl, '>=', 1, 'median_percentile_confidence_limits lower in sample range');
  cmp_ok($mpu, '<=', 20, 'median_percentile_confidence_limits upper in sample range');

  eval { median_exact_confidence_limits([], 0.95) };
  ok($@, 'median_exact_confidence_limits rejects empty sample');
  eval { median_percentile_confidence_limits([], 0.95) };
  ok($@, 'median_percentile_confidence_limits rejects empty sample');
  eval { median_percentile_confidence_limits([1..10], 0.95, 0) };
  ok($@, 'median_percentile_confidence_limits rejects runs = 0');
}

# 11. Adversarial selection patterns (introselect worst-case hardening)
{
  my $n = 2000;
  my @sorted    = (1..$n);
  my @reversed  = reverse @sorted;
  my @all_equal = (42) x $n;
  my @organpipe = (1..1000, reverse 1..1000);
  my @sawtooth  = map { ($_ % 2 == 0) ? $_ / 2 : $n - $_ } (0..$n-1);

  is_close(median(\@sorted), 1000.5, 1e-14, 'introselect median on sorted n=2000');
  is_close(median(\@reversed), 1000.5, 1e-14, 'introselect median on reversed n=2000');
  is_close(median(\@all_equal), 42.0, 1e-14, 'introselect median on all-equal n=2000');
  is_close(median(\@organpipe), 500.5, 1e-14, 'introselect median on organ-pipe n=2000');
  is(select_kth(\@organpipe, 1), 1, 'introselect min on organ-pipe n=2000');
  is(select_kth(\@organpipe, $n), 1000, 'introselect max on organ-pipe n=2000');
  is_close(quantile(\@sawtooth, 0.37), (sort { $a <=> $b } @sawtooth)[int(0.37*($n-1))] + (0.37*($n-1) - int(0.37*($n-1))) * ((sort { $a <=> $b } @sawtooth)[int(0.37*($n-1))+1] - (sort { $a <=> $b } @sawtooth)[int(0.37*($n-1))]), 1e-12, 'introselect quantile on sawtooth n=2000');
}

# 12. resample_quantiles and C-accelerated mean CI functions
{
  my $sample = [1, 2, 4, 7, 11, 16, 22, 29, 37, 46];
  my $expected_mean = mean($sample);

  # resample_quantiles
  is_deeply(resample_quantiles([], 0.25, 10), [], 'resample_quantiles([]) returns []');
  my $rq = resample_quantiles($sample, 0.25, 50);
  is(scalar(@$rq), 50, 'resample_quantiles returns requested count');
  ok(!grep({ $_ < 1 || $_ > 46 } @$rq), 'resample_quantiles values within sample range');

  eval { resample_quantiles($sample, -0.1, 10) };
  ok($@, 'resample_quantiles rejects p < 0');
  eval { resample_quantiles($sample, 1.1, 10) };
  ok($@, 'resample_quantiles rejects p > 1');
  eval { resample_quantiles($sample, $nan, 10) };
  ok($@, 'resample_quantiles rejects NaN p');
  eval { resample_quantiles($sample, 0.5, 0) };
  ok($@, 'resample_quantiles rejects runs = 0');

  # Deterministic check comparing mean_percentile_confidence_limits to manual resample_means
  {
    local $Statistics::CaseResampling::Rnd = Statistics::CaseResampling::RdGen::setup(777);
    my ($l_fast, $m_fast, $u_fast) = mean_percentile_confidence_limits($sample, 0.90, 500);
    $Statistics::CaseResampling::Rnd = Statistics::CaseResampling::RdGen::setup(777);
    my $means = resample_means($sample, 500);
    my ($l_ref, $m_ref, $u_ref) = percentile_confidence_limits_from_samples(mean($sample), $means, 0.90);
    is_close($l_fast, $l_ref, 1e-14, 'mean_percentile_confidence_limits lower matches manual');
    is_close($m_fast, $m_ref, 1e-14, 'mean_percentile_confidence_limits mean matches manual');
    is_close($u_fast, $u_ref, 1e-14, 'mean_percentile_confidence_limits upper matches manual');
  }

  for my $fn (\&mean_percentile_confidence_limits, \&mean_bca_confidence_limits, \&mean_studentized_confidence_limits) {
    my ($l, $m, $u) = $fn->($sample, 0.95, 400);
    is_close($m, $expected_mean, 1e-12, 'mean CI returns exact sample mean');
    cmp_ok($l, '<=', $m, 'mean CI lower <= mean');
    cmp_ok($m, '<=', $u, 'mean CI mean <= upper');
    cmp_ok($l, '>=', 1, 'mean CI lower >= min');
    cmp_ok($u, '<=', 46, 'mean CI upper <= max') unless $fn == \&mean_studentized_confidence_limits;

    # Constant sample collapses interval to constant value
    my ($lc, $mc, $uc) = $fn->([5, 5, 5, 5], 0.95, 50);
    is($lc, 5, 'constant sample mean CI lower == 5');
    is($mc, 5, 'constant sample mean CI mean == 5');
    is($uc, 5, 'constant sample mean CI upper == 5');

    # NaN propagation & error guards
    my ($ln, $mn, $un) = $fn->([1, $nan, 3], 0.95, 20);
    ok(is_nan($ln) && is_nan($mn) && is_nan($un), 'mean CI propagates NaN');
    eval { $fn->([], 0.95) };
    ok($@, 'mean CI rejects empty sample');
    eval { $fn->($sample, $nan) };
    ok($@, 'mean CI rejects NaN confidence');
    eval { $fn->($sample, 0.95, 0) };
    ok($@, 'mean CI rejects runs = 0');
  }

  # n = 1 edge cases
  my ($lb1, $mb1, $ub1) = mean_bca_confidence_limits([9], 0.95, 20);
  is($lb1, 9, 'mean_bca_confidence_limits n=1 lower == 9');
  is($mb1, 9, 'mean_bca_confidence_limits n=1 mean == 9');
  is($ub1, 9, 'mean_bca_confidence_limits n=1 upper == 9');

  eval { mean_studentized_confidence_limits([9], 0.95, 20) };
  ok($@, 'mean_studentized_confidence_limits requires n >= 2');

  my ($ls2, $ms2, $us2) = mean_studentized_confidence_limits([1, 3], 0.90, 200);
  is_close($ms2, 2.0, 1e-14, 'mean_studentized_confidence_limits works for n=2');
  cmp_ok($ls2, '<=', $us2, 'mean_studentized_confidence_limits n=2 ordered');
}

# 13. Scalar undef / non-numeric validation and BCa error-path cleanup
{
  my $sample = [1..10];
  for my $bad (undef, 'abc', '') {
    my $label = defined($bad) ? "'$bad'" : 'undef';
    eval { quantile($sample, $bad) };
    ok($@, "quantile rejects scalar p=$label");
    eval { select_kth($sample, $bad) };
    ok($@, "select_kth rejects scalar kth=$label");
    eval { resample_medians($sample, $bad) };
    ok($@, "resample_medians rejects runs=$label");
    eval { resample_means($sample, $bad) };
    ok($@, "resample_means rejects runs=$label");
    eval { resample_quantiles($sample, $bad, 10) };
    ok($@, "resample_quantiles rejects p=$label");
    eval { resample_quantiles($sample, 0.5, $bad) };
    ok($@, "resample_quantiles rejects runs=$label");
    eval { simple_confidence_limits_from_samples($bad, $sample, 0.95) };
    ok($@, "simple_confidence_limits_from_samples rejects stat=$label");
    eval { simple_confidence_limits_from_samples(5, $sample, $bad) };
    ok($@, "simple_confidence_limits_from_samples rejects conf=$label");
    eval { basic_confidence_limits_from_samples($bad, $sample, 0.95) };
    ok($@, "basic_confidence_limits_from_samples rejects stat=$label");
    eval { basic_confidence_limits_from_samples(5, $sample, $bad) };
    ok($@, "basic_confidence_limits_from_samples rejects conf=$label");
    eval { percentile_confidence_limits_from_samples($bad, $sample, 0.95) };
    ok($@, "percentile_confidence_limits_from_samples rejects stat=$label");
    eval { percentile_confidence_limits_from_samples(5, $sample, $bad) };
    ok($@, "percentile_confidence_limits_from_samples rejects conf=$label");
    eval { bca_confidence_limits_from_samples($bad, $sample, $sample, 0.95) };
    ok($@, "bca_confidence_limits_from_samples rejects stat=$label");
    eval { bca_confidence_limits_from_samples(5, $sample, $sample, $bad) };
    ok($@, "bca_confidence_limits_from_samples rejects conf=$label");
    eval { median_simple_confidence_limits($sample, $bad) };
    ok($@, "median_simple_confidence_limits rejects conf=$label");
    eval { median_simple_confidence_limits($sample, 0.95, $bad) };
    ok($@, "median_simple_confidence_limits rejects runs=$label");
    eval { median_percentile_confidence_limits($sample, $bad) };
    ok($@, "median_percentile_confidence_limits rejects conf=$label");
    eval { median_percentile_confidence_limits($sample, 0.95, $bad) };
    ok($@, "median_percentile_confidence_limits rejects runs=$label");
    eval { median_exact_confidence_limits($sample, $bad) };
    ok($@, "median_exact_confidence_limits rejects conf=$label");
    eval { mean_percentile_confidence_limits($sample, $bad) };
    ok($@, "mean_percentile_confidence_limits rejects conf=$label");
    eval { mean_percentile_confidence_limits($sample, 0.95, $bad) };
    ok($@, "mean_percentile_confidence_limits rejects runs=$label");
    eval { mean_bca_confidence_limits($sample, $bad) };
    ok($@, "mean_bca_confidence_limits rejects conf=$label");
    eval { mean_bca_confidence_limits($sample, 0.95, $bad) };
    ok($@, "mean_bca_confidence_limits rejects runs=$label");
    eval { mean_studentized_confidence_limits($sample, $bad) };
    ok($@, "mean_studentized_confidence_limits rejects conf=$label");
    eval { mean_studentized_confidence_limits($sample, 0.95, $bad) };
    ok($@, "mean_studentized_confidence_limits rejects runs=$label");
    eval { approx_erf($bad) };
    ok($@, "approx_erf rejects x=$label");
    eval { approx_erf_inv($bad) };
    ok($@, "approx_erf_inv rejects x=$label");
    eval { alpha_to_nsigma($bad) };
    ok($@, "alpha_to_nsigma rejects alpha=$label");
    eval { nsigma_to_alpha($bad) };
    ok($@, "nsigma_to_alpha rejects nsigma=$label");
  }

  eval { bca_confidence_limits_from_samples(5, $sample, [1, 'bad', 3], 0.95) };
  like($@, qr/Non-numeric value in sample/, 'bca_confidence_limits_from_samples rejects invalid jackknife cleanly');
}

done_testing();
