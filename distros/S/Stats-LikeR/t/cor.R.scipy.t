#!/usr/bin/env perl
#
# Cross-validation of cor() against the two reference implementations, using
# their own test suites and man-page examples rather than cases invented here.
# t/cor.t keeps the hand-written Kendall underflow regression; this file does
# not repeat it.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) stats::cor() at its default use = "everything",
#     which is the only mode cor() has.  t/cor.R.scipy.R, committed next to
#     this file, generated every literal in the "BEGIN GENERATED (R)" block at
#     options(digits = 17); re-run it with `Rscript t/cor.R.scipy.R` from the
#     distribution root and paste its output over that block.  Its cases are:
#       - tests/reg-tests-1a.R: cor(zz, zz) <= 1 ("fails in R <= 1.3.x"), the
#         Spearman case below "Spearman correlations ranked missing values at
#         end <= 1.8.1", cor(longley) under every method ("cor(mat, use =
#         "pair") was plainly wrong"), and PR#7116;
#       - tests/reg-tests-1b.R "more corner cases for cor()";
#       - tests/reg-tests-2.R PR 883 (cor(x, NULL)), the "corner cases for
#         cor" block X <- cbind(NA, 1:3, rnorm(3)), and PR#14488 ("missing
#         values in rank correlations");
#       - src/library/stats/man/cor.Rd: cor(1:10, 2:11), cor(longley) under
#         all three methods, the "How much do they differ?" correlation of the
#         three lower triangles, and the swiss/swM missing-value examples.
#         The seven-figure values that example prints are themselves pinned in
#         tests/Examples/stats-Ex.Rout.save, and section 3 asserts those too.
#     R's complete.obs and pairwise.complete.obs answers are reproduced by
#     handing cor() exactly the rows those modes keep.
#   * SciPy 1.18.1 scipy/stats/tests (NumPy 2.4.6): test_stats.py
#     TestPearsonrWilkinson, TestPearsonr, TestCorrSpearmanr,
#     TestCorrSpearmanr2 and TestKendallTau; test_correlation.py
#     TestSpearmanRho; test_mstats_basic.py TestCorr.  Their inputs are in the
#     generated tables (so R's full-precision answer is asserted for each) and
#     their own literals are reproduced verbatim in section 4, at the
#     tolerance of the upstream assertion that pins them.  Upstream marks the
#     origin of several: "Reference values result from R: cor.test(x, y,
#     method="kendall", exact=1)" (test_kendalltau_no_ties), "Cross-check with
#     R" (test_spearmanr_vs_r, test_kendalltau_ties), "Expected values
#     computed with R 3.6.2 cor.test" (test_basic_example), "Test against R
#     cor.test" (TestSpearmanRho), "computed using mpmath with 80 digits of
#     precision" (the very-small/very-large pearsonr cases) and "Example
#     values found from Kendall (1970)" (test_kendalltau_ties).
#   * t/cor.R.scipy.py generated the "BEGIN GENERATED (Python)" block with
#     repr(): SciPy's 500-pair normal sample (test_normal_draws /
#     test_large_arrays, RandomState(7546)) and SciPy's statistics for it and
#     for the 200000-pair wh200k sample of section 6.  Re-run it with
#     `python3 t/cor.R.scipy.py`.
#
# Data.  Tie structure decides every rank statistic, so it must not move with
# the NV width.  Every input here is either an integer, a dyadic fraction, or a
# decimal literal that perl and R both parse from the same text; two equal
# literals are equal and two different ones different at every width, so the
# ties are the same on double, long-double and __float128 perls.  Nothing is
# computed in floating point before it reaches cor().  perl-5.10.1's own
# string-to-double reads 215 of the 8223 numbers in the generated tables one
# ulp away from the double R wrote; comparing every vector and column in
# sorted order on 5.10.1 and 5.44.0 showed the same order and the same ties,
# so that moves Pearson by ulps and the rank methods not at all.
#
# Where the references and cor() differ by design, the difference is asserted
# in section 9 rather than left as a comment, so that changing one is a
# decision.  One difference was not by design: on a double perl, Pearson
# over- or underflowed on SciPy's very-large and very-small inputs where R and
# SciPy do not.  Writing this file found it; 0.3217 fixed it, and section 4b
# pins the fix.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use POSIX ();
use Stats::LikeR 'cor';

our (%DATA, @VEC, @MAT, %SWM_PAIRWISE, $LONGLEY_PSK, @REG2_CORNER_X, %R_WH200K);
our (%PY_DRAWS, %PY);

# Tolerances.  All are absolute: a correlation lies in [-1, 1], and a relative
# test near r = 0 (wh200k's r is 2e-4) compares rounding noise in the
# numerator rather than the answer.
#
# $TOL is the limit against R (and against SciPy's repr() in sections 5 and
# 6).  On this build (perl 5.44.0, double NV) the worst disagreement over all
# 86 vector cases, 17 matrices, the pairwise rebuild and the large samples,
# under all three methods, is 3.3e-16: swiss Pearson [2][1], and the
# complete-case Pearson of section 7's regression vector.  Two-pass Pearson
# about the mean against R's two-pass about a refined long-double mean differ
# there in the last bit.  The rank methods' worst is 2.2e-16, and that is R's
# own shortfall: at a perfect correlation R returns 0.99999999999999978 where
# cor() returns 1, because ranks and pair counts are exact integers or halves
# and only the closing sqrt and divide round.  Running pearson_corr()'s
# arithmetic over the vector corpus in numpy.longdouble, on inputs parsed from
# the same decimal text (which is what a long-double perl does), also gave a
# worst of 3.3e-16 against R.  1e-13 leaves more than two orders of headroom
# over both.
#
# $TOL_PIN is half a unit in the seventh decimal: what R's seven-figure
# printout in tests/Examples/stats-Ex.Rout.save can resolve.
my $TOL     = 1e-13;
my $TOL_PIN = 5e-8;

sub is_nan { my $v = shift; return defined($v) && !ref($v) && $v != $v }

# One correlation against R: undef in the table means R's NA, which cor()
# reports as NaN.
sub cmp_r {
	my ($got, $exp, $name, $tol) = @_;
	$tol //= $TOL;
	if (!defined $exp) {
		ok(is_nan($got), "$name is NaN (R: NA)") or diag('got ' . (defined $got ? $got : 'undef'));
		return;
	}
	my $ok = defined($got) && !ref($got) && !is_nan($got) && abs($got - $exp) <= $tol;
	ok($ok, $name) or diag(sprintf('got %s expected %.17g diff %s tol %g',
		(defined $got ? $got : 'undef'), $exp,
		(defined $got && !ref $got ? abs($got - $exp) : 'n/a'), $tol));
}

# A whole matrix against R: shape first, then every cell.
sub cmp_mat {
	my ($got, $exp, $name, $tol) = @_;
	my $shape = ref($got) eq 'ARRAY' && @$got == @$exp
		&& !grep { ref($got->[$_]) ne 'ARRAY' || @{ $got->[$_] } != @{ $exp->[$_] } } 0 .. $#$exp;
	ok($shape, "$name: " . scalar(@$exp) . 'x' . scalar(@{ $exp->[0] }) . ' AoA') or return;
	for my $i (0 .. $#$exp) {
		for my $j (0 .. $#{ $exp->[$i] }) {
			cmp_r($got->[$i][$j], $exp->[$i][$j], "$name [$i][$j]", $tol);
		}
	}
}

# Columns $lo..$hi of a row-major AoA.
sub cols {
	my ($m, $lo, $hi) = @_;
	return [ map { [ @{$_}[$lo .. $hi] ] } @$m ];
}

# The generator names its big matrices instead of repeating them: 'longley' is
# $DATA{longley}, 'longley[0..2]' its first three columns, 'draws' SciPy's
# sample as a two-column matrix and 'draws[1]' its second column.
sub resolve {
	my $r = shift;
	return undef unless defined $r;
	return $r if ref $r;
	my ($name, $lo, $hi) = $r =~ /^(.*?)(?:\[(\d+)(?:\.\.(\d+))?\])?$/;
	my $m = $name eq 'draws'
		? [ map { [ $PY_DRAWS{x}[$_], $PY_DRAWS{y}[$_] ] } 0 .. $#{ $PY_DRAWS{x} } ]
		: $DATA{$name};
	die "no data set '$name'" unless $m;
	return $m unless defined $lo;
	return cols($m, $lo, defined $hi ? $hi : $lo);
}

my @METHODS = qw(pearson spearman kendall);
my %VEC = map { $_->[0] => $_ } @VEC;
my %MAT = map { $_->[0] => $_ } @MAT;

# 1. Every vector case, under every method, against R.
#
# @VEC holds R's regression cases, the man-page vectors, the inputs of every
# SciPy test named in the header, three Inf cases and the regression cases of
# section 7.  Each one is run under all three methods whatever its source
# tested, because the reference value costs nothing and an input that one
# method's suite chose for its awkwardness is usually awkward for the others.
#
# Three Pearson cells are left to section 4b instead: their answer depended on
# the NV's exponent range until 0.3217, and they are checked there in both the
# vector and the matrix form.
my %EXPONENT_RANGE = map { ("$_ pearson" => 1) }
	'pearsonr very small', 'pearsonr very large', 'pearsonr extremely large';
for my $case (@VEC) {
	my ($label, $x, $y, $r) = @$case;
	for my $m (@METHODS) {
		next if $EXPONENT_RANGE{"$label $m"};
		cmp_r(cor($x, $y, $m), $r->{$m}, "C1 $label $m");
	}
}

# A vector result is a plain number, never a 1x1 matrix: tests/reg-tests-1b.R
# "stopifnot(!is.matrix(x)) # was 1x1 in R < 2.7.0".
for my $m (@METHODS) {
	my $v = $VEC{'reg-1b scalar'};
	ok(!ref(cor($v->[1], $v->[2], $m)), "C1 reg-1b $m returns a scalar, not a matrix");
}

# tests/reg-tests-1a.R: "stopifnot(r <= 1) # fails in R <= 1.3.x".
for my $m (@METHODS) {
	my $v = $VEC{'reg-1a zz self'};
	cmp_ok(cor($v->[1], $v->[2], $m), '<=', 1, "C1 reg-1a cor(zz, zz) $m <= 1");
}

# 2. Every matrix case, symmetric and cross, against R.
for my $case (@MAT) {
	my ($label, $xr, $yr, $r) = @$case;
	my ($x, $y) = (resolve($xr), resolve($yr));
	for my $m (@METHODS) {
		my $got = defined $y ? cor($x, $y, $m) : cor($x, undef, $m);
		cmp_mat($got, $r->{$m}, "C2 $label $m");
	}
}

# tests/reg-tests-1a.R: longley has no NAs, so cor(X) and cor(X, X) must
# agree, "all.equal(Cl, cor(X, X, method= meth), tol=ep)" with ep = 32 * Meps.
# Here the two are different code paths -- the symmetric one stores the
# diagonal as 1 and each pair once, the cross one computes every cell -- so this
# is what pins them to each other.  all.equal() compares the mean relative
# difference; this holds every cell to the bound, which is stricter.  2**-52 is
# a double's Meps; a wider NV only narrows the gap.
for my $m (@METHODS) {
	my $sym   = cor($DATA{longley}, undef, $m);
	my $cross = cor($DATA{longley}, $DATA{longley}, $m);
	my $worst = 0;
	for my $i (0 .. $#$sym) {
		for my $j (0 .. $#$sym) {
			my $d = abs($sym->[$i][$j] - $cross->[$i][$j]);
			$worst = $d if $d > $worst;
		}
	}
	cmp_ok($worst, '<=', 32 * 2**-52, "C2 longley $m: cor(X) == cor(X, X) within 32 * Meps");
}

# The cross block of a matrix is the matching block of the full matrix.
for my $m (@METHODS) {
	my $full  = cor($DATA{longley}, undef, $m);
	my $cross = cor(cols($DATA{longley}, 0, 2), cols($DATA{longley}, 3, 6), $m);
	my $worst = 0;
	for my $i (0 .. 2) {
		for my $j (0 .. 3) {
			my $d = abs($full->[$i][$j + 3] - $cross->[$i][$j]);
			$worst = $d if $d > $worst;
		}
	}
	cmp_ok($worst, '<=', 32 * 2**-52, "C2 longley $m: cross block == block of full matrix");
}

# 3. src/library/stats/man/cor.Rd, at the precision its pinned output shows.
#
# tests/Examples/stats-Ex.Rout.save prints the example at seven figures; these
# are those printed numbers, so this is the comparison R's own example check
# would make.  Section 2 already holds cor() to R's full precision.
{
	is(cor([1 .. 10], [2 .. 11]), 1, 'C3 cor.Rd: cor(1:10, 2:11) # == 1');
	# (Cl <- cor(longley)), lower triangle, column by column.
	my @Cl = (
		[ 1.0000000 ],
		[ 0.9915892, 1.0000000 ],
		[ 0.6206334, 0.6042609, 1.0000000 ],
		[ 0.4647442, 0.4464368, -0.1774206, 1.0000000 ],
		[ 0.9791634, 0.9910901, 0.6865515, 0.3644163, 1.0000000 ],
		[ 0.9911492, 0.9952735, 0.6682566, 0.4172451, 0.9939528, 1.0000000 ],
		[ 0.9708985, 0.9835516, 0.5024981, 0.4573074, 0.9603906, 0.9713295, 1.0000000 ],
	);
	my $cl = cor($DATA{longley});
	for my $i (0 .. 6) {
		for my $j (0 .. $i) {
			cmp_r($cl->[$i][$j], $Cl[$i][$j], "C3 Rout.save cor(longley) [$i][$j]", $TOL_PIN);
			cmp_r($cl->[$j][$i], $Cl[$i][$j], "C3 Rout.save cor(longley) [$j][$i]", $TOL_PIN);
		}
	}

	# "How much do they differ?": cor(cbind(P = Cl[i], S = clS[i], K = clK[i]))
	# over the lower triangles, built here from cor()'s own three matrices.
	my $cs = cor($DATA{longley}, undef, 'spearman');
	my $ck = cor($DATA{longley}, undef, 'kendall');
	my @rows;
	for my $j (0 .. 6) {                  # R's lower.tri() order: column-major
		for my $i ($j + 1 .. 6) {
			push @rows, [ $cl->[$i][$j], $cs->[$i][$j], $ck->[$i][$j] ];
		}
	}
	my $psk = cor(\@rows);
	my @PSK = ([ 1, 0.9802390, 0.9572562 ], [ 0.9802390, 1, 0.9742171 ],
	           [ 0.9572562, 0.9742171, 1 ]);
	cmp_mat($psk, \@PSK, 'C3 Rout.save P/S/K agreement', $TOL_PIN);
	# The same matrix to R's full precision.  Its inputs are cor()'s own
	# answers rather than R's; the worst cell was measured at 1.1e-16 from R's,
	# well inside $TOL.
	cmp_mat($psk, $LONGLEY_PSK, 'C3 P/S/K agreement, full precision');

	# use = "pairwise" on swM, rebuilt one pair at a time from the rows where
	# both columns are present.  The diagonal is R's 1 too.
	for my $m (@METHODS) {
		my $exp = $SWM_PAIRWISE{$m};
		for my $i (0 .. 5) {
			for my $j (0 .. 5) {
				my (@a, @b);
				for my $row (@{ $DATA{swM} }) {
					next unless defined $row->[$i] && defined $row->[$j];
					push @a, $row->[$i];
					push @b, $row->[$j];
				}
				cmp_r(cor(\@a, \@b, $m), $exp->[$i][$j], "C3 swM pairwise $m [$i][$j]");
			}
		}
	}
}

# 4. SciPy's own literals, verbatim, at the upstream assertion's tolerance.
#
# Kinds, after numpy.testing and scipy._lib._array_api:
#   approx7  assert_approx_equal(significant=7): scaled to the common decade,
#            the difference must be below 1e-6
#   almost7  assert_almost_equal(decimal=7): |got - exp| < 1.5e-7
#   close    xp_assert_close for float64: rtol = 4 * sqrt(eps) = 5.96e-8
#   allclose assert_allclose: rtol = 1e-7
#   atol15   xp_assert_close(..., atol=1e-15)
#   equal    xp_assert_equal: exactly
#   nan      the statistic is NaN (nan_policy='propagate')
sub scipy_ok {
	my ($got, $exp, $kind, $name) = @_;
	if ($kind eq 'nan')   { ok(is_nan($got), "$name is NaN") or diag('got ' . (defined $got ? $got : 'undef')); return }
	if ($kind eq 'equal') { is($got, $exp, $name); return }
	my $ok;
	if ($kind eq 'approx7') {
		my $scale = 0.5 * (abs($exp) + abs($got));
		if ($scale == 0) { $ok = 1 }
		else {
			$scale = 10**POSIX::floor(log($scale) / log(10));
			$ok = abs($exp / $scale - $got / $scale) < 10**-6;
		}
	}
	elsif ($kind eq 'almost7')  { $ok = abs($got - $exp) < 1.5e-7 }
	elsif ($kind eq 'close')    { $ok = abs($got - $exp) <= 4 * sqrt(2**-52) * abs($exp) }
	elsif ($kind eq 'allclose') { $ok = abs($got - $exp) <= 1e-7 * abs($exp) }
	elsif ($kind eq 'atol15')   { $ok = abs($got - $exp) <= 1e-15 }
	else { die "unknown kind $kind" }
	ok($ok, "$name ($kind)") or diag(sprintf('got %.17g expected %.17g', $got, $exp));
}
sub vcor {
	my ($label, $m) = @_;
	my $v = $VEC{$label} or die "no vector case '$label'";
	return cor($v->[1], $v->[2], $m);
}

# [ vector case, method, SciPy's literal, kind, upstream test ]
my @SCIPY = (
	# test_stats.py TestPearsonr
	[ 'pearsonr arange3 self',     'pearson', 1.0,                 'atol15', 'test_r_almost_exactly_pos1' ],
	[ 'pearsonr arange3 neg',      'pearson', -1.0,                'atol15', 'test_r_almost_exactly_neg1' ],
	[ 'pearsonr basic',            'pearson', 3**0.5 / 2,          'close',  'test_basic' ],
	[ 'pearsonr length two pos',   'pearson', 1,                   'equal',  'test_length_two_pos1' ],
	[ 'pearsonr length two neg',   'pearson', -1,                  'equal',  'test_length_two_neg1' ],
	[ 'pearsonr basic example +',  'pearson', 0.6741998624632421,  'close',  'test_basic_example sign=1' ],
	[ 'pearsonr basic example -',  'pearson', -0.6741998624632421, 'close',  'test_basic_example sign=-1' ],
	[ 'pearsonr length3 exact -1', 'pearson', -1.0,                'close',  'test_length3_r_exactly_negative_one' ],
	# test_mstats_basic.py TestCorr::test_pearsonr: arange(10) against itself
	# and reversed, which are the inputs of two of the Kendall cases below.
	[ 'kendalltau no ties 5', 'pearson', 1.0,          'almost7', 'mstats test_pearsonr x, x' ],
	[ 'kendalltau no ties 8', 'pearson', -1.0,         'almost7', 'mstats test_pearsonr x, x[::-1]' ],
	[ 'pearsonr basic',       'pearson', sqrt(3) / 2,  'almost7', 'mstats test_pearsonr x1, y1' ],
	# test_stats.py TestCorrSpearmanr / TestCorrSpearmanr2
	[ 'spearmanr nan_policy self',  'spearman', undef,                'nan',     'test_nan_policy (propagate)' ],
	[ 'spearmanr 1d_vs_2d nans',    'spearman', undef,                'nan',     'test_1d_vs_2d_nans (propagate)' ],
	[ 'spearmanr vs R',             'spearman', 0.82078268166812329,  'approx7', 'test_spearmanr_vs_r' ],
	[ 'spearmanr corr_1',           'spearman', 1.0,                  'approx7', 'test_corr_1' ],
	[ 'spearmanr gh6061',           'spearman', 0.998,                'almost7', 'test_gh_issue_6061_windows_overflow' ],
	[ 'spearmanr alternative nan',  'spearman', undef,                'nan',     'test_alternative_nan_policy (propagate)' ],
	# test_correlation.py TestSpearmanRho
	[ 'spearmanrho vs R',       'spearman', -0.2727272727272727, 'close', 'test_against_R_cor_test' ],
	[ 'spearmanrho vs R exact', 'spearman', -0.4857142857142857, 'close', 'test_against_R_cor_test_exact' ],
	# test_mstats_basic.py TestCorr::test_spearmanr / test_spearmanr_alternative
	[ 'mstats spearmanr 4',  'spearman', -0.6324555,          'almost7',  'mstats test_spearmanr 4 points' ],
	[ 'mstats spearmanr 15', 'spearman', 0.6887299,           'almost7',  'mstats test_spearmanr 15 points' ],
	[ 'mstats spearmanr 15', 'spearman', 0.6887298747763864,  'allclose', 'mstats test_spearmanr_alternative' ],
	[ 'spearmanr gh6061',    'spearman', 0.998,               'almost7',  'mstats test_spearmanr 2000 points' ],
	# test_stats.py TestKendallTau::test_kendalltau_no_ties ("from R")
	[ 'kendalltau no ties 1',  'kendall', 0.0,                 'close', 'test_kendalltau_no_ties 1' ],
	[ 'kendalltau no ties 2',  'kendall', 0.0,                 'close', 'test_kendalltau_no_ties 2' ],
	[ 'kendalltau no ties 3',  'kendall', -0.14285714286,      'close', 'test_kendalltau_no_ties 3' ],
	[ 'kendalltau no ties 4',  'kendall', 0.047619047619,      'close', 'test_kendalltau_no_ties 4' ],
	[ 'kendalltau no ties 5',  'kendall', 1.0,                 'close', 'test_kendalltau_no_ties 5' ],
	[ 'kendalltau no ties 6',  'kendall', 0.9555555555555556,  'close', 'test_kendalltau_no_ties 6' ],
	[ 'kendalltau no ties 7',  'kendall', 0.9111111111111111,  'close', 'test_kendalltau_no_ties 7' ],
	[ 'kendalltau no ties 8',  'kendall', -1.0,                'close', 'test_kendalltau_no_ties 8' ],
	[ 'kendalltau no ties 9',  'kendall', -0.9555555555555556, 'close', 'test_kendalltau_no_ties 9' ],
	[ 'kendalltau no ties 10', 'kendall', -0.9111111111111111, 'close', 'test_kendalltau_no_ties 10' ],
	# TestKendallTau::test_kendalltau_ties and the rest of the class
	[ 'kendalltau Kendall 1970',    'kendall', 0.85895569,           'close',   'test_kendalltau_ties, variant b' ],
	[ 'kendalltau ties vs R',       'kendall', -0.47140452079103173, 'approx7', 'test_kendalltau_ties, vs R' ],
	[ 'kendalltau 1,1,2 self',      'kendall', 1.0,                  'close',   'test_kendalltau_ties, [1,1,2]' ],
	[ 'kendalltau nan_policy self', 'kendall', undef,                'nan',     'test_nan_policy (propagate)' ],
	# test_mstats_basic.py TestCorr::test_kendalltau.  The mstats function
	# masks a NaN pair out, which is what the complete-case rows are.
	[ 'mstats kendalltau p=1',          'kendall', 0.0,                 'almost7', 'mstats test_kendalltau max disorder' ],
	[ 'kendalltau no ties 5',           'kendall', 1.0,                 'almost7', 'mstats test_kendalltau arange' ],
	[ 'kendalltau no ties 6',           'kendall', 0.9555555555555556,  'almost7', 'mstats test_kendalltau one swap' ],
	[ 'kendalltau no ties 7',           'kendall', 0.9111111111111111,  'almost7', 'mstats test_kendalltau two swaps' ],
	[ 'kendalltau no ties 8',           'kendall', -1.0,                'almost7', 'mstats test_kendalltau reversed' ],
	[ 'kendalltau no ties 9',           'kendall', -0.9555555555555556, 'almost7', 'mstats test_kendalltau reversed, one swap' ],
	[ 'kendalltau no ties 10',          'kendall', -0.9111111111111111, 'almost7', 'mstats test_kendalltau reversed, two swaps' ],
	[ 'mstats kendalltau x y',          'kendall', 0.3333333,           'almost7', 'mstats test_kendalltau x, y' ],
	[ 'mstats kendalltau x z',          'kendall', -0.5477226,          'almost7', 'mstats test_kendalltau x, z' ],
	[ 'mstats kendalltau 22 complete',  'kendall', -0.1585188,          'almost7', 'mstats test_kendalltau 22 points' ],
);
for my $s (@SCIPY) {
	my ($label, $m, $exp, $kind, $test) = @$s;
	scipy_ok(vcor($label, $m), $exp, $kind, "C4 SciPy $test: $label $m");
}

# 4b. Pearson at the ends of the exponent range.
#
# TestPearsonr::test_very_small_input_values (SciPy gh-9353),
# test_very_large_input_values (gh-8980) and test_extremely_large_input_values,
# whose expected values upstream says were "computed using mpmath with 80
# digits of precision".  The centred sums of squares that pearson_corr()
# forms are about 4e-361 (very small, y), 3e181 (very large, y) and 7e402
# (extremely large, y).  The first underflows a double and the last overflows
# it; the middle one fits, but pearson_corr() then takes sqrt(vxx * vyy), and
# that product, about 5e361, does not.
#
# What each side gives.  R's two-argument cor() sums in long double and takes
# each standard deviation's square root there before rounding it to a double
# (src/library/stats/src/cov.c, COV_SDEV), which rescues the first two; the
# covariance itself is still stored as a double, and the third one's, about
# 1e401, overflows to Inf there and makes it NA.
#
#   case             mpmath (truth)      R 4.6.1              cor(), double NV
#   very small       0.7272930540750450  0.72729305407504519  NaN  (vyy underflows to 0)
#   very large       0.8660254037844386  0.86602540378443871  0    (vxx*vyy overflows to Inf)
#   extremely large  0.351312332103289   NA (cov -> Inf)      NaN  (dx*dx overflows)
#
# On a long-double or __float128 perl nothing over- or underflows.  This was
# observed by running pearson_corr()'s arithmetic in numpy.longdouble (x87, the
# perl-5.12.5 and 5.16.3 layout) and in mpmath at 113 bits (the __float128
# significand, with an exponent range wider than these cases need): all three
# came out within 2e-17 of the mpmath value.  On a double perl the last column
# of the table above was the answer through 0.3216.  0.3217's cor_centre()
# divides a column through by its largest |deviation| when its sum of squares
# overflows or drops below NV_MIN / NV_EPSILON -- SciPy's remedy, applied only
# where needed -- and cor_from_centred() takes the root of each factor when
# vxx * vyy would leave the normal range.  After it, on perl-5.44.0, the three
# came out 0.72729305407504530, 0.86602540378443871 and 0.35131233210328916.
# So the expected value is SciPy's at every width.  'extremely large' is now
# better than R's NA; that is recorded here rather than in section 9 because
# the truth is not in doubt.  The matrix branch centres through the same
# function, so each case is also run as a two-column matrix.  The rank methods
# for the same inputs are ordinary and stay in section 1.
{
	my @EXP = (
		[ 'pearsonr very small',      0.7272930540750450, 'test_very_small_input_values' ],
		[ 'pearsonr very large',      0.8660254037844386, 'test_very_large_input_values' ],
		[ 'pearsonr extremely large', 0.351312332103289,  'test_extremely_large_input_values' ],
	);
	for my $e (@EXP) {
		my ($label, $exp, $test) = @$e;
		scipy_ok(vcor($label, 'pearson'), $exp, 'close', "C4b SciPy $test: $label pearson");
		my $v = $VEC{$label};
		my $m = cor([ map { [ $v->[1][$_], $v->[2][$_] ] } 0 .. $#{ $v->[1] } ]);
		scipy_ok($m->[0][1], $exp, 'close', "C4b SciPy $test: $label pearson, matrix form");
	}
}

# TestPearsonrWilkinson / TestCorrSpearmanr: Wilkinson's W.II.D, "All the
# correlations, except for ZERO and MISS, should be exactly 1 ... The same
# should go for SPEARMAN correlations".  ZERO is section 9's constant input.
for my $label (grep { /^Wilkinson / } map { $_->[0] } @VEC) {
	scipy_ok(vcor($label, $_), 1.0, 'approx7', "C4 SciPy $label $_") for qw(pearson spearman);
}

# TestCorrSpearmanr2::test_tie1: "Result of spearmanr should be the same as
# applying pearsonr to the ranks", here cor(spearman) against cor(pearson) on
# the hand-ranked data, both from cor().
scipy_ok(vcor('spearmanr tie1', 'spearman'), vcor('spearmanr tie1 ranks', 'pearson'),
         'almost7', 'C4 SciPy test_tie1: spearman == pearson on the ranks');

# TestCorrSpearmanr::test_1d_vs_2d and test_1d_vs_2d_nans: the vector call and
# the off-diagonal of the two-column matrix are the same number.
{
	my @x1 = (1, 2, 3, 4, 5, 6);
	my @x2 = (1, 2, 3, 4, 6, 5);
	my $m  = cor([ map { [ $x1[$_], $x2[$_] ] } 0 .. 5 ], undef, 'spearman');
	is($m->[0][1], cor(\@x1, \@x2, 'spearman'), 'C4 SciPy test_1d_vs_2d: vector == matrix');
	my @n1 = (1, undef, 3, 4, 5, 6);
	my @n2 = (1, 2, 3, 4, 6, undef);
	my $mn = cor([ map { [ $n1[$_], $n2[$_] ] } 0 .. 5 ], undef, 'spearman');
	ok(is_nan($mn->[0][1]) && is_nan(cor(\@n1, \@n2, 'spearman')),
	   'C4 SciPy test_1d_vs_2d_nans: NaN from both forms');
}

# TestCorrSpearmanr::test_3cols, at assert_allclose's rtol of 1e-7 against
# SciPy's eight-figure matrix.
{
	my $got = cor(resolve($MAT{'spearmanr 3cols'}[1]), undef, 'spearman');
	my @exp = ([ 1, -1, 0.94285714 ], [ -1, 1, -0.94285714 ], [ 0.94285714, -0.94285714, 1 ]);
	for my $i (0 .. 2) {
		for my $j (0 .. 2) {
			scipy_ok($got->[$i][$j], $exp[$i][$j], 'allclose', "C4 SciPy test_3cols [$i][$j]");
		}
	}
}

# TestCorrSpearmanr::test_gh_9103, nan_policy='propagate': every entry that
# involves column 0 or 1 is NaN and [2][2] is 1.  SciPy also puts NaN on the
# diagonal of the two NaN columns; R and cor() put 1 there (section 9).
{
	my $got = cor(resolve($MAT{'spearmanr gh9103'}[1]), undef, 'spearman');
	for my $i (0 .. 2) {
		for my $j (0 .. 2) {
			next if $i == $j;
			ok(is_nan($got->[$i][$j]), "C4 SciPy test_gh_9103 [$i][$j] is NaN");
		}
	}
	is($got->[2][2], 1, 'C4 SciPy test_gh_9103 [2][2] is 1');
}

# TestCorrSpearmanr::test_constant_input_gh22816, columns 2 and 3 (columns 0
# and 1 are constant; see section 9).
{
	my $got = cor(resolve($MAT{'spearmanr gh22816 cols 2,3'}[1]), undef, 'spearman');
	my @exp = ([ 1, -1 ], [ -1, 1 ]);
	for my $i (0 .. 1) {
		for my $j (0 .. 1) {
			scipy_ok($got->[$i][$j], $exp[$i][$j], 'allclose', "C4 SciPy test_constant_input_gh22816 [$i][$j]");
		}
	}
}

# TestKendallTau::test_kendalltau_nan_2nd_arg_gh6134: nan_policy='omit' must
# equal the call on the complete rows "atol=1e-15"; propagate is NaN.
scipy_ok(vcor('kendalltau gh6134', 'kendall'), undef, 'nan', 'C4 SciPy test_kendalltau_nan_2nd_arg_gh6134 propagate');

# 5. SciPy's 500-pair normal sample: test_normal_draws and test_large_arrays.
#
# The sample was drawn by NumPy and is frozen in %PY_DRAWS.  SciPy pins two of
# its statistics; R's value for all three is in %MAT ('draws') and is checked
# in section 2.  Here the vector form is checked against SciPy's own literal
# and against SciPy's full-precision Pearson, which no SciPy test pins.
{
	my ($x, $y) = ($PY_DRAWS{x}, $PY_DRAWS{y});
	is(scalar(@$x), 500, 'C5 draws: 500 pairs');
	scipy_ok(cor($x, $y, 'spearman'), 0.28659685838743354, 'approx7', 'C5 SciPy test_normal_draws spearman');
	scipy_ok(cor($x, $y, 'kendall'),  0.19291382765531062, 'close',   'C5 SciPy test_large_arrays kendall');
	for my $m (@METHODS) {
		cmp_r(cor($x, $y, $m), $PY{"draws $m"}, "C5 draws $m against SciPy repr()");
		cmp_r(cor($x, $y, $m), $MAT{draws}[3]{$m}[0][1], "C5 draws $m vector == R's matrix entry");
	}
}

# 6. 200000 pairs in seven tied levels, after SciPy's gh-18139 overflow test.
#
# SciPy's own data come from Python's random.choices(), which cannot be
# reproduced here, so wh200k is two Wichmann-Hill components (multipliers 171
# and 172, moduli 30269 and 30307) reduced to 1..7.  Every intermediate is
# below 172 * 30307 = 5.2e6, so the recurrence is exact integer arithmetic on
# a 32-bit IV and the sample is the same on every perl.  What it keeps from
# gh-18139 is n(n-1)/2 = 2e10 pairs, past 2**32, all of them in tie blocks of
# ~28000: a pair count that wraps at 32 bits, or a tie count kept in an int,
# moves Kendall's tau by orders of magnitude.  R 4.6.1's cor(method =
# "kendall") took 628 s over its O(n^2) pair loop to print
# 0.00020561663689276635, which is what SciPy's O(n log n) kendalltau and
# cor() give, to the last bit; the generator gets R's value from the 7 x 7
# table instead, to the same bit.  cor() takes under a tenth of a second.
{
	my ($s, $t) = (12345, 6789);
	my (@x, @y);
	for (1 .. 200000) {
		$s = (171 * $s) % 30269;
		$t = (172 * $t) % 30307;
		push @x, $s % 7 + 1;
		push @y, $t % 7 + 1;
	}
	for my $m (@METHODS) {
		my $r = cor(\@x, \@y, $m);
		cmp_r($r, $R_WH200K{$m},      "C6 wh200k $m against R");
		cmp_r($r, $PY{"wh200k $m"},   "C6 wh200k $m against SciPy");
	}
}

# 7. Regression cases for bugs fixed in cor() itself.
#
# Each now gives R 4.6.1's answer.  The vector and matrix values are also in
# @VEC/@MAT, and so in sections 1 and 2; they are asserted again here by name so
# that a failure says which fix came undone.
{
	# Ranking and pair counting used to take the NaN as an ordinary value.
	my @x = (1, 2, undef, 4, 5, 6);
	my @y = (2, 1, 4, 3, 6, 5);
	ok(is_nan(cor(\@x, \@y, 'spearman')), 'C7 incomplete pair: spearman is NA (was 0.82857)');
	ok(is_nan(cor(\@x, \@y, 'kendall')),  'C7 incomplete pair: kendall is NA (was 0.6)');
	ok(is_nan(cor(\@x, \@y, 'pearson')),  'C7 incomplete pair: pearson is NA');

	# The matrix branch ranked a column with an NA in it.
	my $X = [ [ 1, 1 ], [ undef, 2 ], [ 3, 4 ], [ 4, 3 ] ];
	for my $m (qw(spearman kendall)) {
		my $r = cor($X, undef, $m);
		ok($r->[0][0] == 1 && is_nan($r->[0][1]) && is_nan($r->[1][0]) && $r->[1][1] == 1,
		   "C7 matrix with an NA: $m is [[1, NA], [NA, 1]]");
	}

	# A non-matrix y beside a matrix x was dropped, so these returned cor(X).
	my $M = [ [ 1, 2 ], [ 2, 1 ], [ 3, 5 ], [ 4, 3 ] ];
	throws_ok { cor($M, [ 1, 2, 3, 4 ]) } qr/^cor: y must be a matrix \(array ref of array refs\) when x is a matrix/,
		'C7 cor(X, yvec) croaks (used to return cor(X))';
	throws_ok { cor($M, []) } qr/^cor: y must be a matrix \(array ref of array refs\) when x is a matrix/,
		'C7 cor(X, []) croaks (used to return cor(X))';

	# The method in y's slot used to be taken for "no y", and cor(x) is 1.
	throws_ok { cor([ 1, 2, 3 ], 'spearman') } qr/^cor: y must be an ARRAY reference or undef/,
		"C7 cor(\\\@x, 'spearman') croaks (used to return 1)";

	# A one-row matrix used to be told its column 0 had no variance.
	throws_ok { cor([ [ 1, 2, 3 ] ]) } qr/^cor: need at least 2 observations \(got 1\)/,
		'C7 one-row matrix: too few observations, not zero variance';
}

# 8. The Perl-side surface.
{
	my $v  = $VEC{'spearmanr vs R'};
	my $L  = $DATA{longley};

	# The method defaults to pearson in both forms.
	is(cor($v->[1], $v->[2]), cor($v->[1], $v->[2], 'pearson'), 'C8 default method is pearson (vector)');
	is_deeply(cor($L), cor($L, undef, 'pearson'), 'C8 default method is pearson (matrix)');

	# Shapes: p x p for cor(X), p x q for cor(X, Y).
	my $c = cor(cols($L, 0, 2), cols($L, 3, 6), 'kendall');
	is(scalar(@$c), 3, 'C8 cross matrix has p = 3 rows');
	is(scalar(@{ $c->[$_] }), 4, "C8 cross matrix row $_ has q = 4 columns") for 0 .. 2;
	my $f = cor($L, undef, 'spearman');
	is(scalar(@$f), 7, 'C8 cor(longley) has 7 rows');
	ok(!grep({ @$_ != 7 } @$f), 'C8 cor(longley) rows are 7 wide');
	ok(!grep({ $f->[$_][$_] != 1 } 0 .. 6), 'C8 cor(longley) diagonal is exactly 1');
	ok(!grep({ my $i = $_; grep { $f->[$i][$_] != $f->[$_][$i] } 0 .. 6 } 0 .. 6),
	   'C8 cor(longley) is exactly symmetric');

	# cor() reads its inputs and leaves them alone: the rank methods work on
	# copies, not on the caller's data.
	my @x = @{ $v->[1] };
	my @y = @{ $v->[2] };
	my @Lc = map { [@$_] } @$L;
	cor(\@x, \@y, $_) for @METHODS;
	cor(\@Lc, undef, $_) for @METHODS;
	cor(\@Lc, \@Lc, $_) for @METHODS;
	is_deeply([ \@x, \@y ], [ $v->[1], $v->[2] ], 'C8 vector inputs unchanged');
	is_deeply(\@Lc, $L, 'C8 matrix input unchanged');

	# Numeric strings are numbers; a non-numeric cell is NA, silently -- this
	# file runs under FATAL warnings, so a "isn't numeric" warning would die.
	for my $m (@METHODS) {
		is(cor([ '1', '2.5', '3', '4' ], [ 2, 1, 4, 3 ], $m), cor([ 1, 2.5, 3, 4 ], [ 2, 1, 4, 3 ], $m),
		   "C8 numeric strings read as numbers ($m)");
		ok(is_nan(cor([ 'a', 2, 3, 4 ], [ 2, 1, 4, 3 ], $m)), "C8 non-numeric string is NA ($m)");
		ok(is_nan(cor([ 'NaN', 2, 3, 4 ], [ 2, 1, 4, 3 ], $m)), "C8 'NaN' is NA ($m)");
		my $r = cor([ [ 1, 1 ], [ 'x', 2 ], [ 3, 4 ], [ 4, 3 ] ], undef, $m);
		ok(is_nan($r->[0][1]) && $r->[0][0] == 1, "C8 non-numeric matrix cell is NA ($m)");
	}

	# A row shorter than the first is NA in the cells it lacks; a longer one's
	# extra cells are ignored, because the first row sets the width.
	for my $m (@METHODS) {
		my $short = cor([ [ 1, 1 ], [ 2 ], [ 3, 4 ], [ 4, 3 ] ], undef, $m);
		ok(is_nan($short->[0][1]) && is_nan($short->[1][0]), "C8 short row reads as NA ($m)");
		is_deeply(cor([ [ 1, 1 ], [ 2, 2, 99 ], [ 3, 4 ], [ 4, 3 ] ], undef, $m),
		          cor([ [ 1, 1 ], [ 2, 2 ], [ 3, 4 ], [ 4, 3 ] ], undef, $m),
		          "C8 cells past the first row's width are ignored ($m)");
	}
}

# Every croak, by message.
{
	my $X = [ [ 1, 2 ], [ 2, 1 ], [ 3, 5 ] ];
	my @CROAK = (
		[ sub { cor([ 1, 2 ], [ 1, 2 ], 'bogus') },  qr/^cor: unknown method 'bogus' \(use 'pearson', 'spearman', or 'kendall'\)/, 'unknown method' ],
		[ sub { cor([ 1, 2 ], [ 1, 2 ], 'Pearson') }, qr/^cor: unknown method 'Pearson'/, 'method is case-sensitive' ],
		[ sub { cor($X, undef, 'bogus') },            qr/^cor: unknown method 'bogus'/, 'unknown method, matrix' ],
		[ sub { cor(1) },                             qr/^cor: x must be an ARRAY reference/, 'x a number' ],
		[ sub { cor(undef, [ 1, 2 ]) },               qr/^cor: x must be an ARRAY reference/, 'x undef' ],
		[ sub { cor({}, [ 1, 2 ]) },                  qr/^cor: x must be an ARRAY reference/, 'x a hash ref' ],
		[ sub { cor([]) },                            qr/^cor: x is empty/, 'x empty, no y' ],
		[ sub { cor([], []) },                        qr/^cor: x is empty/, 'x and y empty (reg-tests-1b numeric(0))' ],
		[ sub { cor([ 1, 2, 3 ], [ 1, 2 ]) },         qr/^cor: x and y must have the same length \(3 vs 2\)/, 'length mismatch' ],
		[ sub { cor([ 1, 2 ], [ 1, 2, 3 ]) },         qr/^cor: x and y must have the same length \(2 vs 3\)/, 'length mismatch, y longer' ],
		[ sub { cor([ 1 ], [ 2 ]) },                  qr/^cor: need at least 2 observations/, 'n = 1 vectors' ],
		[ sub { cor([ [ 1, 2 ] ]) },                  qr/^cor: need at least 2 observations \(got 1\)/, 'one-row matrix' ],
		[ sub { cor([ [ 1, 2 ] ], [ [ 3 ] ]) },       qr/^cor: need at least 2 observations \(got 1\)/, 'one-row cross' ],
		[ sub { cor([ 1, 1, 1 ], [ 1, 2, 3 ]) },      qr/^cor: standard deviation of x is 0/, 'constant x' ],
		[ sub { cor([ 1, 2, 3 ], [ 2, 2, 2 ]) },      qr/^cor: standard deviation of y is 0/, 'constant y' ],
		[ sub { cor([ 5, 5 ], [ 2, 2 ]) },            qr/^cor: standard deviation of x is 0/, 'both constant: x named first' ],
		[ sub { cor([ [ 1, 7 ], [ 2, 7 ], [ 3, 7 ] ]) }, qr/^cor: standard deviation is 0 in x column 1/, 'constant x column' ],
		[ sub { cor($X, [ [ 4 ], [ 4 ], [ 4 ] ]) },   qr/^cor: standard deviation is 0 in y column 0/, 'constant y column' ],
		[ sub { cor([ 1, 2, 3 ], 'spearman') },       qr/^cor: y must be an ARRAY reference or undef \(the method is the third argument: cor\(x, undef, 'spearman'\)\)/, 'method in y slot' ],
		[ sub { cor([ 1, 2, 3 ], {}) },               qr/^cor: y must be an ARRAY reference or undef/, 'y a hash ref' ],
		[ sub { cor([ 1, 2, 3 ], 7) },                qr/^cor: y must be an ARRAY reference or undef/, 'y a number' ],
		[ sub { cor($X, [ 1, 2, 3 ]) },               qr/^cor: y must be a matrix \(array ref of array refs\) when x is a matrix/, 'matrix x, vector y' ],
		[ sub { cor($X, []) },                        qr/^cor: y must be a matrix \(array ref of array refs\) when x is a matrix/, 'matrix x, empty y' ],
		[ sub { cor([ 1, 2, 3 ], $X) },               qr/^cor: x must be a matrix \(array ref of array refs\) when y is a matrix/, 'vector x, matrix y' ],
		[ sub { cor($X, [ [ 1 ], [ 2 ] ]) },          qr/^cor: x and y must have the same number of rows \(3 vs 2\)/, 'row-count mismatch' ],
		[ sub { cor([ [ 1, 2 ], 5, [ 3, 1 ] ]) },     qr/^cor: x row 1 is not an array ref/, 'x row not a ref' ],
		[ sub { cor([ [ 1, 2 ], [ 2, 1 ], undef ]) }, qr/^cor: x row 2 is not an array ref/, 'x row undef' ],
		[ sub { cor($X, [ [ 1 ], [ 2 ], 'z' ]) },     qr/^cor: y row 2 is not an array ref/, 'y row not a ref' ],
		[ sub { cor([ [], [] ]) },                    qr/^cor: x matrix has zero columns/, 'x zero columns (reg-tests-1b Z[, FALSE])' ],
		[ sub { cor($X, [ [], [], [] ]) },            qr/^cor: y matrix has zero columns/, 'y zero columns' ],
	);
	for my $c (@CROAK) {
		my ($code, $re, $what) = @$c;
		throws_ok { $code->() } $re, "C8 croak: $what";
	}
}

# 9. Recorded divergences from the references.
#
# Each is a place where cor() deliberately does not do what R or SciPy does.
# They are asserted, not merely commented, so that changing one is a decision
# somebody has to make on purpose.

# (a) Zero variance.  R returns NA with the warning "the standard deviation is
#     zero"; SciPy returns NaN with a ConstantInputWarning.  cor() croaks, by
#     design: a constant column is nearly always a mistake upstream, and a
#     warning in a long run is easy to lose.  The inputs are SciPy's:
#     TestPearsonr::test_constant_input and test_length_two_constant_input,
#     TestCorrSpearmanr2::test_tie0 and test_gh_11111, TestKendallTau::
#     test_degenerate_input, Wilkinson's ZERO, and test_constant_input_gh22816,
#     whose two constant columns cor() names rather than filling with NaN.
{
	my @gh11111 = (0, 0.009783728115345005, 0, 0, 0.0019759230121848587,
	               0.0007535430349118562, 0.0002661781514710257, 0, 0, 0.0007835762419683435);
	my @CONST = (
		[ [ 0.667, 0.667, 0.667 ], [ 0.123, 0.456, 0.789 ], 'x', 'test_constant_input' ],
		[ [ 0.667, 0.667 ],        [ 0.123, 0.456 ],        'x', 'test_length_two_constant_input' ],
		[ [ 2, 2, 2 ], [ 2, 2, 2 ], 'x', 'test_tie0 / test_degenerate_input [2,2,2] [2,2,2]' ],
		[ [ 2, 0, 2 ], [ 2, 2, 2 ], 'y', 'test_tie0 / test_degenerate_input [2,0,2] [2,2,2]' ],
		[ [ 2, 2, 2 ], [ 2, 0, 2 ], 'x', 'test_tie0 / test_degenerate_input [2,2,2] [2,0,2]' ],
		[ [ (1.0) x 10 ], \@gh11111, 'x', 'test_gh_11111' ],
		[ [ 1 .. 9 ], [ (0) x 9 ], 'y', 'Wilkinson X, ZERO' ],
	);
	for my $c (@CONST) {
		my ($x, $y, $which, $test) = @$c;
		for my $m (@METHODS) {
			throws_ok { cor($x, $y, $m) } qr/^cor: standard deviation of $which is 0/,
				"C9a $test $m croaks (R: NA, SciPy: NaN)";
		}
	}
	my @gh22816 = map { [ 0, 0, $_, -$_ ] } 0 .. 9;
	throws_ok { cor(\@gh22816, undef, 'spearman') } qr/^cor: standard deviation is 0 in x column 0/,
		'C9a test_constant_input_gh22816 croaks on column 0 (SciPy: NaN rows)';
}

# (b) Too few values to correlate.  R's cor(4, 2) is NA and SciPy's
#     spearmanr(4., 2.) (test_scalar) and kendalltau([0], [0]) are NaN;
#     cor() croaks.  A column whose non-NA values number fewer than two, or
#     are all equal, is refused the same way: tests/reg-tests-2.R's "corner
#     cases for cor" matrix cbind(NA, 1:3, rnorm(3)) gives R an NA first row
#     and column, and cor() says column 0 has no variance.  Its columns 2 and
#     3 alone are in @MAT and agree with R.
{
	for my $m (@METHODS) {
		throws_ok { cor([ 4 ], [ 2 ], $m) } qr/^cor: need at least 2 observations/,
			"C9b cor(4, 2) $m croaks (R: NA, SciPy test_scalar: NaN)";
		throws_ok { cor([ 1, 1, undef ], [ 1, 2, 3 ], $m) } qr/^cor: standard deviation of x is 0/,
			"C9b cor(c(1, 1, NA), 1:3) $m croaks (R: NA)";
		for my $k (0 .. 1) {
			throws_ok { cor($REG2_CORNER_X[$k], undef, $m) } qr/^cor: standard deviation is 0 in x column 0/,
				"C9b reg-tests-2 corner case " . ($k ? 'X[1,1] <- 1' : 'all-NA column') . " $m croaks (R: NA)";
		}
	}
}

# (c) cor(x) with a flat vector and no y is 1.  R refuses it ("supply both 'x'
#     and 'y' or a matrix-like 'x'"); tests/reg-tests-2.R PR 883 notes that
#     cor(rnorm(10), NULL) "gave ... 1 ... in 1.2.2", and R has errored since.
#     cor() keeps the 1, which is the correlation of a variable with itself.
is(cor([ 1, 2, 3 ]), 1, 'C9c cor(vector) is 1 (R: error since PR 883)');
is(cor([ 1, 2, 3 ], undef, 'kendall'), 1, 'C9c cor(vector, undef, kendall) is 1');

# (d) Mixing a vector and a matrix.  tests/reg-tests-1a.R PR#7116 has R treat
#     a vector beside a matrix as a one-column matrix, so both
#     cor(as.array(c(a=1,b=2)), cbind(1:2)) and its transpose are a 1x1
#     matrix.  cor() croaks in both directions rather than guess the shape;
#     the one-column-matrix form it accepts is in @MAT as 'PR#7116 1x1'.
throws_ok { cor([ 1, 2 ], [ [ 1 ], [ 2 ] ]) } qr/^cor: x must be a matrix/, 'C9d PR#7116 vector, matrix croaks (R: 1x1)';
throws_ok { cor([ [ 1 ], [ 2 ] ], [ 1, 2 ]) } qr/^cor: y must be a matrix/, 'C9d PR#7116 matrix, vector croaks (R: 1x1)';

# (e) The diagonal of a column with an NA.  R puts 1 there at use =
#     "everything" and so does cor(); SciPy's spearmanr puts NaN
#     (test_gh_9103's expected matrix).
{
	my $r = cor(resolve($MAT{'spearmanr gh9103'}[1]), undef, 'spearman');
	ok($r->[0][0] == 1 && $r->[1][1] == 1, 'C9e NA column diagonal is 1 (R), not NaN (SciPy)');
}

# (f) Method names.  R's match.arg() accepts any unambiguous abbreviation, so
#     cor(x, y, method = "k") is Kendall; cor() wants the whole name.
throws_ok { cor([ 1, 2, 3 ], [ 3, 1, 2 ], 'k') } qr/^cor: unknown method 'k'/, "C9f abbreviation 'k' croaks (R: kendall)";

# 10. Leaks: every method on each call form, the NaN path, and the croaks that
#     free a half-built matrix.
unless ($INC{'Devel/Cover.pm'}) {
	my @x  = @{ $VEC{'kendalltau Kendall 1970'}[1] };
	my @y  = @{ $VEC{'kendalltau Kendall 1970'}[2] };
	my @xn = (1, 2, undef, 4, 5, 6);
	my @yn = (2, 1, 4, 3, 6, 5);
	my $L  = $DATA{longley};
	my $A  = cols($L, 0, 2);
	my $B  = cols($L, 3, 6);
	my $W  = $DATA{swM};
	for my $m (@METHODS) {
		no_leaks_ok { cor(\@x, \@y, $m) } "C10 no leaks: vector $m";
		no_leaks_ok { cor(\@xn, \@yn, $m) } "C10 no leaks: vector with NA $m";
		no_leaks_ok { cor($L, undef, $m) } "C10 no leaks: matrix $m";
		no_leaks_ok { cor($W, undef, $m) } "C10 no leaks: matrix with NA $m";
		no_leaks_ok { cor($A, $B, $m) } "C10 no leaks: cross matrix $m";
	}
	no_leaks_ok { eval { cor([ 1, 2, 3 ], 'spearman') } } 'C10 no leaks: croak, method in y slot';
	no_leaks_ok { eval { cor([ 1, 1, 1 ], [ 1, 2, 3 ]) } } 'C10 no leaks: croak, constant vector';
	no_leaks_ok { eval { cor([ [ 1, 7 ], [ 2, 7 ], [ 3, 7 ] ]) } } 'C10 no leaks: croak, constant x column';
	no_leaks_ok { eval { cor($A, [ map { [ 4 ] } 0 .. $#$A ]) } }
		'C10 no leaks: croak, constant y column after x is built';
	no_leaks_ok { eval { cor([ [ 1, 2 ], [ 2, 1 ], 5 ]) } } 'C10 no leaks: croak, bad x row';
	no_leaks_ok { eval { cor($A, [ (map { [$_] } 1 .. $#$A), 'z' ]) } } 'C10 no leaks: croak, bad y row';
}

done_testing();

# The frozen reference tables.  They live in a BEGIN block at the foot of the
# file so that the tests above read as tests; regenerate them with the two
# scripts named in the header and paste each between its own markers.
BEGIN {
## BEGIN GENERATED (R) -- Rscript t/cor.R.scipy.R
our %DATA = (
	'longley' => [[83, 234.289, 235.6, 159, 107.608, 1947, 60.323], [88.5, 259.426, 232.5, 145.6, 108.632, 1948, 61.122], [88.2, 258.054, 368.2, 161.6, 109.773, 1949, 60.171], [89.5, 284.599, 335.1, 165, 110.929, 1950, 61.187], [96.2, 328.975, 209.9, 309.9, 112.075, 1951, 63.221], [98.1, 346.999, 193.2, 359.4, 113.27, 1952, 63.639], [99, 365.385, 187, 354.7, 115.094, 1953, 64.989], [100, 363.112, 357.8, 335, 116.219, 1954, 63.761], [101.2, 397.469, 290.4, 304.8, 117.388, 1955, 66.019], [104.6, 419.18, 282.2, 285.7, 118.734, 1956, 67.857], [108.4, 442.769, 293.6, 279.8, 120.445, 1957, 68.169], [110.8, 444.546, 468.1, 263.7, 121.95, 1958, 66.513], [112.6, 482.704, 381.3, 255.2, 123.366, 1959, 68.655], [114.2, 502.601, 393.1, 251.4, 125.368, 1960, 69.564], [115.7, 518.173, 480.6, 257.2, 127.852, 1961, 69.331], [116.9, 554.894, 400.7, 282.7, 130.081, 1962, 70.551]],
	'swiss' => [[80.2, 17, 15, 12, 9.96, 22.2], [83.1, 45.1, 6, 9, 84.84, 22.2], [92.5, 39.7, 5, 5, 93.4, 20.2], [85.8, 36.5, 12, 7, 33.77, 20.3], [76.9, 43.5, 17, 15, 5.16, 20.6], [76.1, 35.3, 9, 7, 90.57, 26.6], [83.8, 70.2, 16, 7, 92.85, 23.6], [92.4, 67.8, 14, 8, 97.16, 24.9], [82.4, 53.3, 12, 7, 97.67, 21], [82.9, 45.2, 16, 13, 91.38, 24.4], [87.1, 64.5, 14, 6, 98.61, 24.5], [64.1, 62, 21, 12, 8.52, 16.5], [66.9, 67.5, 14, 7, 2.27, 19.1], [68.9, 60.7, 19, 12, 4.43, 22.7], [61.7, 69.3, 22, 5, 2.82, 18.7], [68.3, 72.6, 18, 2, 24.2, 21.2], [71.7, 34, 17, 8, 3.3, 20], [55.7, 19.4, 26, 28, 12.11, 20.2], [54.3, 15.2, 31, 20, 2.15, 10.8], [65.1, 73, 19, 9, 2.84, 20], [65.5, 59.8, 22, 10, 5.23, 18], [65, 55.1, 14, 3, 4.52, 22.4], [56.6, 50.9, 22, 12, 15.14, 16.7], [57.4, 54.1, 20, 6, 4.2, 15.3], [72.5, 71.2, 12, 1, 2.4, 21], [74.2, 58.1, 14, 8, 5.23, 23.8], [72, 63.5, 6, 3, 2.56, 18], [60.5, 60.8, 16, 10, 7.72, 16.3], [58.3, 26.8, 25, 19, 18.46, 20.9], [65.4, 49.5, 15, 8, 6.1, 22.5], [75.5, 85.9, 3, 2, 99.71, 15.1], [69.3, 84.9, 7, 6, 99.68, 19.8], [77.3, 89.7, 5, 2, 100, 18.3], [70.5, 78.2, 12, 6, 98.96, 19.4], [79.4, 64.9, 7, 3, 98.22, 20.2], [65, 75.9, 9, 9, 99.06, 17.8], [92.2, 84.6, 3, 3, 99.46, 16.3], [79.3, 63.1, 13, 13, 96.83, 18.1], [70.4, 38.4, 26, 12, 5.62, 20.3], [65.7, 7.7, 29, 11, 13.79, 20.5], [72.7, 16.7, 22, 13, 11.22, 18.9], [64.4, 17.6, 35, 32, 16.92, 23], [77.6, 37.6, 15, 7, 4.97, 20], [67.6, 18.7, 25, 7, 8.65, 19.5], [35, 1.2, 37, 53, 42.34, 18], [44.7, 46.6, 16, 29, 50.43, 18.2], [42.8, 27.7, 22, 29, 58.33, 19.3]],
	'swM' => [[80.2, undef, 15, 12, 9.96, 22.2], [83.1, 45.1, 6, 9, 84.84, 22.2], [92.5, 39.7, 5, 5, 93.4, 20.2], [85.8, 36.5, 12, 7, 33.77, 20.3], [76.9, 43.5, 17, 15, 5.16, 20.6], [76.1, 35.3, 9, 7, 90.57, 26.6], [83.8, 70.2, undef, 7, 92.85, 23.6], [92.4, 67.8, 14, 8, 97.16, 24.9], [82.4, 53.3, 12, 7, 97.67, 21], [82.9, 45.2, 16, 13, 91.38, 24.4], [87.1, 64.5, 14, 6, 98.61, 24.5], [64.1, 62, 21, 12, 8.52, 16.5], [66.9, 67.5, 14, 7, 2.27, 19.1], [68.9, 60.7, 19, 12, 4.43, 22.7], [61.7, 69.3, 22, 5, 2.82, 18.7], [68.3, 72.6, 18, 2, 24.2, 21.2], [71.7, 34, 17, 8, 3.3, 20], [55.7, 19.4, 26, 28, 12.11, 20.2], [54.3, 15.2, 31, 20, 2.15, 10.8], [65.1, 73, 19, 9, 2.84, 20], [65.5, 59.8, 22, 10, 5.23, 18], [65, 55.1, 14, 3, 4.52, 22.4], [56.6, 50.9, 22, 12, 15.14, 16.7], [57.4, 54.1, 20, 6, 4.2, 15.3], [72.5, 71.2, 12, 1, undef, 21], [74.2, 58.1, 14, 8, 5.23, 23.8], [72, 63.5, 6, 3, 2.56, 18], [60.5, 60.8, 16, 10, 7.72, 16.3], [58.3, 26.8, 25, 19, 18.46, 20.9], [65.4, 49.5, 15, 8, 6.1, 22.5], [75.5, 85.9, 3, 2, 99.71, 15.1], [69.3, 84.9, 7, 6, 99.68, 19.8], [77.3, 89.7, 5, 2, 100, 18.3], [70.5, 78.2, 12, 6, 98.96, 19.4], [79.4, 64.9, 7, 3, 98.22, 20.2], [65, 75.9, 9, 9, 99.06, 17.8], [92.2, 84.6, 3, 3, 99.46, 16.3], [79.3, 63.1, 13, 13, 96.83, 18.1], [70.4, 38.4, 26, 12, 5.62, 20.3], [65.7, 7.7, 29, 11, 13.79, 20.5], [72.7, 16.7, 22, 13, 11.22, 18.9], [64.4, 17.6, 35, 32, 16.92, 23], [77.6, 37.6, 15, 7, 4.97, 20], [67.6, 18.7, 25, 7, 8.65, 19.5], [35, 1.2, 37, 53, 42.34, 18], [44.7, 46.6, 16, 29, 50.43, 18.2], [42.8, 27.7, 22, 29, 58.33, 19.3]],
	'swM complete' => [[83.1, 45.1, 6, 9, 84.84, 22.2], [92.5, 39.7, 5, 5, 93.4, 20.2], [85.8, 36.5, 12, 7, 33.77, 20.3], [76.9, 43.5, 17, 15, 5.16, 20.6], [76.1, 35.3, 9, 7, 90.57, 26.6], [92.4, 67.8, 14, 8, 97.16, 24.9], [82.4, 53.3, 12, 7, 97.67, 21], [82.9, 45.2, 16, 13, 91.38, 24.4], [87.1, 64.5, 14, 6, 98.61, 24.5], [64.1, 62, 21, 12, 8.52, 16.5], [66.9, 67.5, 14, 7, 2.27, 19.1], [68.9, 60.7, 19, 12, 4.43, 22.7], [61.7, 69.3, 22, 5, 2.82, 18.7], [68.3, 72.6, 18, 2, 24.2, 21.2], [71.7, 34, 17, 8, 3.3, 20], [55.7, 19.4, 26, 28, 12.11, 20.2], [54.3, 15.2, 31, 20, 2.15, 10.8], [65.1, 73, 19, 9, 2.84, 20], [65.5, 59.8, 22, 10, 5.23, 18], [65, 55.1, 14, 3, 4.52, 22.4], [56.6, 50.9, 22, 12, 15.14, 16.7], [57.4, 54.1, 20, 6, 4.2, 15.3], [74.2, 58.1, 14, 8, 5.23, 23.8], [72, 63.5, 6, 3, 2.56, 18], [60.5, 60.8, 16, 10, 7.72, 16.3], [58.3, 26.8, 25, 19, 18.46, 20.9], [65.4, 49.5, 15, 8, 6.1, 22.5], [75.5, 85.9, 3, 2, 99.71, 15.1], [69.3, 84.9, 7, 6, 99.68, 19.8], [77.3, 89.7, 5, 2, 100, 18.3], [70.5, 78.2, 12, 6, 98.96, 19.4], [79.4, 64.9, 7, 3, 98.22, 20.2], [65, 75.9, 9, 9, 99.06, 17.8], [92.2, 84.6, 3, 3, 99.46, 16.3], [79.3, 63.1, 13, 13, 96.83, 18.1], [70.4, 38.4, 26, 12, 5.62, 20.3], [65.7, 7.7, 29, 11, 13.79, 20.5], [72.7, 16.7, 22, 13, 11.22, 18.9], [64.4, 17.6, 35, 32, 16.92, 23], [77.6, 37.6, 15, 7, 4.97, 20], [67.6, 18.7, 25, 7, 8.65, 19.5], [35, 1.2, 37, 53, 42.34, 18], [44.7, 46.6, 16, 29, 50.43, 18.2], [42.8, 27.7, 22, 29, 58.33, 19.3]],
);
our @VEC = (
	[ 'reg-1a zz self', [-1.30167, -0.4957, -1.46749, 0.46927], [-1.30167, -0.4957, -1.46749, 0.46927], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'reg-1b scalar', [1, 2, 3], [3, 4, 6], { pearson => 0.98198050606196563, spearman => 1, kendall => 1 } ],
	[ 'PR#7116 vectors', [1, 2], [1, 2], { pearson => 0.99999999999999978, spearman => 0.99999999999999978, kendall => 0.99999999999999978 } ],
	[ 'cor.Rd 1:10 vs 2:11', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [2, 3, 4, 5, 6, 7, 8, 9, 10, 11], { pearson => 0.99999999999999978, spearman => 0.99999999999999978, kendall => 1 } ],
	[ 'PR#14488 everything', [0.2655086631421, 0.37212389963679016, undef, 0.9082077899947762, 0.2016819310374558, 0.8983896849676967, 0.9446752686053514, 0.6607977924868464, 0.6291140438988805, 0.061786270467564464], [0.20597457489930093, 0.17655675252899528, 0.6870228466577828, 0.384103718213737, undef, 0.49769924208521843, 0.7176185082644224, 0.9919060948304832, 0.3800351794343442, 0.7774452213197947], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'PR#14488 complete', [0.2655086631421, 0.37212389963679016, 0.9082077899947762, 0.8983896849676967, 0.9446752686053514, 0.6607977924868464, 0.6291140438988805, 0.061786270467564464], [0.20597457489930093, 0.17655675252899528, 0.384103718213737, 0.49769924208521843, 0.7176185082644224, 0.9919060948304832, 0.3800351794343442, 0.7774452213197947], { pearson => 0.13324218974612512, spearman => 0.23809523809523814, kendall => 0.21428571428571427 } ],
	[ 'Wilkinson X X', [1, 2, 3, 4, 5, 6, 7, 8, 9], [1, 2, 3, 4, 5, 6, 7, 8, 9], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson X BIG', [1, 2, 3, 4, 5, 6, 7, 8, 9], [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson X LITTLE', [1, 2, 3, 4, 5, 6, 7, 8, 9], [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson X HUGE', [1, 2, 3, 4, 5, 6, 7, 8, 9], [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson X TINY', [1, 2, 3, 4, 5, 6, 7, 8, 9], [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson X ROUND', [1, 2, 3, 4, 5, 6, 7, 8, 9], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson BIG BIG', [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson BIG LITTLE', [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson BIG HUGE', [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson BIG TINY', [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson BIG ROUND', [99999991, 99999992, 99999993, 99999994, 99999995, 99999996, 99999997, 99999998, 99999999], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson LITTLE LITTLE', [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson LITTLE HUGE', [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson LITTLE TINY', [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson LITTLE ROUND', [0.99999991, 0.99999992, 0.99999993, 0.99999994, 0.99999995, 0.99999996, 0.99999997, 0.99999998, 0.99999999], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson HUGE HUGE', [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson HUGE TINY', [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson HUGE ROUND', [1000000000000, 2000000000000, 3000000000000, 4000000000000, 5000000000000, 6000000000000, 7000000000000, 8000000000000, 9000000000000], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson TINY TINY', [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson TINY ROUND', [1e-12, 2e-12, 3e-12, 4e-12, 5e-12, 6e-12, 7e-12, 8e-12, 9e-12], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'Wilkinson ROUND ROUND', [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], [0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'pearsonr arange3 self', [0, 1, 2], [0, 1, 2], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'pearsonr arange3 neg', [0, 1, 2], [0, -1, -2], { pearson => -1, spearman => -1, kendall => -1 } ],
	[ 'pearsonr basic', [-1, 0, 1], [0, 0, 3], { pearson => 0.86602540378443871, spearman => 0.86602540378443871, kendall => 0.81649658092772615 } ],
	[ 'pearsonr very small', [0.004434375, 0.004756007, 0.003911996, 0.0038005, 0.003409971], [2.48e-188, 7.41e-181, 4.09e-208, 2.08e-223, 2.66e-245], { pearson => 0.72729305407504519, spearman => 0.99999999999999978, kendall => 0.99999999999999978 } ],
	[ 'pearsonr very large', [0, 0, 0, 1e+90, 1e+90, 1e+90, 1e+90], [0, 1e+90, 2e+90, 3e+90, 4e+90, 4.9999999999999995e+90, 6e+90], { pearson => 0.86602540378443871, spearman => 0.8660254037844386, kendall => 0.75592894601845451 } ],
	[ 'pearsonr extremely large', [2.3e+200, 4.5e+200, 6.7e+200, 8e+200], [1.2e+199, 5.5e+200, 3.3e+201, 1e+200], { pearson => undef, spearman => 0.40000000000000002, kendall => 0.33333333333333337 } ],
	[ 'pearsonr length two pos', [1, 2], [3, 5], { pearson => 0.99999999999999978, spearman => 0.99999999999999978, kendall => 0.99999999999999978 } ],
	[ 'pearsonr length two neg', [2, 1], [3, 5], { pearson => -0.99999999999999978, spearman => -0.99999999999999978, kendall => -0.99999999999999978 } ],
	[ 'pearsonr basic example +', [1, 2, 3, 4], [0, 1, 0.5, 1], { pearson => 0.67419986246324215, spearman => 0.63245553203367588, kendall => 0.54772255750516607 } ],
	[ 'pearsonr basic example -', [1, 2, 3, 4], [-0, -1, -0.5, -1], { pearson => -0.67419986246324215, spearman => -0.63245553203367588, kendall => -0.54772255750516607 } ],
	[ 'pearsonr gh17795', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, -1, -2, -3, -4, -5, -6, -7, -8, -9], { pearson => -0.99999999999999978, spearman => -0.99999999999999978, kendall => -1 } ],
	[ 'pearsonr length3 exact -1', [1, 2, 3], [5, -4, -13], { pearson => -1, spearman => -1, kendall => -1 } ],
	[ 'mstats pearsonr misaligned', [1, 4, 5, 6], [9, 6, 5, 9], { pearson => -0.29939247542604785, spearman => -0.10540925533894598, kendall => -0.18257418583505536 } ],
	[ 'spearmanr vs R', [1, 2, 3, 4, 5], [5, 6, 7, 8, 7], { pearson => 0.83205029433784361, spearman => 0.82078268166812329, kendall => 0.73786478737262184 } ],
	[ 'spearmanr 1d_vs_2d', [1, 2, 3, 4, 5, 6], [1, 2, 3, 4, 6, 5], { pearson => 0.94285714285714284, spearman => 0.94285714285714284, kendall => 0.8666666666666667 } ],
	[ 'spearmanr 1d_vs_2d nans', [1, undef, 3, 4, 5, 6], [1, 2, 3, 4, 6, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'spearmanr corr_1', [1, 1, 2], [1, 1, 2], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'spearmanr tie1', [1, 2, 3, 4], [1, 2, 2, 3], { pearson => 0.94868329805051377, spearman => 0.94868329805051388, kendall => 0.9128709291752769 } ],
	[ 'spearmanr tie1 ranks', [1, 2, 3, 4], [1, 2.5, 2.5, 4], { pearson => 0.94868329805051388, spearman => 0.94868329805051388, kendall => 0.9128709291752769 } ],
	[ 'spearmanr tie2', [1, 2, 2.5, 2], [1, 3, 2.5, 4], { pearson => 0.66226617853252201, spearman => 0.31622776601683794, kendall => 0.18257418583505536 } ],
	[ 'spearmanr tie2 nan', [1, 2, 2.5, 2, undef], [1, 3, 2.5, 4, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'spearmanr 3cols x1 x3', [0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 5, 4], { pearson => 0.94285714285714284, spearman => 0.94285714285714284, kendall => 0.8666666666666667 } ],
	[ 'spearmanr nan_policy self', [0, 1, 2, 3, 4, 5, 6, 7, 8, undef], [0, 1, 2, 3, 4, 5, 6, 7, 8, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'spearmanr alternative nan', [1, 2, 3, 4, 5, undef], [5, 6, 7, 8, 7, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'spearmanr gh6061', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 650, 651, 652, 653, 654, 655, 656, 657, 658, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 670, 671, 672, 673, 674, 675, 676, 677, 678, 679, 680, 681, 682, 683, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 696, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 767, 768, 769, 770, 771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 783, 784, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 857, 858, 859, 860, 861, 862, 863, 864, 865, 866, 867, 868, 869, 870, 871, 872, 873, 874, 875, 876, 877, 878, 879, 880, 881, 882, 883, 884, 885, 886, 887, 888, 889, 890, 891, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 903, 904, 905, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 947, 948, 949, 950, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962, 963, 964, 965, 966, 967, 968, 969, 970, 971, 972, 973, 974, 975, 976, 977, 978, 979, 980, 981, 982, 983, 984, 985, 986, 987, 988, 989, 990, 991, 992, 993, 994, 995, 996, 997, 998, 999, 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047, 1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1120, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, 1129, 1130, 1131, 1132, 1133, 1134, 1135, 1136, 1137, 1138, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1146, 1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167, 1168, 1169, 1170, 1171, 1172, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1180, 1181, 1182, 1183, 1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223, 1224, 1225, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233, 1234, 1235, 1236, 1237, 1238, 1239, 1240, 1241, 1242, 1243, 1244, 1245, 1246, 1247, 1248, 1249, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257, 1258, 1259, 1260, 1261, 1262, 1263, 1264, 1265, 1266, 1267, 1268, 1269, 1270, 1271, 1272, 1273, 1274, 1275, 1276, 1277, 1278, 1279, 1280, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 1292, 1293, 1294, 1295, 1296, 1297, 1298, 1299, 1300, 1301, 1302, 1303, 1304, 1305, 1306, 1307, 1308, 1309, 1310, 1311, 1312, 1313, 1314, 1315, 1316, 1317, 1318, 1319, 1320, 1321, 1322, 1323, 1324, 1325, 1326, 1327, 1328, 1329, 1330, 1331, 1332, 1333, 1334, 1335, 1336, 1337, 1338, 1339, 1340, 1341, 1342, 1343, 1344, 1345, 1346, 1347, 1348, 1349, 1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1361, 1362, 1363, 1364, 1365, 1366, 1367, 1368, 1369, 1370, 1371, 1372, 1373, 1374, 1375, 1376, 1377, 1378, 1379, 1380, 1381, 1382, 1383, 1384, 1385, 1386, 1387, 1388, 1389, 1390, 1391, 1392, 1393, 1394, 1395, 1396, 1397, 1398, 1399, 1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415, 1416, 1417, 1418, 1419, 1420, 1421, 1422, 1423, 1424, 1425, 1426, 1427, 1428, 1429, 1430, 1431, 1432, 1433, 1434, 1435, 1436, 1437, 1438, 1439, 1440, 1441, 1442, 1443, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 1458, 1459, 1460, 1461, 1462, 1463, 1464, 1465, 1466, 1467, 1468, 1469, 1470, 1471, 1472, 1473, 1474, 1475, 1476, 1477, 1478, 1479, 1480, 1481, 1482, 1483, 1484, 1485, 1486, 1487, 1488, 1489, 1490, 1491, 1492, 1493, 1494, 1495, 1496, 1497, 1498, 1499, 1500, 1501, 1502, 1503, 1504, 1505, 1506, 1507, 1508, 1509, 1510, 1511, 1512, 1513, 1514, 1515, 1516, 1517, 1518, 1519, 1520, 1521, 1522, 1523, 1524, 1525, 1526, 1527, 1528, 1529, 1530, 1531, 1532, 1533, 1534, 1535, 1536, 1537, 1538, 1539, 1540, 1541, 1542, 1543, 1544, 1545, 1546, 1547, 1548, 1549, 1550, 1551, 1552, 1553, 1554, 1555, 1556, 1557, 1558, 1559, 1560, 1561, 1562, 1563, 1564, 1565, 1566, 1567, 1568, 1569, 1570, 1571, 1572, 1573, 1574, 1575, 1576, 1577, 1578, 1579, 1580, 1581, 1582, 1583, 1584, 1585, 1586, 1587, 1588, 1589, 1590, 1591, 1592, 1593, 1594, 1595, 1596, 1597, 1598, 1599, 1600, 1601, 1602, 1603, 1604, 1605, 1606, 1607, 1608, 1609, 1610, 1611, 1612, 1613, 1614, 1615, 1616, 1617, 1618, 1619, 1620, 1621, 1622, 1623, 1624, 1625, 1626, 1627, 1628, 1629, 1630, 1631, 1632, 1633, 1634, 1635, 1636, 1637, 1638, 1639, 1640, 1641, 1642, 1643, 1644, 1645, 1646, 1647, 1648, 1649, 1650, 1651, 1652, 1653, 1654, 1655, 1656, 1657, 1658, 1659, 1660, 1661, 1662, 1663, 1664, 1665, 1666, 1667, 1668, 1669, 1670, 1671, 1672, 1673, 1674, 1675, 1676, 1677, 1678, 1679, 1680, 1681, 1682, 1683, 1684, 1685, 1686, 1687, 1688, 1689, 1690, 1691, 1692, 1693, 1694, 1695, 1696, 1697, 1698, 1699, 1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712, 1713, 1714, 1715, 1716, 1717, 1718, 1719, 1720, 1721, 1722, 1723, 1724, 1725, 1726, 1727, 1728, 1729, 1730, 1731, 1732, 1733, 1734, 1735, 1736, 1737, 1738, 1739, 1740, 1741, 1742, 1743, 1744, 1745, 1746, 1747, 1748, 1749, 1750, 1751, 1752, 1753, 1754, 1755, 1756, 1757, 1758, 1759, 1760, 1761, 1762, 1763, 1764, 1765, 1766, 1767, 1768, 1769, 1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789, 1790, 1791, 1792, 1793, 1794, 1795, 1796, 1797, 1798, 1799, 1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 1810, 1811, 1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819, 1820, 1821, 1822, 1823, 1824, 1825, 1826, 1827, 1828, 1829, 1830, 1831, 1832, 1833, 1834, 1835, 1836, 1837, 1838, 1839, 1840, 1841, 1842, 1843, 1844, 1845, 1846, 1847, 1848, 1849, 1850, 1851, 1852, 1853, 1854, 1855, 1856, 1857, 1858, 1859, 1860, 1861, 1862, 1863, 1864, 1865, 1866, 1867, 1868, 1869, 1870, 1871, 1872, 1873, 1874, 1875, 1876, 1877, 1878, 1879, 1880, 1881, 1882, 1883, 1884, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898, 1899, 1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1910, 1911, 1912, 1913, 1914, 1915, 1916, 1917, 1918, 1919, 1920, 1921, 1922, 1923, 1924, 1925, 1926, 1927, 1928, 1929, 1930, 1931, 1932, 1933, 1934, 1935, 1936, 1937, 1938, 1939, 1940, 1941, 1942, 1943, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999], [9, 1, 2, 3, 4, 5, 6, 7, 8, 0, 434, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 10, 1509, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 524, 525, 526, 527, 528, 529, 530, 531, 532, 533, 534, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 650, 651, 652, 653, 654, 655, 656, 657, 658, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 670, 671, 672, 673, 674, 675, 676, 677, 678, 679, 680, 681, 682, 683, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 696, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 767, 768, 769, 770, 771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 783, 784, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 847, 848, 849, 850, 851, 852, 853, 854, 855, 856, 857, 858, 859, 860, 861, 862, 863, 864, 865, 866, 867, 868, 869, 870, 871, 872, 873, 874, 875, 876, 877, 878, 879, 880, 881, 882, 883, 884, 885, 886, 887, 888, 889, 890, 891, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 903, 904, 905, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 947, 948, 949, 950, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962, 963, 964, 965, 966, 967, 968, 969, 970, 971, 972, 973, 974, 975, 976, 977, 978, 979, 980, 981, 982, 983, 984, 985, 986, 987, 988, 989, 990, 991, 992, 993, 994, 995, 996, 997, 998, 999, 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1025, 1026, 1027, 1028, 1029, 1030, 1031, 1032, 1033, 1034, 1035, 1036, 1037, 1038, 1039, 1040, 1041, 1042, 1043, 1044, 1045, 1046, 1047, 1048, 1049, 1050, 1051, 1052, 1053, 1054, 1055, 1056, 1057, 1058, 1059, 1060, 1061, 1062, 1063, 1064, 1065, 1066, 1067, 1068, 1069, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1115, 1116, 1117, 1118, 1119, 1120, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, 1129, 1130, 1131, 1132, 1133, 1134, 1135, 1136, 1137, 1138, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1146, 1147, 1148, 1149, 1150, 1151, 1152, 1153, 1154, 1155, 1156, 1157, 1158, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167, 1168, 1169, 1170, 1171, 1172, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1180, 1181, 1182, 1183, 1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1203, 1204, 1205, 1206, 1207, 1208, 1209, 1210, 1211, 1212, 1213, 1214, 1215, 1216, 1217, 1218, 1219, 1220, 1221, 1222, 1223, 1224, 1225, 1226, 1227, 1228, 1229, 1230, 1231, 1232, 1233, 1234, 1235, 1236, 1237, 1238, 1239, 1240, 1241, 1242, 1243, 1244, 1245, 1246, 1247, 1248, 1249, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257, 1258, 1259, 1260, 1261, 1262, 1263, 1264, 1265, 1266, 1267, 1268, 1269, 1270, 1271, 1272, 1273, 1274, 1275, 1276, 1277, 1278, 1279, 1280, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 1292, 1293, 1294, 1295, 1296, 1297, 1298, 1299, 1300, 1301, 1302, 1303, 1304, 1305, 1306, 1307, 1308, 1309, 1310, 1311, 1312, 1313, 1314, 1315, 1316, 1317, 1318, 1319, 1320, 1321, 1322, 1323, 1324, 1325, 1326, 1327, 1328, 1329, 1330, 1331, 1332, 1333, 1334, 1335, 1336, 1337, 1338, 1339, 1340, 1341, 1342, 1343, 1344, 1345, 1346, 1347, 1348, 1349, 1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1361, 1362, 1363, 1364, 1365, 1366, 1367, 1368, 1369, 1370, 1371, 1372, 1373, 1374, 1375, 1376, 1377, 1378, 1379, 1380, 1381, 1382, 1383, 1384, 1385, 1386, 1387, 1388, 1389, 1390, 1391, 1392, 1393, 1394, 1395, 1396, 1397, 1398, 1399, 1400, 1401, 1402, 1403, 1404, 1405, 1406, 1407, 1408, 1409, 1410, 1411, 1412, 1413, 1414, 1415, 1416, 1417, 1418, 1419, 1420, 1421, 1422, 1423, 1424, 1425, 1426, 1427, 1428, 1429, 1430, 1431, 1432, 1433, 1434, 1435, 1436, 1437, 1438, 1439, 1440, 1441, 1442, 1443, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 1458, 1459, 1460, 1461, 1462, 1463, 1464, 1465, 1466, 1467, 1468, 1469, 1470, 1471, 1472, 1473, 1474, 1475, 1476, 1477, 1478, 1479, 1480, 1481, 1482, 1483, 1484, 1485, 1486, 1487, 1488, 1489, 1490, 1491, 1492, 1493, 1494, 1495, 1496, 1497, 1498, 1499, 1500, 1501, 1502, 1503, 1504, 1505, 1506, 1507, 1508, 435, 1510, 1511, 1512, 1513, 1514, 1515, 1516, 1517, 1518, 1519, 1520, 1521, 1522, 1523, 1524, 1525, 1526, 1527, 1528, 1529, 1530, 1531, 1532, 1533, 1534, 1535, 1536, 1537, 1538, 1539, 1540, 1541, 1542, 1543, 1544, 1545, 1546, 1547, 1548, 1549, 1550, 1551, 1552, 1553, 1554, 1555, 1556, 1557, 1558, 1559, 1560, 1561, 1562, 1563, 1564, 1565, 1566, 1567, 1568, 1569, 1570, 1571, 1572, 1573, 1574, 1575, 1576, 1577, 1578, 1579, 1580, 1581, 1582, 1583, 1584, 1585, 1586, 1587, 1588, 1589, 1590, 1591, 1592, 1593, 1594, 1595, 1596, 1597, 1598, 1599, 1600, 1601, 1602, 1603, 1604, 1605, 1606, 1607, 1608, 1609, 1610, 1611, 1612, 1613, 1614, 1615, 1616, 1617, 1618, 1619, 1620, 1621, 1622, 1623, 1624, 1625, 1626, 1627, 1628, 1629, 1630, 1631, 1632, 1633, 1634, 1635, 1636, 1637, 1638, 1639, 1640, 1641, 1642, 1643, 1644, 1645, 1646, 1647, 1648, 1649, 1650, 1651, 1652, 1653, 1654, 1655, 1656, 1657, 1658, 1659, 1660, 1661, 1662, 1663, 1664, 1665, 1666, 1667, 1668, 1669, 1670, 1671, 1672, 1673, 1674, 1675, 1676, 1677, 1678, 1679, 1680, 1681, 1682, 1683, 1684, 1685, 1686, 1687, 1688, 1689, 1690, 1691, 1692, 1693, 1694, 1695, 1696, 1697, 1698, 1699, 1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712, 1713, 1714, 1715, 1716, 1717, 1718, 1719, 1720, 1721, 1722, 1723, 1724, 1725, 1726, 1727, 1728, 1729, 1730, 1731, 1732, 1733, 1734, 1735, 1736, 1737, 1738, 1739, 1740, 1741, 1742, 1743, 1744, 1745, 1746, 1747, 1748, 1749, 1750, 1751, 1752, 1753, 1754, 1755, 1756, 1757, 1758, 1759, 1760, 1761, 1762, 1763, 1764, 1765, 1766, 1767, 1768, 1769, 1770, 1771, 1772, 1773, 1774, 1775, 1776, 1777, 1778, 1779, 1780, 1781, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789, 1790, 1791, 1792, 1793, 1794, 1795, 1796, 1797, 1798, 1799, 1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 1810, 1811, 1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819, 1820, 1821, 1822, 1823, 1824, 1825, 1826, 1827, 1828, 1829, 1830, 1831, 1832, 1833, 1834, 1835, 1836, 1837, 1838, 1839, 1840, 1841, 1842, 1843, 1844, 1845, 1846, 1847, 1848, 1849, 1850, 1851, 1852, 1853, 1854, 1855, 1856, 1857, 1858, 1859, 1860, 1861, 1862, 1863, 1864, 1865, 1866, 1867, 1868, 1869, 1870, 1871, 1872, 1873, 1874, 1875, 1876, 1877, 1878, 1879, 1880, 1881, 1882, 1883, 1884, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898, 1899, 1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1910, 1911, 1912, 1913, 1914, 1915, 1916, 1917, 1918, 1919, 1920, 1921, 1922, 1923, 1924, 1925, 1926, 1927, 1928, 1929, 1930, 1931, 1932, 1933, 1934, 1935, 1936, 1937, 1938, 1939, 1940, 1941, 1942, 1943, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1953, 1954, 1955, 1956, 1957, 1958, 1959, 1960, 1961, 1962, 1963, 1964, 1965, 1966, 1967, 1968, 1969, 1970, 1971, 1972, 1973, 1974, 1975, 1976, 1977, 1978, 1979, 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999], { pearson => 0.998, spearman => 0.998, kendall => 0.99698749374687345 } ],
	[ 'spearmanrho vs R', [0.11027287231363914, 0.8154770102474279, 0.7073943466920335, 0.6651317324378386, 0.6905752850115503, 0.06115250587536558, 0.5209906494474178, 0.3155763519785274, 0.18405731803625924, 0.8613557911541495], [0.8402081904493103, 0.5946972833914318, 0.23481606164114155, 0.49754786197715384, 0.9146460831206026, 0.5848057749217579, 0.7620801065573549, 0.31410063302647495, 0.7935620302236199, 0.5423085761365468], { pearson => -0.24242698951554323, spearman => -0.27272727272727271, kendall => -0.20000000000000001 } ],
	[ 'spearmanrho vs R exact', [0.11027287231363914, 0.8154770102474279, 0.7073943466920335, 0.6651317324378386, 0.6905752850115503, 0.06115250587536558], [0.5209906494474178, 0.3155763519785274, 0.18405731803625924, 0.8613557911541495, 0.8402081904493103, 0.5946972833914318], { pearson => -0.11388476109322818, spearman => -0.48571428571428571, kendall => -0.33333333333333331 } ],
	[ 'mstats spearmanr 4', [5.05, 6.75, 3.21, 2.66], [1.65, 2.64, 2.64, 6.95], { pearson => -0.62079672927347374, spearman => -0.63245553203367588, kendall => -0.54772255750516607 } ],
	[ 'mstats spearmanr 4 nan', [5.05, 6.75, 3.21, 2.66, undef], [1.65, 2.64, 2.64, 6.95, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'mstats spearmanr 15', [2, 47.4, 42, 10.8, 60.1, 1.7, 64, 63.1, 1, 1.4, 7.9, 0.3, 3.9, 0.3, 6.7], [22.6, 8.3, 44.4, 11.9, 24.6, 0.6, 5.7, 41.6, 0, 0.6, 6.7, 3.8, 1, 1.2, 1.4], { pearson => 0.61694150627876054, spearman => 0.68872987477638636, kendall => 0.50961538461538469 } ],
	[ 'mstats spearmanr 15 nan', [2, 47.4, 42, 10.8, 60.1, 1.7, 64, 63.1, 1, 1.4, 7.9, 0.3, 3.9, 0.3, 6.7, undef], [22.6, 8.3, 44.4, 11.9, 24.6, 0.6, 5.7, 41.6, 0, 0.6, 6.7, 3.8, 1, 1.2, 1.4, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'kendalltau no ties 1', [5, 2, 1, 3, 6, 4, 7, 8], [5, 2, 6, 3, 1, 8, 7, 4], { pearson => 0.023809523809523812, spearman => 0.023809523809523812, kendall => 0 } ],
	[ 'kendalltau no ties 2', [0, 5, 2, 1, 3, 6, 4, 7, 8], [5, 2, 0, 6, 3, 1, 8, 7, 4], { pearson => 0, spearman => 0, kendall => 0 } ],
	[ 'kendalltau no ties 3', [5, 2, 1, 3, 6, 4, 7], [5, 2, 6, 3, 1, 7, 4], { pearson => -0.21428571428571422, spearman => -0.21428571428571422, kendall => -0.14285714285714285 } ],
	[ 'kendalltau no ties 4', [2, 1, 3, 6, 4, 7, 8], [2, 6, 3, 1, 8, 7, 4], { pearson => 0.017123287671232872, spearman => 0.10714285714285711, kendall => 0.047619047619047616 } ],
	[ 'kendalltau no ties 5', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], { pearson => 0.99999999999999978, spearman => 0.99999999999999978, kendall => 1 } ],
	[ 'kendalltau no ties 6', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, 2, 1, 3, 4, 5, 6, 7, 8, 9], { pearson => 0.98787878787878769, spearman => 0.98787878787878769, kendall => 0.9555555555555556 } ],
	[ 'kendalltau no ties 7', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [0, 2, 1, 3, 4, 6, 5, 7, 8, 9], { pearson => 0.9757575757575756, spearman => 0.9757575757575756, kendall => 0.91111111111111109 } ],
	[ 'kendalltau no ties 8', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [9, 8, 7, 6, 5, 4, 3, 2, 1, 0], { pearson => -0.99999999999999978, spearman => -0.99999999999999978, kendall => -1 } ],
	[ 'kendalltau no ties 9', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [9, 7, 8, 6, 5, 4, 3, 2, 1, 0], { pearson => -0.98787878787878769, spearman => -0.98787878787878769, kendall => -0.9555555555555556 } ],
	[ 'kendalltau no ties 10', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], [9, 7, 8, 6, 5, 3, 4, 2, 1, 0], { pearson => -0.9757575757575756, spearman => -0.9757575757575756, kendall => -0.91111111111111109 } ],
	[ 'kendalltau Kendall 1970', [1, 2, 2, 4, 4, 6, 6, 8, 9, 9], [1, 2, 4, 4, 4, 4, 8, 8, 8, 10], { pearson => 0.91449145378834129, spearman => 0.91713786855380708, kendall => 0.85895569038733333 } ],
	[ 'kendalltau ties vs R', [12, 2, 1, 12, 2], [1, 4, 7, 1, 0], { pearson => -0.55663999856656965, spearman => -0.54073807043587518, kendall => -0.47140452079103173 } ],
	[ 'kendalltau 1,1,2 self', [1, 1, 2], [1, 1, 2], { pearson => 1, spearman => 1, kendall => 1 } ],
	[ 'kendalltau attributes', [1, 2, 2, 4, 4, 6, 6, 8, 9, 9], [1, 2, 2, 4, 4, 4, 8, 8, 8, 10], { pearson => 0.94207964670849753, spearman => 0.95279991580961532, kendall => 0.91205026548865176 } ],
	[ 'kendalltau nan_policy self', [0, 1, 2, 3, 4, 5, 6, 7, 8, undef], [0, 1, 2, 3, 4, 5, 6, 7, 8, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'kendalltau gh6134', [1, 2, 3, 4], [undef, 2.4, 3.4, 3.4], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'kendalltau gh6134 complete', [2, 3, 4], [2.4, 3.4, 3.4], { pearson => 0.86602540378443871, spearman => 0.86602540378443871, kendall => 0.81649658092772615 } ],
	[ 'mstats kendalltau p=1', [9, 2, 5, 6], [4, 7, 9, 11], { pearson => -0.3673598658373522, spearman => -0.20000000000000001, kendall => 0 } ],
	[ 'mstats kendalltau x y', [5.05, 6.75, 3.21, 2.66], [1.65, 26.5, -5.93, 7.96], { pearson => 0.72443514211849769, spearman => 0.40000000000000002, kendall => 0.33333333333333337 } ],
	[ 'mstats kendalltau x z', [5.05, 6.75, 3.21, 2.66], [1.65, 2.64, 2.64, 6.95], { pearson => -0.62079672927347374, spearman => -0.63245553203367588, kendall => -0.54772255750516607 } ],
	[ 'mstats kendalltau x y nan', [5.05, 6.75, 3.21, 2.66, undef], [1.65, 26.5, -5.93, 7.96, undef], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'mstats kendalltau 22 nan', [0, 0, 0, 0, 20, 20, 0, 60, 0, 20, 10, 10, 0, 40, 0, 20, 0, 0, 0, 0, 0, undef], [0, 80, 80, 80, 10, 33, 60, 0, 67, 27, 25, 80, 80, 80, 80, 80, 80, 0, 10, 45, undef, 0], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'mstats kendalltau 22 complete', [0, 0, 0, 0, 20, 20, 0, 60, 0, 20, 10, 10, 0, 40, 0, 20, 0, 0, 0, 0], [0, 80, 80, 80, 10, 33, 60, 0, 67, 27, 25, 80, 80, 80, 80, 80, 80, 0, 10, 45], { pearson => -0.26764245666825487, spearman => -0.18643165320404434, kendall => -0.15851878478024339 } ],
	[ 'bug NA rank', [1, 2, undef, 4, 5, 6], [2, 1, 4, 3, 6, 5], { pearson => undef, spearman => undef, kendall => undef } ],
	[ 'bug NA rank complete', [1, 2, 4, 5, 6], [2, 1, 3, 6, 5], { pearson => 0.86046511627907007, spearman => 0.79999999999999982, kendall => 0.59999999999999987 } ],
	[ 'Inf', [1, 2, 9**9**9, 4], [2, 1, 4, 3], { pearson => undef, spearman => 0.80000000000000004, kendall => 0.66666666666666674 } ],
	[ '-Inf', [1, -9**9**9, 3, 4], [2, 1, 4, 3], { pearson => undef, spearman => 0.80000000000000004, kendall => 0.66666666666666674 } ],
	[ 'Inf both', [1, 2, 9**9**9, 4], [2, -9**9**9, 9**9**9, 3], { pearson => undef, spearman => 0.80000000000000004, kendall => 0.66666666666666674 } ],
);
our @MAT = (
	[ 'longley', 'longley', undef, { pearson => [[1, 0.99158917802478197, 0.62063339255909666, 0.46474418760067465, 0.97916343297749808, 0.99114919006720525, 0.97089852506105589], [0.99158917802478197, 1, 0.60426093988955787, 0.44643679189262653, 0.99109006945847744, 0.99527348376478475, 0.98355161117966938], [0.62063339255909666, 0.60426093988955787, 1, -0.17742062950187834, 0.6865515163653122, 0.66825660456217462, 0.50249808387599415], [0.46474418760067465, 0.44643679189262653, -0.17742062950187834, 1, 0.36441626718903181, 0.41724514983494548, 0.45730739997648218], [0.97916343297749808, 0.99109006945847744, 0.6865515163653122, 0.36441626718903181, 1, 0.99395284623292557, 0.96039057159437557], [0.99114919006720525, 0.99527348376478475, 0.66825660456217462, 0.41724514983494548, 0.99395284623292557, 1, 0.97132945919211877], [0.97089852506105589, 0.98355161117966938, 0.50249808387599415, 0.45730739997648218, 0.96039057159437557, 0.97132945919211877, 1]], spearman => [[1, 0.99705882352941178, 0.66470588235294115, 0.22058823529411764, 0.99705882352941178, 0.99705882352941178, 0.98235294117647054], [0.99705882352941178, 1, 0.63823529411764701, 0.22352941176470587, 0.99411764705882355, 0.99411764705882355, 0.98529411764705876], [0.66470588235294115, 0.63823529411764701, 1, -0.3411764705882353, 0.68529411764705883, 0.68529411764705883, 0.56470588235294117], [0.22058823529411764, 0.22352941176470587, -0.3411764705882353, 1, 0.22647058823529412, 0.22647058823529412, 0.22647058823529412], [0.99705882352941178, 0.99411764705882355, 0.68529411764705883, 0.22647058823529412, 1, 1, 0.97647058823529409], [0.99705882352941178, 0.99411764705882355, 0.68529411764705883, 0.22647058823529412, 1, 1, 0.97647058823529409], [0.98235294117647054, 0.98529411764705876, 0.56470588235294117, 0.22647058823529412, 0.97647058823529409, 0.97647058823529409, 1]], kendall => [[1, 0.98333333333333317, 0.44999999999999996, 0.033333333333333326, 0.98333333333333317, 0.98333333333333317, 0.91666666666666652], [0.98333333333333317, 1, 0.43333333333333329, 0.049999999999999996, 0.96666666666666656, 0.96666666666666656, 0.93333333333333324], [0.44999999999999996, 0.43333333333333329, 1, -0.21666666666666665, 0.46666666666666662, 0.46666666666666662, 0.36666666666666664], [0.033333333333333326, 0.049999999999999996, -0.21666666666666665, 1, 0.049999999999999996, 0.049999999999999996, 0.049999999999999996], [0.98333333333333317, 0.96666666666666656, 0.46666666666666662, 0.049999999999999996, 1, 0.99999999999999989, 0.89999999999999991], [0.98333333333333317, 0.96666666666666656, 0.46666666666666662, 0.049999999999999996, 0.99999999999999989, 1, 0.89999999999999991], [0.91666666666666652, 0.93333333333333324, 0.36666666666666664, 0.049999999999999996, 0.89999999999999991, 0.89999999999999991, 1]] } ],
	[ 'longley cross', 'longley[0..2]', 'longley[3..6]', { pearson => [[0.46474418760067465, 0.97916343297749808, 0.99114919006720525, 0.97089852506105589], [0.44643679189262653, 0.99109006945847744, 0.99527348376478475, 0.98355161117966938], [-0.17742062950187834, 0.6865515163653122, 0.66825660456217462, 0.50249808387599415]], spearman => [[0.22058823529411764, 0.99705882352941178, 0.99705882352941178, 0.98235294117647054], [0.22352941176470587, 0.99411764705882355, 0.99411764705882355, 0.98529411764705876], [-0.3411764705882353, 0.68529411764705883, 0.68529411764705883, 0.56470588235294117]], kendall => [[0.033333333333333326, 0.98333333333333317, 0.98333333333333317, 0.91666666666666652], [0.049999999999999996, 0.96666666666666656, 0.96666666666666656, 0.93333333333333324], [-0.21666666666666665, 0.46666666666666662, 0.46666666666666662, 0.36666666666666664]] } ],
	[ 'swiss', 'swiss', undef, { pearson => [[1, 0.3530791836199747, -0.64588270645728751, -0.66378885703506907, 0.4636847006517939, 0.41655603143498271], [0.3530791836199747, 1, -0.68654220861713655, -0.63952251894832013, 0.40109505304873982, -0.060858608416581604], [-0.64588270645728751, -0.68654220861713655, 1, 0.69841529628848298, -0.57274180606416658, -0.11402159648203355], [-0.66378885703506907, -0.63952251894832013, 0.69841529628848298, 1, -0.15385891709091479, -0.099321845821345664], [0.4636847006517939, 0.40109505304873982, -0.57274180606416658, -0.15385891709091479, 1, 0.17549590759662292], [0.41655603143498271, -0.060858608416581604, -0.11402159648203355, -0.099321845821345664, 0.17549590759662292, 1]], spearman => [[1, 0.24266427693641762, -0.66090299635235406, -0.44325769036098822, 0.41364556230124316, 0.43713670057422294], [0.24266427693641762, 1, -0.59885993874896293, -0.650463814145816, 0.28868780908828523, -0.15212866043437015], [-0.66090299635235406, -0.59885993874896293, 1, 0.6746038314061471, -0.47505752571717447, -0.059154357161938287], [-0.44325769036098822, -0.650463814145816, 0.6746038314061471, 1, -0.14441630883022444, -0.018981368070256018], [0.41364556230124316, 0.28868780908828523, -0.47505752571717447, -0.14441630883022444, 1, 0.066117142881611329], [0.43713670057422294, -0.15212866043437015, -0.059154357161938287, -0.018981368070256018, 0.066117142881611329, 1]], kendall => [[1, 0.17954652547083078, -0.47624374042006684, -0.33061116135805874, 0.24537037037037038, 0.3156473838183374], [0.17954652547083078, 1, -0.4505221560842293, -0.47616456317784911, 0.2054604569820847, -0.080038691111814844], [-0.47624374042006684, -0.4505221560842293, 1, 0.52894368392582902, -0.32127553917226731, -0.03135731980956994], [-0.33061116135805874, -0.47616456317784911, 0.52894368392582902, 1, -0.084796522653796044, -0.0028743228174573079], [0.24537037037037038, 0.2054604569820847, -0.32127553917226731, -0.084796522653796044, 1, 0.054935680369563145], [0.3156473838183374, -0.080038691111814844, -0.03135731980956994, -0.0028743228174573079, 0.054935680369563145, 1]] } ],
	[ 'swM everything', 'swM', undef, { pearson => [[1, undef, undef, -0.66378885703506907, undef, 0.41655603143498271], [undef, 1, undef, undef, undef, undef], [undef, undef, 1, undef, undef, undef], [-0.66378885703506907, undef, undef, 1, undef, -0.099321845821345664], [undef, undef, undef, undef, 1, undef], [0.41655603143498271, undef, undef, -0.099321845821345664, undef, 1]], spearman => [[1, undef, undef, -0.44325769036098822, undef, 0.43713670057422294], [undef, 1, undef, undef, undef, undef], [undef, undef, 1, undef, undef, undef], [-0.44325769036098822, undef, undef, 1, undef, -0.018981368070256018], [undef, undef, undef, undef, 1, undef], [0.43713670057422294, undef, undef, -0.018981368070256018, undef, 1]], kendall => [[1, undef, undef, -0.33061116135805874, undef, 0.3156473838183374], [undef, 1, undef, undef, undef, undef], [undef, undef, 1, undef, undef, undef], [-0.33061116135805874, undef, undef, 1, undef, -0.0028743228174573079], [undef, undef, undef, undef, 1, undef], [0.3156473838183374, undef, undef, -0.0028743228174573079, undef, 1]] } ],
	[ 'swM complete', 'swM complete', undef, { pearson => [[1, 0.37821953232961192, -0.65483062095334998, -0.67421580916886714, 0.47722978705677149, 0.38781500153874399], [0.37821953232961192, 1, -0.71270778496833509, -0.64337782184250603, 0.40148365351797066, -0.07168222803561651], [-0.65483062095334998, -0.71270778496833509, 1, 0.69776906372592329, -0.6079436198704492, -0.10710047229525503], [-0.67421580916886714, -0.64337782184250603, 0.69776906372592329, 1, -0.17014449250893823, -0.083432791247531071], [0.47722978705677149, 0.40148365351797066, -0.6079436198704492, -0.17014449250893823, 1, 0.1722159393286401], [0.38781500153874399, -0.07168222803561651, -0.10710047229525503, -0.083432791247531071, 0.1722159393286401, 1]], spearman => [[1, 0.26731033527290071, -0.68525261489035727, -0.48064856628531993, 0.42349707519909779, 0.39816679662077503], [0.26731033527290071, 1, -0.6246040920243916, -0.63103889501014809, 0.30931322475949413, -0.1979130185347921], [-0.68525261489035727, -0.6246040920243916, 1, 0.68170913725932814, -0.52074537869856186, -0.035396397145346176], [-0.48064856628531993, -0.63103889501014809, 0.68170913725932814, 1, -0.20156344230042617, 0.0085585257510224447], [0.42349707519909779, 0.30931322475949413, -0.52074537869856186, -0.20156344230042617, 1, 0.074528476009944958], [0.39816679662077503, -0.1979130185347921, -0.035396397145346176, 0.0085585257510224447, 0.074528476009944958, 1]], kendall => [[1, 0.19777898058953786, -0.49928025410375981, -0.35665344374269331, 0.24761904761904766, 0.28511041637099765], [0.19777898058953786, 1, -0.47207156982560755, -0.46405642412342207, 0.22739294559759698, -0.10101182825424251], [-0.49928025410375981, -0.47207156982560755, 1, 0.53963082220537584, -0.3504667010447558, -0.014093434801610906], [-0.35665344374269331, -0.46405642412342207, 0.53963082220537584, 1, -0.12178410274140747, 0.017490517508940637], [0.24761904761904766, 0.22739294559759698, -0.3504667010447558, -0.12178410274140747, 1, 0.063830690232312901], [0.28511041637099765, -0.10101182825424251, -0.014093434801610906, 0.017490517508940637, 0.063830690232312901, 1]] } ],
	[ 'reg-1a spearman NA', [[1, 1], [3, 4], [4, 2], [undef, undef]], undef, { pearson => [[1, undef], [undef, 1]], spearman => [[1, undef], [undef, 1]], kendall => [[1, undef], [undef, 1]] } ],
	[ 'reg-1a spearman NA complete cross', [[1, 1], [3, 4], [4, 2]], [[1, 1], [3, 4], [4, 2]], { pearson => [[1, 0.5], [0.5, 1]], spearman => [[1, 0.5], [0.5, 1]], kendall => [[1, 0.33333333333333337], [0.33333333333333337, 1]] } ],
	[ 'PR#7116 1x1', [[1], [2]], [[1], [2]], { pearson => [[0.99999999999999978]], spearman => [[0.99999999999999978]], kendall => [[0.99999999999999978]] } ],
	[ 'reg-2 corner cols 2,3', [[1, -0.6264538107423324], [2, 0.18364332422208224], [3, -0.8356286124100472]], undef, { pearson => [[1, -0.19427385216523568], [-0.19427385216523568, 1]], spearman => [[1, -0.5], [-0.5, 1]], kendall => [[1, -0.33333333333333337], [-0.33333333333333337, 1]] } ],
	[ 'spearmanr 3cols', [[0, 0, 0], [1, -1, 1], [2, -2, 2], [3, -3, 3], [4, -4, 5], [5, -5, 4]], undef, { pearson => [[1, -1, 0.94285714285714284], [-1, 1, -0.94285714285714284], [0.94285714285714284, -0.94285714285714284, 1]], spearman => [[1, -1, 0.94285714285714284], [-1, 1, -0.94285714285714284], [0.94285714285714284, -0.94285714285714284, 1]], kendall => [[1, -1, 0.8666666666666667], [-1, 1, -0.8666666666666667], [0.8666666666666667, -0.8666666666666667, 1]] } ],
	[ 'spearmanr gh9103', [[undef, 5, 0.5], [3, undef, 4], [4, 4.1, 7.1], [5, 4.8, 3.8], [5.1, 4.9, 8], [6, 5, 5.1], [9.2, 4.1, 7.6]], undef, { pearson => [[1, undef, undef], [undef, 1, undef], [undef, undef, 1]], spearman => [[1, undef, undef], [undef, 1, undef], [undef, undef, 1]], kendall => [[1, undef, undef], [undef, 1, undef], [undef, undef, 1]] } ],
	[ 'spearmanr gh22816 cols 2,3', [[0, 0], [1, -1], [2, -2], [3, -3], [4, -4], [5, -5], [6, -6], [7, -7], [8, -8], [9, -9]], undef, { pearson => [[1, -0.99999999999999978], [-0.99999999999999978, 1]], spearman => [[1, -0.99999999999999978], [-0.99999999999999978, 1]], kendall => [[1, -1], [-1, 1]] } ],
	[ 'spearmanr 1d_vs_2d', [[1, 1], [2, 2], [3, 3], [4, 4], [5, 6], [6, 5]], undef, { pearson => [[1, 0.94285714285714284], [0.94285714285714284, 1]], spearman => [[1, 0.94285714285714284], [0.94285714285714284, 1]], kendall => [[1, 0.8666666666666667], [0.8666666666666667, 1]] } ],
	[ 'bug NA matrix', [[1, 1], [undef, 2], [3, 4], [4, 3]], undef, { pearson => [[1, undef], [undef, 1]], spearman => [[1, undef], [undef, 1]], kendall => [[1, undef], [undef, 1]] } ],
	[ 'cross y NA', 'longley[0..1]', [[1947, 60.323], [1948, 61.122], [1949, 60.171], [1950, 61.187], [1951, undef], [1952, 63.639], [1953, 64.989], [1954, 63.761], [1955, 66.019], [1956, 67.857], [1957, 68.169], [1958, 66.513], [1959, 68.655], [1960, 69.564], [1961, 69.331], [1962, 70.551]], { pearson => [[0.99114919006720525, undef], [0.99527348376478475, undef]], spearman => [[0.99705882352941178, undef], [0.99411764705882355, undef]], kendall => [[0.98333333333333317, undef], [0.96666666666666656, undef]] } ],
	[ 'draws', 'draws', undef, { pearson => [[1, 0.30450461720238559], [0.30450461720238559, 1]], spearman => [[1, 0.28659685838743354], [0.28659685838743354, 1]], kendall => [[1, 0.19291382765531062], [0.19291382765531062, 1]] } ],
	[ 'draws cross', 'draws[0]', 'draws[1]', { pearson => [[0.30450461720238559]], spearman => [[0.28659685838743354]], kendall => [[0.19291382765531062]] } ],
);
our %SWM_PAIRWISE = (
	pearson => [[1, 0.39202893125797417, -0.65314918786050646, -0.66378885703506918, 0.47231290332024506, 0.41655603143498271], [0.39202893125797417, 1, -0.7150561156617079, -0.65221506205556301, 0.41520068673463945, -0.036484267521671686], [-0.65314918786050646, -0.7150561156617079, 1, 0.69921153248838264, -0.60034017066518297, -0.11433546182674718], [-0.66378885703506918, -0.65221506205556301, 0.69921153248838264, 1, -0.17913338530757825, -0.09932184582134565], [0.47231290332024506, 0.41520068673463945, -0.60034017066518297, -0.17913338530757825, 1, 0.18503786297148425], [0.41655603143498271, -0.036484267521671686, -0.11433546182674718, -0.09932184582134565, 0.18503786297148425, 1]],
	spearman => [[1, 0.28468346246844911, -0.67687551926803247, -0.44325769036098822, 0.43123226841001605, 0.43713670057422294], [0.28468346246844911, 0.99999999999999989, -0.62840119090866031, -0.64464008412102969, 0.34078856370804844, -0.13648003929260402], [-0.67687551926803247, -0.62840119090866031, 1, 0.6803772582423856, -0.51376429212144825, -0.055337503472552653], [-0.44325769036098822, -0.64464008412102969, 0.6803772582423856, 1, -0.21381848615474319, -0.018981368070256018], [0.43123226841001605, 0.34078856370804844, -0.51376429212144825, -0.21381848615474319, 1, 0.089282417163421043], [0.43713670057422294, -0.13648003929260402, -0.055337503472552653, -0.018981368070256018, 0.089282417163421043, 1]],
	kendall => [[1, 0.20686324310832294, -0.4902334343106905, -0.33061116135805874, 0.26015473887814311, 0.3156473838183374], [0.20686324310832294, 1, -0.47923121367558991, -0.47311568953792754, 0.24557860639016674, -0.067056533537956445], [-0.4902334343106905, -0.47923121367558991, 0.99999999999999989, 0.53395466500555766, -0.34730679546936316, -0.02778045734926694], [-0.33061116135805874, -0.47311568953792754, 0.53395466500555766, 1, -0.1305363749050297, -0.0028743228174573079], [0.26015473887814311, 0.24557860639016674, -0.34730679546936316, -0.1305363749050297, 1, 0.071950469715807014], [0.3156473838183374, -0.067056533537956445, -0.02778045734926694, -0.0028743228174573079, 0.071950469715807014, 0.99999999999999978]],
);
our $LONGLEY_PSK = [[1, 0.98023898797314057, 0.95725624117917518], [0.98023898797314057, 1, 0.97421706882500103], [0.95725624117917518, 0.97421706882500103, 1]];
our @REG2_CORNER_X = ([[undef, 1, -0.6264538107423324], [undef, 2, 0.18364332422208224], [undef, 3, -0.8356286124100472]], [[1, 1, -0.6264538107423324], [undef, 2, 0.18364332422208224], [undef, 3, -0.8356286124100472]]);
our %R_WH200K = (pearson => 0.0002686427111792794, spearman => 0.00026888025175667523, kendall => 0.00020561663689276635);
## END GENERATED (R)

## BEGIN GENERATED (Python) -- python3 t/cor.R.scipy.py
our %PY_DRAWS = (
	x => [1.5374507520491147, 0.34649475164680055, -0.5500269677016936, -0.7404103693308972, 0.3336713597705434, 0.6064010988838381, 2.975111140710311, 0.36931871541756167, -0.0652656148321058, 1.0626959726105552, 0.39965654632043435, 1.759237035183956, -0.0061955899629830835, 0.31204898018677485, 1.3536063407854502, 0.2436058355480658, 0.3192784036476163, 1.510665461714057, 1.075602447229673, 0.6429868453088072, 0.8359527030210311, -0.23131437416997946, 1.0173961868104378, 1.479303864480798, 2.12409833685818, 2.506027414122884, 2.2327596409636894, 1.397350887113851, -0.2441178052854298, 2.324977346485878, 1.0140621037944448, 2.17086650524546, 1.4974423409447208, 0.7250202449852763, 2.9857573916877236, 0.40976580499755044, -0.31264266090881176, 1.0304164466142156, -0.606037329661022, 1.9615690541464024, 1.0950883201500718, -0.5756769036595297, -0.036156825996700226, -0.42027334056320576, 0.5549004610432292, 0.17881602920019812, 0.34064259024405263, -0.2610825236806762, 1.7805574279379122, 0.1316589885036623, 1.174759531880094, 1.721474828356134, 2.674969985049004, 1.024804084919424, -0.0856365081960544, 0.6463176797288591, 1.0537145346702679, 0.9833799551258194, 1.4301385734683216, 0.9433800603193623, -0.3441070933866459, -0.3500707381773691, 1.9660472953975836, 1.557828128754569, -0.09616417075455597, 1.015790650632982, 3.72193642940983, 0.16203192611063888, 2.942383957605025, 0.32678868389374294, 1.9103144786092625, 2.1681085528872894, 1.5870902938998737, 0.172434549259592, -1.0057293558927216, 0.972187800409611, -0.0580804146838334, 0.21307775340381097, -0.3536631375463113, 0.12769962022589987, -0.256311850080871, 0.640772567840991, 0.09491658682162696, 2.080901616215029, 1.8455571379482214, 1.9285864843310585, -1.9430343404097514, 1.3142211296818906, 0.2538212266621155, 0.7674484356262646, 2.2504282679027945, -0.7969425460106445, 2.530766429005463, 0.962566015438295, 2.057693957823112, 0.7229200799512725, 0.04348944181765402, 0.09415432671183288, 1.841654226977104, 1.151458211219634, 2.6639575715245902, 0.14898805139661575, 1.716688431033872, 2.375838885249929, 0.5106948964283127, 0.39180926387510695, 0.6738436012563216, 0.9717756235575595, 1.9209410520164032, 0.08358095886348049, 0.7305970906329587, 1.438527370295931, 1.6865217942717803, 2.19865450771914, 1.1274119861275596, 1.7068407520801525, 1.5970794478297707, 1.5202159307876637, 0.7336035626340749, 0.30316669274644903, 1.4998802450957411, 0.5399062384695288, 1.7505603886760113, 1.4083905654030897, 0.3666671493578624, 3.079869308672917, 0.5545850692037947, 0.6105250879797655, 0.375140734478145, -0.008968735182844911, 1.5519661186308134, -0.8959897589677916, 0.3215662699240136, 0.7808568345348711, 2.106393117154825, 1.772802601091755, 0.6396694342718023, 0.8148990739563169, 0.7798951454058558, -0.3095879891712323, 0.3101093972167682, -0.08603721170421341, 2.1458326132368963, 0.5132435219329472, 0.5897944248287245, -1.1685192095373695, 2.8079776339309985, 1.4973339140276731, -0.3564514802184353, 0.23439430074639322, 1.2337324541441188, 1.8857917165267115, -0.8267964369590217, 1.8325275263824103, 2.39232096609856, -0.22095220416546701, -0.4522232164931379, 1.135167173609764, 1.201668179839879, 2.133493207227385, -1.0991055237302478, -0.30035578406440067, 1.368407536190687, 0.09785410779948756, 2.3571044363374174, 1.6846810181474048, -0.3591014465174771, 0.0318992465964012, 1.5801774319635777, 0.8590674479200718, 0.6006245257999305, 1.021273192348662, 0.6861824009620767, 0.5240166933123424, 1.7252578901729758, 2.0454768643838044, -0.3640926643882043, 1.3969796643074723, 0.5989936575571626, -0.8638845705246743, 3.042644879348051, 0.24647486543072195, 0.053904984384745114, 2.666413734049522, 0.4536524944383131, 1.2542251675157812, 1.4694320464021464, 1.4286567569942497, -0.6666900169575292, 2.5265780709934673, 0.6291966972611038, 1.2438534381385, 1.13537171235869, 0.6076811390736214, -1.1530136700241718, 0.3648955174254944, 0.37698412692881145, 1.2636794914175353, 0.9238431558932673, 1.4011019124884214, 0.979661930602063, 2.199634218059631, 1.578107578552937, 1.1843298612215811, 1.133840183961928, -0.5602435774254475, 1.1798683933693213, 0.1618326875596614, 1.3670204527046743, 1.6887553599117449, -0.4739309483147671, 1.6492833653610315, 1.7272841902207816, 1.9537993229098753, 1.5171218358644643, 0.03936690614001015, -1.161119018320727, 0.7461245742232924, -0.14959560849506892, 1.4067673498480224, 1.1719225322913132, 1.8376865179492041, 2.357145698823524, 1.4023536770444736, 1.9794336917350492, 1.202601519441639, 1.2216201053301532, 2.309014249175588, -0.26463507550541854, -0.4277030073414618, 0.4371400738028567, 1.2505875786291494, 1.4495540684623385, 0.872889851176067, 1.3101934467956593, 1.4286860424266565, 0.6197991939567872, 1.168578869208248, 1.0839959620206006, 1.1288543799341626, 1.8313708554706443, 0.13625275151245175, 1.7142620561665893, -1.4036696464208354, 1.2552112199573604, 1.21747087738286, 0.6529699308003929, 0.8787483302349627, -0.2343312675794027, 1.869391613603562, 1.3653672120758436, 0.15886403125878523, 0.5823586782641523, 0.8047977581814838, 0.30575689322456867, 0.5820624564674977, 0.1645703171180657, 1.535195598518034, -0.5249863672275894, 1.2102711002173583, 2.3889021239117074, 2.306975475009275, 1.2777833187794296, 1.9962600493769582, 1.5920995306463754, 1.2377734795847901, 1.3164155987785258, 3.175970853303713, 0.8137115040621138, -0.5199116041373226, 1.2227562325230819, 2.0219257503896237, 1.6833486262900208, 2.041459063828173, 0.7709696846250532, 1.5087442999648264, -0.5353089668859154, 1.9138470281669169, 1.097926724232419, 3.0682211027228616, 0.7332078743089745, 0.3972492140682148, -0.17852943939531785, 1.2025222945802145, 0.8641904462737118, 1.0928728228576363, 0.6637482341427604, 0.22245409997295307, 0.6499095333508373, 0.973008156265551, -1.3167468075120303, 1.1600994030792897, 2.19320107738708, -0.17227954160823078, -0.9099473800478226, 1.2650513777593688, 1.2570939896701616, 2.7946864084912564, 1.7355467446973798, 2.8878044663545483, 0.6063129355024695, 1.6579537397719037, 1.074031081903747, 1.5697205675044341, 1.2181396243908729, 1.7134425576284151, -1.5661591777116972, -0.21201977289507723, 1.4488313715339118, 0.40285500162313503, 1.4089066815794242, 1.686692295660447, 0.45277460113502144, 0.22375153094854583, 0.5944712497698047, 1.651521191967737, -0.8781760127604699, 0.4528289564491812, 0.252576007296917, 1.555065840174675, 0.7929040918629169, -0.042652640789387464, 0.9288513938605203, 0.24402394854958787, 1.1404687165771406, 0.7205397020728883, -0.16789899685727327, 0.04887685767503325, 1.5337214487163853, 0.5692465451101507, 1.0566175851765964, 0.9714440161987012, 0.2974417061226513, 1.6243126784627724, 0.38721291183752415, 0.15459594421028833, 2.4800524211108206, 2.853029147078153, 0.19034871753700655, 2.7382339693666826, 2.0200220153752477, 1.1301092680516285, -0.2621274170995507, 2.877109991094027, 1.140913020573955, -0.044141366082055544, 1.727801032671606, -0.03178733705596404, -0.09327883786567881, -0.420168503610725, 1.0095510746964784, 0.5672647397697284, 0.5105254216850316, 1.1764961514451897, 1.65860657345715, -0.22308320182192465, 0.9049643803614906, 0.4202099478821846, 2.7604733867867193, 1.721151928178501, 0.30415665562021776, 0.3873178169305782, 0.731590059857155, 1.5050410432931036, 2.8832423397372167, 0.8110918560724147, -0.24111595854429235, 0.8903829948837803, -0.16157290067324737, 0.576964828859382, 1.5560083679625754, 2.2759360950873244, 2.5920817854372356, 1.270290581098361, 1.8945736678554552, 0.16982816640454146, 2.244243743642237, 0.2742267804647047, 3.28207505239463, 1.7038691745923629, 1.9278565953889881, 0.8928173969275632, 1.0969477586579235, 1.4899467386409055, 1.7548858280823096, 1.7772954512604926, -1.3499445629936324, 0.1910143331886064, 1.448586333395693, 0.618300694529837, 1.7008049309921631, 1.3193613983164176, 0.9471838216972703, -0.970431844972639, -0.7563668291341756, 1.6623299791669046, 0.7341566313816921, -0.8745761843179496, -0.6221644030253011, 1.195898772575341, 0.7840009542767887, 1.1644609616554038, 0.5411279357229328, 2.314735734043209, 0.8110418842284369, 2.034594323386508, 2.6139999762442576, -0.010243816664430305, -0.08052047668432127, 1.3906483776435175, 2.0126577031069592, 1.336787741716892, 0.9287988746175047, -0.370193125888687, 1.2177840148816839, 2.0652583710834094, 1.1351159565607218, 1.2447142302723109, 2.8766101291034607, -1.1938349856551658, 0.3254985692879011, 0.09885599807279755, 1.6886705555559516, 3.2072055275917255, 2.4962045261625887, 0.6946477360914608, 1.15660287721485, 0.3346430091916266, 1.8275554092805781, 1.131011614714798, 1.5559748300616167, 1.8482855716548068, 1.850900736070709, 1.5364827572851558, 1.7689964767501656, 1.8681637303889889, 0.9758063043940399, 2.0019303397221115, -0.12256485529926264, -0.11277236700087623, 2.1355024353614924, -0.48693822197820147, 0.09637647656447224, 1.4465757823743735, -0.24699925467181316, 0.9519930274527942, 1.647354348751139, 0.5134886060468083, 1.0299405936647494, 1.4741153412489916, 2.1043298288593135, 1.2227511258910937, 2.5446363248703974, 1.1956270077239208, 0.47791904440195854, 0.8754331556325413, -1.092652237102468, 1.94719794710777, -0.4567020370692281, -0.4706494349608994, 1.4504664941789094, 1.4160474996937324, 0.06645983348237627, 1.1250569574795564, 1.5761345556293889, 0.6440359868852129, 2.0237131865414515, 2.3873092175677177, 2.3181183114470434, 1.247145277198126, 3.5725256187649084, -0.21897506890756424, 0.0876989492106156, -0.12842803366244815, 0.12472533457577839, 1.9007915571877798, -0.6927949801936166, 0.2787014638038826, 1.331314492483257, 1.1051406566706643, -0.691323725680105, 0.14387896183007387, 2.0859364718351627, 1.8694026963263393, 1.4430566749698426, 1.6396625094549062, 0.5365319439179057, -0.9158494289526105, 1.2305204667859602, -0.6450495319966822, 0.9913926199178742, 0.656895449478784, 0.43054628604942136, 1.4493081275583741, 0.7533693942094487, 0.8674129715466156, 2.043755859898784, 0.067398569695725, 0.6011003878143959, 1.0865574854591837],
	y => [-0.464902526482024, -0.37743064916745195, -0.199043883274027, 0.4863206792169616, 1.3911873348637587, 0.08506002572580539, 0.9477156511836798, 0.8192388675666333, 0.24429520427352058, 1.5437405634332442, 2.8615313695182927, 2.4636159262998594, 1.5873747942080345, 1.4763287556926343, 0.10893387493786391, 0.2627057552320236, 1.8026125279627818, 1.2154035156542664, -0.2739565577345854, 1.2692761532004848, 2.2538480032363135, -0.35185451275402607, 0.25887576355173175, 1.451022179526359, 2.235546244446759, 1.3899479832644956, 0.3424845729516223, 2.269980428029749, 0.5290634848790523, 1.9378728909372551, 2.3102991703075593, 2.2608805008482253, 1.0021184810534292, 2.2986405037052253, 3.9256250012985068, 0.35846913784144346, 1.6277251587287513, 1.5136812671258584, 1.759588995508606, 0.6416596676575456, 0.5096023479827626, 0.45007192958934444, -0.15209639809005712, 0.02796351360961823, 1.6594446510117171, 0.5512375895210004, 2.577042700043052, -0.35195200968984475, 0.21903102881756886, 0.5271396066498774, 0.7248931438177795, -0.12328730375529312, 0.881723294501038, 2.6750253895053437, 1.5193736497323005, -0.10143983210139497, 1.0412623436969706, -0.34924238763573023, 0.21215881680726736, 1.8494381484626585, 1.6754711918939449, -1.1641038263624575, 0.1542481035572514, 0.0184382851317907, 1.2931292570551913, 1.2411077560374433, 3.2728471245119097, 1.3954160725248534, 3.183623586416306, 0.1934100185718716, -0.44197575258999805, 0.8338379066834742, 1.8793485834673276, 1.9155556850583972, 1.8160337658861287, 0.16880156202590718, 1.3601818512834345, 0.810842090616963, -0.8648697566306688, 0.7440633617282698, 0.8633512435910999, 0.8898537259131812, 0.5947930801013712, 1.6476425519250788, 0.9437797052185432, 1.2135399540099963, 1.7499836563212419, -0.7288084857466682, 0.526843947728802, 1.2835894342282352, 1.4295369143087535, 0.33217013742010837, 0.12355866508486324, 1.8301590849531955, 1.928066585502749, 0.6558624077591636, 0.7123089054510764, 2.609580498624939, 1.0335234570362666, -0.10358448169392175, 2.616486744223799, 1.4405071280196147, 1.8965814482581362, 1.5865287785218773, 1.5042376532338007, 1.0721898887218693, 2.302399592901391, 1.054476977018376, 1.361674003546083, 0.5872403252979345, 2.536861560493431, 0.8502583992371344, 1.682862841169762, 1.2958106066834552, 1.6463283731256846, 1.5848008170984098, 1.6646228474918812, 2.3353739323227503, 0.398186907302309, 1.4173666950605637, 3.529553749792526, 3.1743252423255752, 0.7440422296473249, 1.010804993692589, 2.297828233508488, 1.1215068565981459, 0.805980593028454, -0.03521667391669699, 2.2965948518410157, 2.1949763836594465, 2.1177571070478214, -0.15838397041463312, 0.41297266488195183, 1.9472950628417924, 0.2997977298122353, 0.9604715303709551, 0.5908289128875738, 0.35498288277852563, 0.3611480409062702, 0.6667177729488302, -0.12960650707541388, 0.750339217549385, 2.87290154871342, 2.185181697192224, 0.9745029433485515, -0.056951196401879386, 0.7793131355805116, 2.418661497382616, 2.5022647911816587, -0.5816744651671218, 1.0780759227968157, 0.43588280584747124, -0.5685672345546412, 1.4159245300677787, 1.431331664233767, 2.2626333262745417, 0.41077380255283796, 1.0223554390629666, 1.9001273049689835, 2.041783281875528, 1.1228345522832792, -1.082123104259038, 2.8452980142744932, 0.07223957871428947, 1.771387557154086, 2.972410793122625, 1.0053533845324685, 0.07779283460080468, 0.5864661486089734, 0.3944469303070067, 1.6842173431518181, 0.22921747427558642, 1.2497972560962118, 1.994890280422496, 2.4504961054080656, 0.37399065696612444, 1.534482541464343, 0.406766172093037, 0.37608672710796903, 0.5544061148959583, 2.2003207152122033, 0.3102220854035491, 0.3808879110978514, 1.267349124031611, 1.9500924679138614, 1.068091251442433, 0.5113456256477447, 2.054260152216435, -0.783280149614334, 2.5162626476762537, 2.293645611746134, 1.6936613303219719, 2.3686173567165034, 0.7335559590921952, 0.27817210743915793, 0.6430502305929061, 1.4544648692894029, 0.9897511204531987, 0.9325050970128528, -0.4024714715091163, 1.8708225303313675, 2.2433416179685777, 1.8583085351127753, 2.613662377001414, 2.615774951795657, 0.5406030799467878, 0.8303261647807951, 1.3432226116380588, 3.3992114148568175, 0.9236902875382682, 2.3009070577372603, 0.8129062702944344, 3.4375066715278497, 2.9905539518079114, 2.3075752249920916, -1.0387043384902708, 0.9268208267031725, 1.2910155973974673, 2.4852323281914557, 2.7639481852747854, 1.1868225014757243, 2.08450990599553, 0.7526392606498871, 1.4234757255538548, 2.6497739515657965, 0.27115346353277825, 1.4187040111208804, 2.838705668938304, 0.9773890127552851, 1.603718933799353, 1.8976755131357859, 0.20588799748980033, -0.05136237697223234, 1.3145413977648708, 0.4132011387477948, 3.105899421905334, 0.6799415516773466, 1.996448995235568, 2.007341833843008, 2.53694157044821, 0.6633297755537266, 1.3971020028261778, 1.2635331725612788, -0.21318153709395823, 0.8147542760783617, 1.735369647804855, 0.8857227560756951, 5.104729896695541, 0.12693747669247715, 2.2111355918190467, 0.9923505834416309, 1.6818970096320092, -0.10811532794065758, 0.765917474616581, 0.6433123799962097, -0.034089600755261476, 0.5235614411215636, 2.0990447059718735, 1.2895690090794611, 1.981614819617111, 1.5727120479496208, 3.28150957098566, 1.3778740649877084, 2.1762564459808935, 2.7914161127092814, 0.9109259149084359, 1.4491401096452323, 1.54415587428483, 0.9345191224342156, 0.13457192136196486, 1.0203634153888201, 1.358937510033436, 2.975587340672535, 0.5599062247596726, 1.1639391801027748, 2.4808384268007795, 1.0213420846982486, 2.0630025975383757, 1.4868087077111682, 2.008396941040129, 1.1249248765905895, 1.2184222499389326, 1.4828438926842151, 2.8361008438378397, 0.2713966802581903, 1.7693905633995326, 1.229757625731127, 1.2829460346660795, 1.2410677913922743, 1.315836352164192, 1.6162266761863322, 2.696965813659977, 1.3119063012234065, -0.2291084225866676, 2.5981125238665292, 1.035223962970473, 2.5682299220882685, 0.741239613516406, 1.9807303526012567, 1.2930147795545528, 1.604196054954294, 2.1986966292630665, 1.91425642223271, 2.7832109342358464, 3.0586190919219622, 1.2471618066496726, 1.255438196945673, 0.43710795587858936, 1.0129214224315626, 2.11530922999887, 1.7880606018168717, 1.0248023766922112, 1.2768662284504462, 2.1443521609950835, 0.07577419576381755, 1.9422099126227126, 1.972378506112333, 1.7305788665553332, 0.2844236461198178, 2.9024890887901775, 1.7789443163772862, 0.1127421264140251, 0.7040068040856662, 1.531429111228748, 1.006302278285715, 0.5522660867616622, -0.903340292735111, 0.2351431637733253, 0.7043920777835041, 1.202651231847869, 1.6618017163816696, -0.8399563279409612, 0.1601063193350054, 0.5389187846089809, -0.0048942147358032664, 1.9668243865652566, 1.7679522838437134, 2.433246870588423, 1.0887978138150596, 2.839062556563997, 1.4379476128440398, 2.148109371351068, 1.188771979880074, 1.1157204009141286, 1.4336228410116596, 0.8211931916993181, 1.3673559640368094, -0.2996895944343056, 0.29461150123462954, 0.21963724428059878, 0.059619458404230115, 2.597551818960064, 0.2700947030021804, 1.290581938948434, 2.758387481820709, 2.8373141302433127, 0.5782891933319533, 1.239659495877442, 2.4374918350050425, 1.7079567823505717, 1.722552643680042, 2.5497286407632918, 0.0763087623231102, 2.9204797683649653, 3.615114437657392, 1.9790840753542471, 2.0127562484876993, 2.413297809237735, 0.6974085123029392, 0.6608224607911176, 0.8712340779185606, 2.004182534769713, 1.7050133230730713, 1.900355416707865, 1.0006683217442518, -0.7805655562072285, 1.2779310273330828, -0.3815663848433675, 2.40343499384495, 1.4504709364996564, 0.6690402669560218, 1.7401216169576448, 1.8570393431257872, 0.8853763496308589, 0.6402710872353811, 1.3973621680446053, 1.3785685594566897, 1.1082411171840938, 1.4839214768465558, 0.13258512580086787, 0.4326793009959116, 0.006617923538589659, 1.5939249466029202, -1.0586498046227668, 1.0866410430853288, 1.3321815653439035, 2.046269857234954, 0.32781975142895453, 0.7564397774950804, 1.359573476874353, 1.5095910567417812, 0.41436429001484504, 2.3127116721042755, 1.978058361443078, 1.3805370823633079, -0.5301938923088801, 2.603958570527436, -0.6028307045922371, 0.4974396390549274, 1.2124363720405444, 0.9831229862395084, 1.7660263233185416, 0.9297992796801416, 0.15622751812104518, 0.294314676562725, 1.9743348554867772, 3.517391208894835, 2.3077389710334337, 2.7417362073162894, 1.0712416331558146, -0.6309986017697015, 1.6092274794468033, 0.7164364804500648, 0.6414001069344143, 1.456372832032772, 0.12389729649946765, 1.930176454457702, 2.2848880042809627, -0.22390410994165996, 2.0841917134475576, 1.1029952993460101, 1.6058696466275522, 1.1078896439383192, 0.43246341030053237, 0.4788440759623808, 0.5801528971968543, 1.799409915518179, 0.7443914606007382, 1.01664366312364, 1.0090152015313731, 1.7284483570824802, 0.9596246821930733, -0.5647126537881698, 0.8021566536827712, 1.971589777580047, 0.8260991487303793, -0.5426614193676564, 1.8554354911089317, 1.278654017849616, 3.29315275802095, 0.4810536152046625, 0.4128004710640812, 1.661142116134993, 1.7511720149146526, 0.4604918464593359, -0.5041787743969357, 1.1458693132916278, 1.190757293187699, 1.2142635038821008, 1.4400800025697413, 0.8451724308445551, 0.9349356409218775, 0.842611420824161, 0.5835255380635505, 2.6840941248829058, 1.9944431848416013, 3.149263510474876, 0.9099548950640375, 2.6119643297903874, 2.255395836763622, 2.6326821949049632, 1.677602043134199, 2.2566250064214017, -0.1399233487328132, 0.49355128665631853, 2.0307940364920656, 1.4210348316128454, 2.9183879894968334, 0.4959418893590289, 0.5374991335697837, 0.09662030353772241, 1.4495609241392617, 2.1339714997430312, 2.4721645211805314, 0.4595380791474868, 1.500275366463822, 1.0713690860694378, 1.677441236798327, 3.632589358038676, 0.26796287784188155, -0.16670099096840515, 1.2936047497425267, -0.9061734824668561, 0.4019918654427114, 0.15766098157772143, 1.1691653727671318, 1.6346887565620138, 1.653894896474793, -0.1910325086862037, 1.1283266567466146],
);
our %PY = (
	'draws pearson' => 0.30450461720238553,
	'draws spearman' => 0.28659685838743354,
	'draws kendall' => 0.19291382765531062,
	'wh200k pearson' => 0.0002686427111793169,
	'wh200k spearman' => 0.0002688802517566752,
	'wh200k kendall' => 0.00020561663689276635,
);
## END GENERATED (Python)
}
