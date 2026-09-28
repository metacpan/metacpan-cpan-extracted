#!/usr/bin/env perl
#
# lm() at the edges R reaches and lm() used to get wrong.
#
# Expected values: R 4.6.1 stats::lm() / summary.lm(), printed at full
# precision by t/lm.edge.R.R, which also says how to re-run it.  The test never
# runs R.  Cases:
#
#   sqrt_hp, inv_wt, disp_1_5
#       R's own mtcars.  A non-integer or negative exponent inside I().  Up to
#       0.3211 the exponent was read with atoi(), so I(hp^0.5) became hp^0 --
#       a column of ones, aliased against the intercept, reported as NaN.
#   zero_x
#       SciPy 1.18.0 scipy/stats/tests/test_stats.py,
#       TestRegression.test_regressZEROX: Wilkinson's test W.IV.D, "Regress
#       ZERO on X".  Every statistic is 0/0: R has NaN t, p, R^2 and adjusted
#       R^2.  lm() reported t = Inf, p = 0 and R^2 = 0.
#   short_aliased
#       Three rows, three columns, z = 2x.  The rank is 2, so there is one
#       residual degree of freedom and R fits it with z NA; lm() refused it
#       because it compared the row count with the column count, not the rank.
#
# Non-finite data: R's lm.fit() stops with "NA/NaN/Inf in 'y'" (or 'x'), as
# R 4.6.1 does for lm(y ~ x, data.frame(y = c(1, 2, Inf, 4), x = 1:4)).  lm()
# used to fit it, return every coefficient NaN, and report each with t = -Inf
# and p = 0.
#
# exact_inf and exact_neg_inf: x = (0, 0, 1, 1) makes every step of lm()'s
# sweep exact in binary -- pivots 4 and 1, multipliers 1/2 -- so the estimates
# are exact, the residuals exactly 0, and every standard error exactly 0 at
# every NV width.  summary.lm() defines t as Estimate / Std. Error, so a nonzero
# estimate has t = +-Inf and p = 0, a zero one t = NaN, and F = Inf.  R 4.6.1
# itself does NOT report those numbers: its Householder QR leaves 9.9e-32 of
# rounding in the residual sum of squares for both cases, and so reports
# t = 9.0e15 and an intercept of -2.2e-16 with t = -1.41, p = 0.29 for the first.
# That is a known divergence, kept on purpose -- R's figures are noise from its
# own rounding -- and the expectations below are the definition's, not R's.
# (UTF-8 row names, and the other model functions' row-keyed results, are
# t/rownames.utf8.t.)
#
# On tolerances: kappa(X'X) is 6.5e8 for disp_1_5, the worst of the three
# mtcars designs (R's kappa(crossprod(X), exact = TRUE)), so the normal
# equations lm() solves permit a relative error of about 1.4e-7 there.  The
# worst disagreement with R actually measured on the double perl was 3.3e-13.
# The 1e-10 relative tolerance leaves 300 times that as headroom for
# long-double and quadmath builds, whose literals and incomplete-beta tails
# differ in the last bits.
# zero_x is exact arithmetic -- y is all zeros, so X'y, the estimates and the
# residuals are exactly zero at every NV width -- and is compared exactly.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(lm);
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $INF = 9**9**9;
my $RTOL = 1e-10;	# see "On tolerances" above

sub is_nanish {
	my ($x) = @_;
	return 1 if !defined $x;
	return 1 if $x eq 'NaN' || $x eq 'nan' || $x eq '-nan';
	no warnings 'numeric';
	return $x != $x ? 1 : 0;
}

my $worst = 0;
sub near {
	my ($got, $want, $name) = @_;
	if (!defined $want) { return ok(is_nanish($got), "$name is NaN") }
	if (is_nanish($got)) { return ok(0, "$name: got NaN, want $want") }
	if ($want == 0) {
		ok($got == 0, "$name is 0") or diag("got $got");
		return;
	}
	my $rel = abs($got - $want) / abs($want);
	$worst = $rel if $rel > $worst;
	ok($rel <= $RTOL, $name) or diag(sprintf "got %.17g want %.17g rel %.3g", $got, $want, $rel);
}

# mtcars (R 4.6.1 datasets), the columns the cases use, in R's row order
my %mtcars = (
	mpg  => [21, 21, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2, 17.8, 16.4, 17.3, 15.2, 10.4, 10.4, 14.7, 32.4, 30.4, 33.9, 21.5, 15.5, 15.2, 13.3, 19.2, 27.3, 26, 30.4, 15.8, 19.7, 15, 21.4],
	hp   => [110, 110, 93, 110, 175, 105, 245, 62, 95, 123, 123, 180, 180, 180, 205, 215, 230, 66, 52, 65, 97, 150, 150, 245, 175, 66, 91, 113, 264, 175, 335, 109],
	wt   => [2.62, 2.875, 2.32, 3.215, 3.44, 3.46, 3.57, 3.19, 3.15, 3.44, 3.44, 4.07, 3.73, 3.78, 5.25, 5.424, 5.345, 2.2, 1.615, 1.835, 2.465, 3.52, 3.435, 3.84, 3.845, 1.935, 2.14, 1.513, 3.17, 2.77, 3.57, 2.78],
	disp => [160, 160, 108, 258, 360, 225, 360, 146.7, 140.8, 167.6, 167.6, 275.8, 275.8, 275.8, 472, 460, 440, 78.7, 75.7, 71.1, 120.1, 318, 304, 350, 400, 79, 120.3, 95.1, 351, 145, 301, 121],
);

my %CASE = (
	sqrt_hp       => ['mpg ~ I(hp^0.5)',        \%mtcars],
	inv_wt        => ['mpg ~ I(wt^-1)',         \%mtcars],
	disp_1_5      => ['mpg ~ I(disp^1.5) + wt', \%mtcars],
	zero_x        => ['y ~ x', { x => [1 .. 9], y => [(0) x 9] }],
	short_aliased => ['y ~ x + z', { y => [1, 2, 4], x => [1, 2, 3], z => [2, 4, 6] }],
);

# Frozen by t/lm.edge.R.R; re-run it rather than editing these by hand.
my %EXPECT = (
	sqrt_hp => {
		names    => ['Intercept', 'I(hp^0.5)'],
		estimate => [41.073638753424675, -1.7783639427166005],
		se       => [2.75141859418846, 0.22717477911776982],
		t        => [14.92816790588692, -7.8281750712946785],
		p        => [1.991801335750602e-15, 9.795530112539456e-09],
		rank => 2, df => 30,
		r2 => 0.6713420989959048, adj => 0.6603868356291016,
		fstat => 61.28032494683945,
		rss => 370.08430507531483,
	},
	inv_wt => {
		names    => ['Intercept', 'I(wt^-1)'],
		estimate => [4.386254227357997, 45.82948753754401],
		se       => [1.5364176146813584, 4.249154834307346],
		t        => [2.854858070777634, 10.785553674702625],
		p        => [0.007737377303853949, 7.639160403026984e-12],
		rank => 2, df => 30,
		r2 => 0.7949813737456826, adj => 0.7881474195372054,
		fstat => 116.32816806989135,
		rss => 230.86064747878777,
	},
	disp_1_5 => {
		names    => ['Intercept', 'I(disp^1.5)', 'wt'],
		estimate => [35.29661584516779, -0.00042983892606299705, -4.209328945667806],
		se       => [2.6101278815183035, 0.0003932713155288457, 1.178648706274234],
		t        => [13.522945023151838, -1.0929831622349002, -3.5713176651028617],
		p        => [4.715502202448016e-14, 0.28339774684299435, 0.0012631830096377734],
		rank => 3, df => 29,
		r2 => 0.7626116560758841, adj => 0.7462400461500831,
		fstat => 46.58134780465509,
		rss => 267.31047702103336,
	},
	zero_x => {
		names    => ['Intercept', 'x'],
		estimate => [-0, 0],
		se       => [0, 0],
		t        => [undef, undef],
		p        => [undef, undef],
		rank => 2, df => 7,
		r2 => undef, adj => undef,
		fstat => undef,
		rss => 0,
	},
	short_aliased => {
		names    => ['Intercept', 'x', 'z'],
		estimate => [-0.6666666666666672, 1.5000000000000002, undef],
		se       => [0.623609564462324, 0.28867513459481303, undef],
		t        => [-1.0690449676496976, 5.19615242270663, undef],
		p        => [0.47876359039291994, 0.12103771832367675, undef],
		rank => 2, df => 1,
		r2 => 0.9642857142857142, adj => 0.9285714285714284,
		fstat => 26.999999999999996,
		rss => 0.1666666666666667,
	},
);

for my $key (sort keys %CASE) {
	my ($formula, $data) = @{ $CASE{$key} };
	my $e = $EXPECT{$key};
	my $r = lm(formula => $formula, data => $data);
	is_deeply($r->{terms}, $e->{names}, "$key: terms");
	is($r->{rank}, $e->{rank}, "$key: rank");
	is($r->{'df.residual'}, $e->{df}, "$key: df.residual");
	for my $j (0 .. $#{ $e->{names} }) {
		my $n = $e->{names}[$j];
		my $s = $r->{summary}{$n};
		near($r->{coefficients}{$n}, $e->{estimate}[$j], "$key: $n estimate");
		near($s->{'Std. Error'},     $e->{se}[$j],       "$key: $n std. error");
		near($s->{'t value'},        $e->{t}[$j],        "$key: $n t value");
		near($s->{'Pr(>|t|)'},       $e->{p}[$j],        "$key: $n Pr(>|t|)");
	}
	near($r->{'r.squared'},     $e->{r2},  "$key: r.squared");
	near($r->{'adj.r.squared'}, $e->{adj}, "$key: adj.r.squared");
	near($r->{rss},             $e->{rss}, "$key: rss");
	if (defined $e->{fstat}) {
		near($r->{fstatistic}[0], $e->{fstat}, "$key: F");
	} else {
		ok(!exists $r->{fstatistic}, "$key: no F statistic when R's is NaN");
	}
}
diag(sprintf 'worst relative disagreement with R: %.3g', $worst);

# I() with an exponent that is not a number: every row is NaN and dropped
throws_ok { lm(formula => 'y ~ I(x^abc)', data => { y => [1, 2, 3], x => [1, 2, 3] }) }
	qr/0 degrees of freedom/, 'I(x^abc): a non-numeric exponent is not read as 0';

# Non-finite data is refused, as R's lm.fit() refuses it
throws_ok { lm(formula => 'y ~ x', data => { y => [1, 2, $INF, 4], x => [1, 2, 3, 4] }) }
	qr/^lm: NA\/NaN\/Inf in 'y' \(row '3'\)/, "Inf in y croaks with R's message";
throws_ok { lm(formula => 'y ~ x', data => { y => [1, 2, 3, 4], x => [1, 2, -$INF, 4] }) }
	qr/^lm: NA\/NaN\/Inf in 'x' \(row '3'\)/, "-Inf in x croaks with R's message";
throws_ok { lm(formula => 'y ~ x', data => { y => [1, 2, 3, 4], x => [1, 2, 'Inf', 4] }) }
	qr/^lm: NA\/NaN\/Inf in 'x'/, 'the string "Inf" counts as infinite';
throws_ok { lm(formula => 'y ~ I(x^-1)', data => { y => [1, 2, 3, 4], x => [1, 0, 3, 4] }) }
	qr/^lm: NA\/NaN\/Inf in 'x' \(row '2'\)/, 'I(x^-1) at x = 0 is Inf, not a dropped row';
# NaN is missing, not infinite: its row is dropped, as na.omit drops it
{
	my $r = lm(formula => 'y ~ x', data => { y => [1, 2, 'NaN', 4, 6], x => [1, 2, 3, 4, 5] });
	is($r->{'df.residual'}, 2, 'NaN in y drops its row');
}

# Zero residual degrees of freedom is still refused, with the rank as the test
throws_ok { lm(formula => 'y ~ x + z', data => { y => [1, 2], x => [1, 2], z => [2, 4] }) }
	qr/0 degrees of freedom/, 'rank 2 on 2 rows croaks';

# Exact zero residuals: see exact_inf above.  Columns: case, y, t per
# coefficient, p per coefficient; undef is NaN.
for my $c (['exact_inf',     [0, 0, 2, 2],     [undef, $INF],  [undef, 0]],
           ['exact_neg_inf', [-3, -3, -5, -5], [-$INF, -$INF], [0, 0]]) {
	my ($key, $y, $t, $p) = @$c;
	my $r = lm(formula => 'y ~ x', data => { x => [0, 0, 1, 1], y => $y });
	my @n = ('Intercept', 'x');
	for my $j (0, 1) {
		my $s = $r->{summary}{ $n[$j] };
		is($s->{'Std. Error'}, 0, "$key: $n[$j] std. error is exactly 0");
		if (!defined $t->[$j]) {
			ok(is_nanish($s->{'t value'}),  "$key: $n[$j] t is NaN (0/0)");
			ok(is_nanish($s->{'Pr(>|t|)'}), "$key: $n[$j] p is NaN");
		} else {
			is($s->{'t value'},  $t->[$j], "$key: $n[$j] t is " . ($t->[$j] > 0 ? '+' : '-') . 'Inf');
			is($s->{'Pr(>|t|)'}, $p->[$j], "$key: $n[$j] p is 0");
		}
	}
	is($r->{rss}, 0, "$key: rss is exactly 0");
	is($r->{'r.squared'}, 1, "$key: R^2 is 1");
	is($r->{fstatistic}[0], $INF, "$key: F is Inf");
	is($r->{'f.pvalue'}, 0, "$key: F's p is 0");
}

# The croaks above run after every allocation is made; none may leak
no_leaks_ok { eval { lm(formula => 'y ~ x', data => { y => [1, 2, $INF, 4], x => [1, 2, 3, 4] }) } }
	'no leak on the non-finite croak';
no_leaks_ok { eval { lm(formula => 'y ~ x + z', data => { y => [1, 2], x => [1, 2], z => [2, 4] }) } }
	'no leak on the 0 df croak';
no_leaks_ok { lm(formula => 'y ~ x + z', data => { y => [1, 2, 4], x => [1, 2, 3], z => [2, 4, 6] }) }
	'no leak on a rank-deficient fit';

done_testing();
