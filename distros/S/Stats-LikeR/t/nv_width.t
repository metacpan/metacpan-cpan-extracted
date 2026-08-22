#!/usr/bin/env perl
#
# The XS must compute at the width NV actually is.
#
# C has no type-generic <math.h>, so a bare sqrt()/log()/lgamma() call takes a
# double.  On a perl built with -Duselongdouble or -Dusequadmath that silently
# rounds every NV down to 53 bits of mantissa, computes there, and converts
# back: no warning, no build failure, just answers that are quietly less
# accurate than the perl running them.  LikeR.xs routes every NV-valued libm
# call through the nv_* macros for exactly this reason, and Makefile.PL
# link-tests the long double variants before enabling them.
#
# This file fails if that ever comes undone.  It is width-adaptive rather than
# skipped on a plain double perl: there NV is a double, the assertions below
# are simply satisfied by everyone, and they still guard against a change that
# would break the wide builds.
#
# Numbers quoted in the tolerances were measured on perl-5.12.5 (long double,
# NV epsilon 1.08e-19), built both ways:
#
#                                   width-correct        narrowed to double
#   sd(1..5) == sqrt(2.5)           exactly equal        not equal
#   fisher_test 2x2 vs exact 17/35  6.4e-18 relative     1.5e-16 relative
#
# The sqrt check is the sharp one -- exact NV equality, no tolerance to tune.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(sd var mean fisher_test);

# NV epsilon at this build's width, computed rather than assumed: 2.22e-16 for
# double, 1.08e-19 for x86 long double, 1.93e-34 for __float128.
my $EPS = 1.0;
$EPS /= 2 while (1.0 + $EPS / 2) != 1.0;
my $WIDE = $EPS < 1e-17;   # NV is wider than a double on this perl

diag(sprintf 'NV epsilon = %.4g%s', $EPS, $WIDE ? ' (NV is wider than double)' : '');

# ---------------------------------------------------------------------------
# 1. sqrt.  sd(1..5) is sqrt(sum((x-3)^2)/4) = sqrt(10/4); 10 and 4 and 2.5 are
#    all exact in binary at every width, so the module's answer must be the
#    identical NV to perl's own sqrt(2.5) -- perl's sqrt goes through
#    Perl_sqrt, which is width-correct.  Narrowing shows up here immediately:
#    the module returns the double-rounded root instead, which differs in the
#    17th significant digit.
# ---------------------------------------------------------------------------
is(sd(1 .. 5), sqrt(2.5), 'sd(1..5) is exactly perl sqrt(2.5) at NV width');
is(sd([1 .. 5]), sqrt(2.5), 'sd([1..5]) via an array ref is exactly sqrt(2.5) too');

# var is pure arithmetic with no libm in it, so it must be exact on any build;
# if this ever fails the problem is not the math width.
is(var(1 .. 5), 2.5, 'var(1..5) is exactly 2.5');
is(mean(1 .. 5), 3, 'mean(1..5) is exactly 3');

# ---------------------------------------------------------------------------
# 2. lgamma and exp.  Fisher's exact test on [[3,1],[1,3]] has the closed-form
#    two-sided p-value 17/35 (R: fisher.test(matrix(c(3,1,1,3),2))$p.value =
#    0.4857142857142857).  The XS reaches it through lgamma()/exp(), so its
#    accuracy tracks the width those are computed at, while 17/35 evaluated in
#    perl is correct to one NV ulp.
# ---------------------------------------------------------------------------
#    The limit here is an absolute relative error rather than a multiple of
#    NV epsilon, because fisher_test()'s summation has an accuracy floor of its
#    own at about 6.4e-18 -- measured identically on the long double and the
#    __float128 build, so it is the algorithm rather than the math width (the
#    quadmath object was checked with nm: it references lgammaq/expq/sqrtq and
#    no double-width libm symbol at all).  A double-precision computation of
#    this p-value lands at 1.5e-16, which is 20x worse than that floor, so 5e-17
#    separates the two cleanly on any wide build.
{
	my $res = fisher_test([[3, 1], [1, 3]]);
	my $p = ref $res ? ($res->{p_value} // $res->{p}) : $res;
	my $exact = 17 / 35;
	my $rel = abs($p - $exact) / $exact;
	# On a double perl the module is *expected* to land near 1.5e-16; there is
	# no narrowing to detect, so this only checks the value is broadly right.
	my $limit = $WIDE ? 5e-17 : 1e-14;
	ok($rel <= $limit,
	   sprintf 'fisher_test 2x2 p-value vs exact 17/35: rel err %.3g <= %.0e', $rel, $limit)
		or diag(sprintf "got   %.34g\nwant  %.34g\nrel   %.4g (%.4g NV eps)",
		                $p, $exact, $rel, $rel / $EPS);
}

# ---------------------------------------------------------------------------
# 3. Float classification.  nv_isnan/nv_isinf/nv_isfinite compare against
#    NV_MAX and so know how wide an NV is; the bare C99 macros are type-generic
#    on glibc but are plain double functions where a platform does not provide
#    them, and narrowing a large-but-finite long double into one of those
#    reports it as infinite.  (perl's own Perl_isnan/Perl_isinf/Perl_isfinite
#    are not usable here either: see the comment above nv_isnan in LikeR.xs.)
#    Only a wide build can express such a value, so this section is skipped on
#    a double perl -- and on glibc it passes either way, which is why the
#    section is a guard for other platforms rather than a local detector.
# ---------------------------------------------------------------------------
SKIP: {
	skip 'NV is a double here: no value is finite for NV but infinite for double', 3
		unless $WIDE;
	my $big = "9e400" + 0;          # finite as a long double, +Inf as a double
	my $inf = "9e9999" + 0;
	ok($big < $inf, '9e400 is finite at NV width');
	is(mean($big, $big), $big, 'mean() treats a beyond-double-range NV as finite');
	is(var($big, $big), 0, 'var() of two equal huge NVs is 0, not NaN');
}

# ---------------------------------------------------------------------------
# 4. NaN and Inf still classify correctly, on every width.
# ---------------------------------------------------------------------------
{
	my $nan = "NaN" + 0;
	my $inf = "Inf" + 0;
	ok($nan != $nan, 'NaN is available on this build');
	ok($inf > 0 && $inf == $inf * 2, 'Inf is available on this build');
	my $m = mean(1, 2, $inf);
	ok($m == $inf || $m != $m, 'mean() with an Inf gives Inf or NaN, not a finite number')
		or diag("got $m");
}

done_testing();
