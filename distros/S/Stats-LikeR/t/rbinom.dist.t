#!/usr/bin/env perl
#
# rbinom(): the variates are binomial, and a variate costs the same whatever
# `size` is.
#
# Up to 0.315 generate_binomial() was the textbook Bernoulli loop -- `size`
# draws from Drand01() per variate, counting successes.  Exact, and O(size):
# rbinom(n => 10, size => 1e9) asks it for ten billion uniforms and never
# returns, and rbinom(n => 1e4, size => 1e5) for a billion.  0.316 replaces it
# with BTPE (Kachitvichyanukul and Schmeiser 1988, CACM 31, 216-222), taken
# from R 4.6.1 src/nmath/rbinom.c, whose cost does not grow with size at all.
#
# THE SEEDED STREAM MOVED.  BTPE consumes a different number of uniforms per
# variate than the Bernoulli loop did, so a given srand() produces different
# numbers from those 0.315 gave.  The distribution is the same and a run is
# still reproducible; this file tests both of those and deliberately pins no
# individual variate, because pinning one would pin the algorithm rather than
# the distribution.
#
# Provenance:
#
#   * The null distribution every goodness-of-fit test below is run against is
#     this module's own pbinom(), which t/binom_test.R.scipy.t and
#     t/distributions.R.scipy.t cross-validate against R 4.6.1 and SciPy.  A
#     generator cannot be checked against a table of numbers -- it is checked
#     against the distribution it claims to draw from, and that distribution is
#     the one already pinned to the references.
#   * The cases are the ones that exercise the algorithm's branches: n*p below
#     30 (the inverse-CDF walk), n*p above it (the triangle / parallelogram /
#     exponential-tail rejection), p above and below 0.5 (the reflection), and
#     size 0 and 1 and p exactly 0 and 1 (the short circuits).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Time::HiRes qw(time);
use Stats::LikeR qw(rbinom pbinom pchisq mean var);

# Seeded: every check below compares a sample statistic against its population
# value, and an unconditional tolerance on an unseeded draw fails at some rate
# however wide it is -- the same reasoning t/01.t records for rnorm/runif.
srand 20260911;

my $N = 60_000;     # variates per case

# Pearson chi-square goodness of fit against the exact binomial CDF.  The
# support is cut at ~12 quantiles of the true distribution so that no cell is
# thin; cells with an expected count of 5 or fewer are pooled out, which is the
# usual rule and is what keeps the statistic chi-square under H0.
sub gof_p {
	my ($x, $size, $p) = @_;
	my (@cut, $prev) = (-1);
	$prev = -1;
	for my $qq (map { $_ / 12 } 1 .. 11) {
		my ($a, $b) = (0, $size);
		while ($a < $b) {                       # smallest k with pbinom(k) >= qq
			my $m = int(($a + $b) / 2);
			if (pbinom($m, $size, $p) < $qq) { $a = $m + 1 } else { $b = $m }
		}
		if ($a > $prev) { push @cut, $a; $prev = $a }
	}
	push @cut, $size;
	my (@obs, @exp);
	for my $j (0 .. $#cut - 1) {
		my $lo = $cut[$j] < 0 ? 0 : pbinom($cut[$j], $size, $p);
		push @exp, (pbinom($cut[$j + 1], $size, $p) - $lo) * scalar(@$x);
		push @obs, 0;
	}
	for my $v (@$x) {
		for my $j (0 .. $#cut - 1) {
			if ($v > $cut[$j] && $v <= $cut[$j + 1]) { $obs[$j]++; last }
		}
	}
	my ($chi, $df) = (0, -1);
	for my $j (0 .. $#exp) {
		next unless $exp[$j] > 5;
		$chi += ($obs[$j] - $exp[$j]) ** 2 / $exp[$j];
		$df++;
	}
	return $df > 0 ? pchisq($chi, $df, lower => 0) : undef;
}

# size, prob, and which branch of the algorithm it lands in
my @CASES = (
	[ 10,      0.5,   'inverse-CDF, symmetric'       ],
	[ 10,      0.05,  'inverse-CDF, small p'         ],
	[ 10,      0.95,  'inverse-CDF, reflected'       ],
	[ 100,     0.3,   'BTPE'                         ],
	[ 100,     0.5,   'BTPE, symmetric'              ],
	[ 100,     0.01,  'inverse-CDF (np = 1)'         ],
	[ 100,     0.99,  'inverse-CDF, reflected'       ],
	[ 1000,    0.5,   'BTPE'                         ],
	[ 1000,    0.02,  'BTPE, np = 20 -> inverse-CDF' ],
	[ 5000,    0.4,   'BTPE'                         ],
	[ 100_000, 0.5,   'BTPE, large n'                ],
	[ 1_000_000, 0.001, 'inverse-CDF at a huge size' ],
	[ 1_000_000, 0.999, 'reflected at a huge size'   ],
);

for my $c (@CASES) {
	my ($size, $p, $what) = @$c;
	my $x = rbinom(n => $N, size => $size, prob => $p);
	is(scalar @$x, $N, "size=$size p=$p: $N variates returned");

	# a goodness-of-fit p below 1e-4 on a fixed seed is a broken generator,
	# not bad luck: under H0 it happens once in ten thousand runs, and the
	# seed does not change between runs
	my $gp = gof_p($x, $size, $p);
	ok(!defined $gp || $gp > 1e-4,
	   sprintf 'size=%s p=%s (%s): chi-square GOF p = %.4f', $size, $p, $what,
	           defined $gp ? $gp : 1);

	# first two moments, against 6 standard errors of the sample mean -- a
	# two-sided 2e-9 event under H0
	my $sd_mean = sqrt($size * $p * (1 - $p) / $N);
	cmp_ok(abs(mean($x) - $size * $p), '<', 6 * $sd_mean,
	       "size=$size p=$p: sample mean is within 6 SE of n*p");
	# the sample variance of n*p*(1-p) has relative SE ~ sqrt(2/N); 8% is far
	# outside that at N = 60000 (sqrt(2/60000) = 0.6%) and inside anything a
	# wrong distribution would produce
	cmp_ok(abs(var($x) / ($size * $p * (1 - $p)) - 1), '<', 0.08,
	       "size=$size p=$p: sample variance is within 8% of n*p*(1-p)");

	# and nothing outside the support
	my ($lo, $hi) = ($size, 0);
	for my $v (@$x) { $lo = $v if $v < $lo; $hi = $v if $v > $hi }
	cmp_ok($lo, '>=', 0,     "size=$size p=$p: no variate below 0");
	cmp_ok($hi, '<=', $size, "size=$size p=$p: no variate above size");
}

# ------------------------------------------------------ the short circuits
{
	is_deeply(rbinom(n => 4, size => 0,  prob => 0.5), [0, 0, 0, 0], 'size = 0 is all 0');
	is_deeply(rbinom(n => 4, size => 7,  prob => 0),   [0, 0, 0, 0], 'prob = 0 is all 0');
	is_deeply(rbinom(n => 4, size => 7,  prob => 1),   [7, 7, 7, 7], 'prob = 1 is all size');
	my $b = rbinom(n => 2000, size => 1, prob => 0.25);
	is(scalar(grep { $_ != 0 && $_ != 1 } @$b), 0, 'size = 1 gives only 0 and 1');
	cmp_ok(abs(mean($b) - 0.25), '<', 6 * sqrt(0.25 * 0.75 / 2000),
	       'size = 1 is a Bernoulli(0.25)');
	is_deeply(rbinom(n => 0, size => 5, prob => 0.5), [], 'n = 0 returns nothing');
}

# Not exercised here, and cannot be: `binom_draw()` keeps the old Bernoulli
# loop for a `size` past IV_MAX, which BTPE's index type cannot carry.  On a
# 64-bit-IV perl that is unreachable -- `sv_count_arg()` refuses anything above
# 2^48 and IV_MAX is 2^63 -- and on the one 32-bit-IV build in the matrix
# (5.44.0-i686, ivsize 4) reaching it means a size between 2^31 and 2^32, i.e.
# two billion Bernoulli trials for a single variate.  A test that took half a
# minute to draw one number would say nothing the sizes above do not.

# ------------------------------------------------------------ reproducible
#
# srand() still governs the stream, which is the contract; WHICH numbers it
# gives is the algorithm's business and is deliberately not pinned here.
{
	srand 4242; my $a = rbinom(n => 25, size => 250, prob => 0.37);
	srand 4242; my $b = rbinom(n => 25, size => 250, prob => 0.37);
	is_deeply($a, $b, 'the same seed gives the same variates');
	srand 4243; my $c = rbinom(n => 25, size => 250, prob => 0.37);
	isnt(join(',', @$a), join(',', @$c), 'a different seed gives different variates');
}

# ---------------------------------------------------- the reflection is exact
#
# BTPE draws for min(p, 1-p) and returns n - ix when p > 0.5, so the two must
# be the same stream mirrored.  This is also what makes the p > 0.5 cases above
# test the same code the p < 0.5 ones do.
#
# 3/4 and 1/4, and not the 0.68 and 0.32 this used to ask for, because the
# identity is only exact when `1.0 - prob_hi` is bit-for-bit `prob_lo` -- that
# is what makes the two setups the same setup.  A dyadic pair is that in every
# NV width; 0.68 and 0.32 are not even in a double, where 1.0 - 0.68 lands one
# ulp below 0.32.  It passed anyway -- 200 seeds x 30 variates, no divergence,
# because an ulp in p is far too small to flip an accept/reject test -- but it
# passed by luck rather than by construction, and the luck is NV-width
# dependent.  np is 100 here, so this is still the BTPE branch the old pair
# exercised.
{
	srand 99; my $hi = rbinom(n => 30, size => 400, prob => 0.75);
	srand 99; my $lo = rbinom(n => 30, size => 400, prob => 0.25);
	is_deeply($hi, [ map { 400 - $_ } @$lo ],
	          'prob and 1-prob mirror each other on the same seed');
}

# ------------------------------------------------------- cost, not distribution
#
# The point of the change.  1000 variates at size = 1e9 is 1e12 Bernoulli
# trials under the old loop -- hours -- and about forty uniforms in total under
# BTPE.  No ratio is asserted, because a smoker's clock is not evidence; the
# bound is absolute and enormous (measured here: 0.0002 s), so it can only fail
# if the cost has gone back to being proportional to `size`.
{
	my $t = time;
	my $x = rbinom(n => 1000, size => 1_000_000_000, prob => 0.5);
	my $el = time - $t;
	is(scalar @$x, 1000, 'a huge size still returns the right count');
	cmp_ok($el, '<', 10, 'a variate does not cost O(size)')
		or diag("1000 variates at size = 1e9 took ${el}s");
	diag(sprintf '1000 variates at size = 1e9: %.4fs', $el);
	cmp_ok(abs(mean($x) / 5e8 - 1), '<', 1e-3,
	       'and they are still centred on n*p');
}

done_testing();
