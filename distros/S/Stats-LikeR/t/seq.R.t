#!/usr/bin/env perl
#
# Cross-validation of seq() against R's base::seq().
#
# seq() is not the one-line loop it looks like.  R's version is a chain of
# eight special cases -- two different fuzz factors, three ways to end up
# with a single value, a rewrite for endpoints whose difference overflows,
# and a clamp on the last element -- and every one of them decides either how
# many values come back or where the sequence stops.  A plain
# (to - from)/by loop, which is what this module shipped up to 0.314, agrees
# with R on seq(1, 5) and disagrees on a surprising amount else.  So the
# cases below are R's own, not invented here.
#
# Provenance:
#
#   * R 4.6.1 tests/reg-tests-1a.R, the "## seq" block (moved there from
#     seq.Rd): seq(3,3,by=pi) and seq(3,3.1,by=pi) are both the single value
#     3, seq(1,6,by=3) is c(1,4), and seq(10,4.05,by=-3) is c(10,7).
#   * R 4.6.1 tests/reg-tests-1a.R, "Don MacQueen 2002-03-26":
#     length(seq(1024902010, 1024902025, by=1)) == 16.
#   * R 4.6.1 tests/reg-tests-1a.R, the "## Round" block, whose sample is
#     seq(-2, 4, by = 0.5).
#   * R 4.6.1 tests/reg-tests-1b.R, "(Deliberate) overshot in
#     seq(from, to, by) because of fuzz": every value of
#     seq(0, 1, 0.00025+5e-16) must be <= 1.  It overshot by about 2e-12 in
#     R 2.8.x and stopped short of 1 in 2.11.0; the clamp on the last
#     element, added in R 2.9.0, is what makes it land.
#   * R 4.6.1 tests/reg-tests-2.R, "seq() with NaN etc inputs now gives
#     explicit error messages": seq(NaN), seq(to = NaN), seq(NaN, NaN).
#   * R 4.6.1 src/library/base/man/seq.Rd \examples: seq(1, 9, by = 2)
#     ("matches 'end'"), seq(1, 9, by = pi) ("stays below 'end'"),
#     seq(1, 6, by = 3), seq(1.575, 5.125, by = 0.05).
#   * R 4.6.1 base::seq.default() itself for the frozen tables, generated at
#     %.17g by t/seq.R.R, which is committed next to this file; re-run that
#     script to regenerate them.  The remaining cases there are chosen to
#     reach the branches of seq.default() the citations above do not: the
#     absent-'by' route (from:to) in both directions, the four ways to a
#     single value, a subnormal step, the (to - from) overflow rewrite, and
#     the integral sequences that run past 2**31 -- exactly representable in
#     a double, but outside the IV of a perl built with use64bitint=undef,
#     which is what made 0.314 FAIL on the armv6l CPAN smokers.
#
# Python has no equivalent to cross-check against, which is why there is no
# t/seq.R.numpy.t.  numpy.arange() is half-open and carries no fuzz, so
# arange(0, 1, 0.1) is ten values ending at 0.9 where seq(0, 1, 0.1) is
# eleven ending at 1; numpy.linspace() and range() are parameterised by
# length, which is R's seq(length.out=) and not this function.  Both were
# checked (NumPy 2.5.2 numpy/_core/tests/test_multiarray.py TestArange,
# SciPy 1.18.0 has nothing of its own) before concluding it.
#
# Where this deliberately differs from R, and why, is asserted in section H
# rather than left for someone to discover.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Config;
use Stats::LikeR 'seq';

# Import no_leaks_ok at compile time so its (&;$) prototype is in scope for
# the block-style calls at the end.  Absent module -> those tests skip.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

# The tables are R's doubles.  A plain double perl reproduces them bit for
# bit, because the arithmetic is the same two operations in the same order:
# the diag() at the end reports a worst relative disagreement of exactly 0 on
# perl-5.44.0 and perl-5.42.3.  The other builds cannot, and not because the
# arithmetic is worse -- because it is done on a different number.  A
# long-double or __float128 perl parses "0.05" to its own NV, half an ulp of
# a double away from what R read, and one multiply and one add carry that
# through; an x87 build keeps the product in an 80-bit register.  So the
# comparison is toleranced rather than exact, and the tolerance is measured
# rather than chosen:
#
#   perl-5.44.0, perl-5.42.3   (double)               0
#   perl-5.10.1                (double)               1.11e-16
#   perl-5.44.0+x87            (double, 80-bit regs)  1.60e-16
#   perl-5.12.5                (long double)          1.50e-16
#   5.44.0-quadmath            (__float128)           1.50e-16
#
# 8e-16 is a little over 3 * DBL_EPSILON, five times the worst of those.  It
# is a bound on one rounding of the step plus one of the product, so it does
# not need to grow with the length of the sequence, and it must not be
# widened to make a failure go away: a real disagreement with R here would
# be a whole ulp of the step times the index, which is orders of magnitude
# larger than this.
my $REL = 8e-16;

# Lengths are integer counts and must agree exactly on every build, and they
# do, because no count here sits near the boundary R's truncation puts it on.
# Half the cases have an n = (to-from)/by that is exactly integral and are
# built from dyadic literals, so n is the same number at every NV width and
# the 1e-10 is pure margin.  Of the genuinely fuzzy ones the tightest is
# seq(0,1,0.00025+5e-16): n is 3999.9999999920, 7.9e-9 short of the 4000 that
# would add a twelve-thousandth value, where the most a wider NV can move it
# is about n * DBL_EPSILON, or 9e-13.  Four orders of magnitude of headroom.
my $worst = 0;
my $worst_at = '';
sub val_ok {
	my ($got, $want, $label) = @_;
	if ($want == 0 || $got == 0) {
		return is($got, $want, $label);      # a zero is exact or it is wrong
	}
	my $rel = abs($got - $want) / abs($want);
	($worst, $worst_at) = ($rel, $label) if $rel > $worst;
	my $pass = ok($rel <= $REL, $label);
	diag("  got $got\n want $want\n  rel $rel > $REL") unless $pass;
	return $pass;
}

# label | [ from, to, by (undef = absent) ] | every value, from R
my @FULL = (
	[ 'seq(3,3,by=pi)', [ 3, 3, 4*atan2(1,1) ],
	  [ 3 ] ],
	[ 'seq(3,3.1,by=pi)', [ 3, 3.1, 4*atan2(1,1) ],
	  [ 3 ] ],
	[ 'seq(1,6,by=3)', [ 1, 6, 3 ],
	  [ 1, 4 ] ],
	[ 'seq(10,4.05,by=-3)', [ 10, 4.05, -3 ],
	  [ 10, 7 ] ],
	[ 'seq(1024902010,1024902025,by=1)', [ 1024902010, 1024902025, 1 ],
	  [ 1024902010, 1024902011, 1024902012, 1024902013, 1024902014,
	    1024902015, 1024902016, 1024902017, 1024902018, 1024902019,
	    1024902020, 1024902021, 1024902022, 1024902023, 1024902024, 1024902025 ] ],
	[ 'seq(-2,4,by=0.5)', [ -2, 4, 0.5 ],
	  [ -2, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4 ] ],
	[ 'seq(1,9,by=2)', [ 1, 9, 2 ],
	  [ 1, 3, 5, 7, 9 ] ],
	[ 'seq(1,9,by=pi)', [ 1, 9, 4*atan2(1,1) ],
	  [ 1, 4.1415926535897931, 7.2831853071795862 ] ],
	[ 'seq(1.575,5.125,by=0.05)', [ 1.575, 5.125, 0.05 ],
	  [ 1.575, 1.625, 1.675, 1.7250000000000001, 1.7749999999999999, 1.825,
	    1.875, 1.925, 1.9750000000000001, 2.0249999999999999,
	    2.0750000000000002, 2.125, 2.1749999999999998, 2.2250000000000001,
	    2.2749999999999999, 2.3250000000000002, 2.375, 2.4249999999999998,
	    2.4750000000000001, 2.5249999999999999, 2.5750000000000002, 2.625,
	    2.6749999999999998, 2.7250000000000001, 2.7750000000000004,
	    2.8250000000000002, 2.875, 2.9249999999999998, 2.9750000000000001,
	    3.0250000000000004, 3.0750000000000002, 3.125, 3.1749999999999998,
	    3.2250000000000001, 3.2750000000000004, 3.3250000000000002, 3.375,
	    3.4249999999999998, 3.4750000000000001, 3.5250000000000004,
	    3.5750000000000002, 3.625, 3.6749999999999998, 3.7249999999999996,
	    3.7750000000000004, 3.8250000000000002, 3.875, 3.9249999999999998,
	    3.9750000000000005, 4.0250000000000004, 4.0750000000000002, 4.125,
	    4.1749999999999998, 4.2250000000000005, 4.2750000000000004,
	    4.3250000000000002, 4.375, 4.4249999999999998, 4.4750000000000005,
	    4.5250000000000004, 4.5750000000000002, 4.625, 4.6749999999999998,
	    4.7250000000000005, 4.7750000000000004, 4.8250000000000002, 4.875,
	    4.9249999999999998, 4.9750000000000005, 5.0250000000000004,
	    5.0750000000000002, 5.125 ] ],
	[ 'seq(1,5)', [ 1, 5, undef ],
	  [ 1, 2, 3, 4, 5 ] ],
	[ 'seq(5,1)', [ 5, 1, undef ],
	  [ 5, 4, 3, 2, 1 ] ],
	[ 'seq(1,1)', [ 1, 1, undef ],
	  [ 1 ] ],
	[ 'seq(2,-2)', [ 2, -2, undef ],
	  [ 2, 1, 0, -1, -2 ] ],
	[ 'seq(-1,-5)', [ -1, -5, undef ],
	  [ -1, -2, -3, -4, -5 ] ],
	[ 'seq(1.5,4.5)', [ 1.5, 4.5, undef ],
	  [ 1.5, 2.5, 3.5, 4.5 ] ],
	[ 'seq(4.5,1.5)', [ 4.5, 1.5, undef ],
	  [ 4.5, 3.5, 2.5, 1.5 ] ],
	[ 'seq(-2.5,2.5)', [ -2.5, 2.5, undef ],
	  [ -2.5, -1.5, -0.5, 0.5, 1.5, 2.5 ] ],
	[ 'seq(1,4.99)', [ 1, 4.99, undef ],
	  [ 1, 2, 3, 4 ] ],
	[ 'seq(1,4.9999999)', [ 1, 4.9999999, undef ],
	  [ 1, 2, 3, 4, 5 ] ],
	[ 'seq(1,4.9999999,by=1)', [ 1, 4.9999999, 1 ],
	  [ 1, 2, 3, 4 ] ],
	[ 'seq(4.9999999,1,by=-1)', [ 4.9999999, 1, -1 ],
	  [ 4.9999998999999997, 3.9999998999999997, 2.9999998999999997,
	    1.9999998999999997 ] ],
	[ 'seq(1,5,by=1)', [ 1, 5, 1 ],
	  [ 1, 2, 3, 4, 5 ] ],
	[ 'seq(0,1,0.1)', [ 0, 1, 0.1 ],
	  [ 0, 0.10000000000000001, 0.20000000000000001, 0.30000000000000004,
	    0.40000000000000002, 0.5, 0.60000000000000009, 0.70000000000000007,
	    0.80000000000000004, 0.90000000000000002, 1 ] ],
	[ 'seq(1,2,0.25)', [ 1, 2, 0.25 ],
	  [ 1, 1.25, 1.5, 1.75, 2 ] ],
	[ 'seq(10,5,-1)', [ 10, 5, -1 ],
	  [ 10, 9, 8, 7, 6, 5 ] ],
	[ 'seq(0.1,0.9,by=0.2)', [ 0.1, 0.9, 0.2 ],
	  [ 0.10000000000000001, 0.30000000000000004, 0.5, 0.70000000000000007,
	    0.90000000000000002 ] ],
	[ 'seq(-3,3,by=1.5)', [ -3, 3, 1.5 ],
	  [ -3, -1.5, 0, 1.5, 3 ] ],
	[ 'seq(-2,4,by=1.5)', [ -2, 4, 1.5 ],
	  [ -2, -0.5, 1, 2.5, 4 ] ],
	[ 'seq(-5,5,by=2.5)', [ -5, 5, 2.5 ],
	  [ -5, -2.5, 0, 2.5, 5 ] ],
	[ 'seq(1,3,by=0.9999999999)', [ 1, 3, 0.9999999999 ],
	  [ 1, 1.9999999999, 2.9999999998 ] ],
	[ 'seq(1,3,by=0.99999999999)', [ 1, 3, 0.99999999999 ],
	  [ 1, 1.99999999999, 2.99999999998 ] ],
	[ 'seq(0,0,by=0)', [ 0, 0, 0 ],
	  [ 0 ] ],
	[ 'seq(0,0,by=5)', [ 0, 0, 5 ],
	  [ 0 ] ],
	[ 'seq(3,3,by=0)', [ 3, 3, 0 ],
	  [ 3 ] ],
	[ 'seq(3,3,by=1)', [ 3, 3, 1 ],
	  [ 3 ] ],
	[ 'seq(0.5,0.5,by=0.5)', [ 0.5, 0.5, 0.5 ],
	  [ 0.5 ] ],
	[ 'seq(1e15,1e15+20,by=2)', [ 1e15, 1e15+20, 2 ],
	  [ 1000000000000000 ] ],
	[ 'seq(1e17,1e17+1,by=0.5)', [ 1e17, 1e17+1, 0.5 ],
	  [ 1e+17 ] ],
	[ 'seq(2,2.00000000000001,by=1e-16)', [ 2, 2.00000000000001, 1e-16 ],
	  [ 2 ] ],
	[ 'seq(3000000000,3000000010)', [ 3000000000, 3000000010, undef ],
	  [ 3000000000, 3000000001, 3000000002, 3000000003, 3000000004,
	    3000000005, 3000000006, 3000000007, 3000000008, 3000000009, 3000000010 ] ],
	[ 'seq(-3000000000,-2999999990,by=2)', [ -3000000000, -2999999990, 2 ],
	  [ -3000000000, -2999999998, -2999999996, -2999999994, -2999999992,
	    -2999999990 ] ],
	[ 'seq(-2147483646,2147483646,by=1073741823)', [ -2147483646, 2147483646, 1073741823 ],
	  [ -2147483646, -1073741823, 0, 1073741823, 2147483646 ] ],
	[ 'seq(9007199254740992,9007199254741000,by=2)', [ 9007199254740992, 9007199254741000, 2 ],
	  [ 9007199254740992 ] ],
);
# label | [ from, to, by ] | length | first four values | last four
my @ENDS = (
	[ 'seq(0,1,0.00025+5e-16)', [ 0, 1, 0.00025+5e-16 ], 4000,
	  [ 0, 0.00025000000000049999, 0.00050000000000099997,
	    0.0007500000000014999 ],
	  [ 0.99900000000199796, 0.99925000000199848, 0.9995000000019989,
	    0.99975000000199943 ] ],
	[ 'seq(0,100,0.1)', [ 0, 100, 0.1 ], 1001,
	  [ 0, 0.10000000000000001, 0.20000000000000001, 0.30000000000000004 ],
	  [ 99.700000000000003, 99.800000000000011, 99.900000000000006, 100 ] ],
	[ 'seq(1,1000,0.5)', [ 1, 1000, 0.5 ], 1999,
	  [ 1, 1.5, 2, 2.5 ],
	  [ 998.5, 999, 999.5, 1000 ] ],
	[ 'seq(1e15,1e15+200,by=2)', [ 1e15, 1e15+200, 2 ], 101,
	  [ 1000000000000000, 1000000000000002, 1000000000000004, 1000000000000006 ],
	  [ 1000000000000194, 1000000000000196, 1000000000000198, 1000000000000200 ] ],
	[ 'seq(9007199254740992,9007199254741992,by=2)', [ 9007199254740992, 9007199254741992, 2 ], 501,
	  [ 9007199254740992, 9007199254740994, 9007199254740996, 9007199254740998 ],
	  [ 9007199254741986, 9007199254741988, 9007199254741990, 9007199254741992 ] ],
);
# label | [ from, to, by ] | exponent k | every value as an integer * 2**k
my @DYADIC = (
	[ 'seq(0,2^-1066,by=2^-1070)', [ 0, 2**-1066, 2**-1070 ], -1070,
	  [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 ] ],
	[ 'seq(-(2^1023),2^1023,by=2^1019)', [ -(2**1023), 2**1023, 2**1019 ], 1019,
	  [ -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1,
	    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 ] ],
	[ 'seq(2^1023,-(2^1023),by=-(2^1019))', [ 2**1023, -(2**1023), -(2**1019) ], 1019,
	  [ 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, -1, -2, -3,
	    -4, -5, -6, -7, -8, -9, -10, -11, -12, -13, -14, -15, -16 ] ],
);
# seq() carries the prototype $$;$, so an argument list cannot be flattened
# into a call; every call site here goes through this.  An undef 'by' means
# the argument is absent, which is the from:to branch and not the same thing
# as by = 1.
sub call_row {
	my ($args) = @_;
	return defined $args->[2] ? seq($args->[0], $args->[1], $args->[2])
	                          : seq($args->[0], $args->[1]);
}

#=========================================================================
# A. R's regression-suite assertions, in the form R makes them
#=========================================================================

# tests/reg-tests-1a.R, "## seq"
{
	my @a = seq(3, 3, 4 * atan2(1, 1));
	is_deeply(\@a, [3], 'reg-tests-1a: 3 == seq(3,3,by=pi)');
	my @b = seq(3, 3.1, 4 * atan2(1, 1));
	is_deeply(\@b, [3], 'reg-tests-1a: 3 == seq(3,3.1,by=pi)');
	my @c = seq(1, 6, 3);
	is_deeply(\@c, [1, 4], 'reg-tests-1a: seq(1,6,by=3) == c(1,4)');
	my @d = seq(10, 4.05, -3);
	is_deeply(\@d, [10, 7], 'reg-tests-1a: seq(10,4.05,by=-3) == c(10,7)');
}

# tests/reg-tests-1a.R, Don MacQueen 2002-03-26
{
	my @a = seq(1024902010, 1024902025, 1);
	is(scalar @a, 16, 'reg-tests-1a: length(seq(1024902010,1024902025,by=1)) == 16');
}

# tests/reg-tests-1b.R, the deliberate overshoot.  R asserts nothing about
# the length here, only that no value passes 'to'; both are checked because
# a length one short would satisfy the inequality vacuously.
{
	my @a = seq(0, 1, 0.00025 + 5e-16);
	is(scalar @a, 4000, 'reg-tests-1b: seq(0,1,0.00025+5e-16) has 4000 values');
	my $over = grep { $_ > 1 } @a;
	is($over, 0, 'reg-tests-1b: all(seq(0,1,0.00025+5e-16) <= 1)');
	cmp_ok($a[-1], '>', 0.9989, 'reg-tests-1b: ... and it does not stop short');
}

# tests/reg-tests-2.R, "seq() with NaN etc inputs now gives explicit error
# messages".  R's seq(NaN) and seq(to=NaN) are the one-argument forms this
# XS seq() does not have, so both endpoints are exercised in the two- and
# three-argument forms instead; the messages are R's, verbatim.
{
	my $nan = 9**9**9 - 9**9**9;
	for my $c ([[$nan, 5],    qr/'from' must be a finite number/, 'seq(NaN, 5)'],
	           [[1, $nan],    qr/'to' must be a finite number/,   'seq(1, NaN)'],
	           [[$nan, $nan], qr/'from' must be a finite number/, 'seq(NaN, NaN)'],
	           [[$nan, 5, 1], qr/'from' must be a finite number/, 'seq(NaN, 5, 1)'],
	           [[1, $nan, 1], qr/'to' must be a finite number/,   'seq(1, NaN, 1)']) {
		my ($args, $re, $label) = @$c;
		eval { my @x = call_row($args); 1 };
		like($@, $re, "reg-tests-2: $label croaks like R");
	}
}

#=========================================================================
# B. Every value of every short sequence, against R's own output
#=========================================================================

for my $row (@FULL) {
	my ($label, $args, $want) = @$row;
	my @got = call_row($args);
	is(scalar @got, scalar @$want, "$label: length");
	next if @got != @$want;
	for my $i (0 .. $#got) {
		val_ok($got[$i], $want->[$i], "$label: [$i]");
	}
}

#=========================================================================
# C. Long sequences: length, and the first and last four values
#=========================================================================

for my $row (@ENDS) {
	my ($label, $args, $n, $first, $last) = @$row;
	my @got = call_row($args);
	is(scalar @got, $n, "$label: length");
	next if @got < 8;
	for my $i (0 .. $#$first) {
		val_ok($got[$i], $first->[$i], "$label: [$i]");
	}
	for my $i (0 .. $#$last) {
		my $j = @got - @$last + $i;
		val_ok($got[$j], $last->[$i], "$label: [$j]");
	}
}

#=========================================================================
# D. The two ends of the exponent range, as exact multiples of a power of 2
#=========================================================================

# R's values for these cases are exactly dyadic, and they are asserted in
# that form rather than as %.17g decimals because a decimal there would not
# survive the trip through perl: perl-5.10.1's string-to-double reads
# 7.9050503334599447e-323 as 0 and 1e307 five ulp low.  2**k is exact on
# every perl and every NV width, so an integer multiple of it is too, and
# these comparisons can be exact rather than toleranced.
for my $row (@DYADIC) {
	my ($label, $args, $k, $mult) = @$row;
	my $scale = 2 ** $k;
	my @got = call_row($args);
	is(scalar @got, scalar @$mult, "$label: length");
	next if @got != @$mult;
	my $bad = 0;
	my $first_bad = '';
	for my $i (0 .. $#got) {
		next if $got[$i] == $mult->[$i] * $scale;
		$bad++;
		$first_bad ||= sprintf ' [%d] got %s, want %s * 2**%d',
		                       $i, $got[$i], $mult->[$i], $k;
	}
	is($bad, 0, "$label: every value is exactly its multiple of 2**$k")
		or diag($first_bad);
}

#=========================================================================
# E. Every croak, with R's wording
#=========================================================================

{
	my $inf = 9**9**9;
	my $nan = $inf - $inf;
	my @croaks = (
		# non-finite endpoints (R: "'from'/'to' must be a finite number")
		[[$inf,  1, 1], qr/'from' must be a finite number/,  'from = Inf'],
		[[-$inf, 1, 1], qr/'from' must be a finite number/,  'from = -Inf'],
		[[0, $inf,  1], qr/'to' must be a finite number/,    'to = Inf'],
		[[0, -$inf, 1], qr/'to' must be a finite number/,    'to = -Inf'],
		# (to - from)/by not finite, and not the by == 0 && from == to case
		[[1, 2, 0],     qr{\Qinvalid '(to - from)/by'\E},    'by = 0, from != to'],
		[[1, 5, $nan],  qr{\Qinvalid '(to - from)/by'\E},    'by = NaN'],
		[[1, 1, $nan],  qr{\Qinvalid '(to - from)/by'\E},    'by = NaN, from == to'],
		# n < 0
		[[1, 10, -1],   qr/wrong sign in 'by' argument/,     'up with a negative by'],
		[[10, 1, 1],    qr/wrong sign in 'by' argument/,     'down with a positive by'],
		[[0, 1, -0.25], qr/wrong sign in 'by' argument/,     'fractional wrong sign'],
		# n > INT_MAX.  Every one of these used to be silently wrong: the
		# count overflowed size_t and the call returned the empty list.
		[[0, 1e30, 1],  qr/'by' argument is much too small/,  'to = 1e30, by = 1'],
		[[1, 2, 1e-12], qr/'by' argument is much too small/,  'by = 1e-12'],
		[[0, 1, 1e-11], qr/'by' argument is much too small/,  'by = 1e-11'],
		[[1, 2, 4e-10], qr/'by' argument is much too small/,  'by = 4e-10'],
		[[2, 1, -1e-11],qr/'by' argument is much too small/,  'by = -1e-11'],
	);
	for my $c (@croaks) {
		my ($args, $re, $label) = @$c;
		eval { my @x = call_row($args); 1 };
		like($@, $re, "croak: $label");
	}
	# and the from:to branch's own cap
	eval { my @x = seq(0, 2147483647); 1 };
	like($@, qr/result would be too long a vector/, 'croak: from:to longer than INT_MAX');
	# a croak must leave nothing on the stack for the caller to see
	my @after = eval { seq(1, 10, -1) };
	is(scalar @after, 0, 'croak: returns nothing');
}

#=========================================================================
# F. The Perl-visible surface
#=========================================================================

{
	# both accepted call forms, and the fact that they are not the same
	# function: an absent 'by' is from:to, whose fuzz is looser.
	my @two   = seq(1, 4.9999999);
	my @three = seq(1, 4.9999999, 1);
	is(scalar @two,   5, 'two-arg seq(1, 4.9999999) is from:to: five values');
	is(scalar @three, 4, 'three-arg seq(1, 4.9999999, 1) is the by branch: four');

	# context.  List context is the documented one; scalar context yields
	# the last value, which is what perl gives for any list-returning sub,
	# and void context yields nothing.
	my @list = seq(1, 3);
	is_deeply(\@list, [1, 2, 3], 'list context returns the whole sequence');
	my $scalar = seq(1, 10);
	is($scalar, 10, 'scalar context returns the last value');
	my $frac = seq(0, 1, 0.25);
	is($frac, 1, 'scalar context returns the last value (fractional step)');
	is(scalar(() = seq(1, 7)), 7, 'list assignment in scalar context counts 7');
	my @void_probe = do { seq(1, 5); (42) };
	is_deeply(\@void_probe, [42], 'void context returns nothing');
	# context reaches through a sub call, so a wrapper still gets a list
	my $wrap = sub { seq(1, 3) };
	my @wrapped = $wrap->();
	is_deeply(\@wrapped, [1, 2, 3], 'list context propagates through a sub');
	my $wrapped_scalar = $wrap->();
	is($wrapped_scalar, 3, 'scalar context propagates through a sub');
	# flattening into a larger list
	my @flat = (0, seq(1, 3), seq(7, 9), 10);
	is_deeply(\@flat, [0, 1, 2, 3, 7, 8, 9, 10], 'flattens into a surrounding list');
}

{
	# An exactly-integral sequence comes back as IVs, which is what R
	# returns for the integer case and what makes stringifying the result
	# five times cheaper.  A fractional one must stay NV, or 0.1 would be
	# truncated to 0.
	my $has_b = eval { require B; 1 };
	SKIP: {
		skip 'B not available', 4 unless $has_b;
		my $iok = B::SVf_IOK();
		my $nok = B::SVf_NOK();
		my $flags = sub { B::svref_2object(\$_[0])->FLAGS };
		my @int = seq(1, 5);
		is(scalar(grep { $flags->($_) & $iok } @int), 5, 'seq(1,5) is all IVs');
		my @neg = seq(5, 1);
		is(scalar(grep { $flags->($_) & $iok } @neg), 5, 'seq(5,1) is all IVs');
		my @frac = seq(0, 1, 0.1);
		is(scalar(grep { $flags->($_) & $nok } @frac), 11, 'seq(0,1,0.1) is all NVs');
		is(scalar(grep { $flags->($_) & $iok } @frac), 0,  'seq(0,1,0.1) has no IVs');
	}
	# whichever body it picks, the numbers are the numbers
	is(join(',', seq(1, 5)),       '1,2,3,4,5',   'integer sequence stringifies as integers');
	is(join(',', seq(0, 1, 0.25)), '0,0.25,0.5,0.75,1', 'fractional sequence keeps its fractions');
	# Past 2**53 an NV can no longer name every integer, so the IV path
	# gives up and the sequence comes back as NVs; its values are checked
	# against R in section C.
	SKIP: {
		skip 'B not available', 2 unless $has_b;
		my $iok = B::SVf_IOK();
		my @big = seq(9007199254740992, 9007199254741992, 2);
		is(scalar @big, 501, 'a sequence starting at 2**53 has R\'s length');
		is(scalar(grep { B::svref_2object(\$_)->FLAGS & $iok } @big), 0,
		   'a sequence starting at 2**53 is NVs, not IVs');
	}
	# 2**53 is only half of that bound: the other half is the perl's own
	# IV_MAX, which is 2147483647 where use64bitint is undef (a 32-bit-IV
	# perl -- the armv6l CPAN smokers are built that way).  Casting 1e15 to
	# such an IV is out of range, and 0.314 pushed the saturated result, so
	# seq(1e15, 1e15+200, 2) came back as 2147483647 and -2147483645 there.
	# The values are checked against R in section C; what is asserted here
	# is the body, on whichever perl happens to be running.
	SKIP: {
		skip 'B not available', 1 unless $has_b;
		my $iok = B::SVf_IOK();
		my @past = seq(3000000000, 3000000010);
		is(scalar(grep { B::svref_2object(\$_)->FLAGS & $iok } @past),
		   ($Config{ivsize} >= 8 ? 11 : 0),
		   'past 2**31: IVs where an IV is 64-bit, NVs where it is 32-bit');
	}
	is(join(',', seq(3000000000, 3000000010)),
	   '3000000000,3000000001,3000000002,3000000003,3000000004,3000000005,'
	   . '3000000006,3000000007,3000000008,3000000009,3000000010',
	   'a sequence past 2**31 keeps its values at either IV width');
	# Straddles zero with a step of the endpoints' own magnitude: every
	# element of this one fits a 32-bit IV, but from + 3*by does not, which
	# is why the fast path accumulates rather than multiplying.
	is(join(',', seq(-2147483646, 2147483646, 1073741823)),
	   '-2147483646,-1073741823,0,1073741823,2147483646',
	   'a sequence straddling zero does not overflow a 32-bit IV');
}

#=========================================================================
# G. Leaks
#=========================================================================

SKIP: {
	skip 'Test::LeakTrace not installed', 4 unless $HAVE_LEAKTRACE;
	skip 'Devel::Cover perturbs refcounts', 4 if $INC{'Devel/Cover.pm'};
	no_leaks_ok { my @x = seq(1, 5);          1 } 'seq: no leaks, integer path';
	no_leaks_ok { my @x = seq(0, 1, 0.1);     1 } 'seq: no leaks, NV path';
	no_leaks_ok { my @x = seq(5, 1);          1 } 'seq: no leaks, from:to downwards';
	no_leaks_ok { eval { my @x = seq(1, 2, 0) }; 1 } 'seq: no leaks on croak';
}

#=========================================================================
# H. Where this deliberately differs from R
#=========================================================================

{
	# R's seq() is a generic with a one-argument form (seq(17) is 1:17) and
	# a length.out= form; this seq() is from/to/by only, and says so rather
	# than guessing.
	my $one_arg = eval 'my @x = Stats::LikeR::seq(17); 1';
	ok(!$one_arg, 'one-argument seq() is an error, not R seq(17)');
	like($@, qr/\Ausage: seq\(FROM, TO \[, BY\]\).*^seq: error: expected 2 or 3 arguments/ms,
	     '... and it says so rather than guessing 1:17');

	# R caps the from:to branch at R_XLEN_T_MAX and the by branch at
	# INT_MAX + 1 elements.  EXTEND() casts its count to int on perl 5.10
	# and 5.12, so both are capped at INT_MAX here.  Nothing observable
	# hangs on the difference -- a sequence of that length needs 2.1e9 SVs
	# and cannot be built on any machine -- but the boundary is asserted so
	# that moving it is a deliberate act.
	eval { my @x = seq(0, 2147483647); 1 };
	like($@, qr/result would be too long a vector/, 'from:to caps at INT_MAX elements');

	# The "endpoints are indistinguishable" collapse keeps R's
	# 100 * DBL_EPSILON on every build rather than scaling to the perl's own
	# NV_EPSILON -- see the comment at the test in LikeR.xs.  Scaled, this
	# call returns eleven values on a long-double or __float128 perl and one
	# on a double one; pinned, it is R's single value everywhere, which is
	# the point of the function.  Asserted here so that changing it is a
	# deliberate act.
	my @collapsed = seq(1e15, 1e15 + 20, 2);
	is(scalar @collapsed, 1, 'indistinguishable endpoints collapse to one value');
	# cmp_ok, not is: on a 64-bit-IV perl an exactly integral value comes
	# back as an IV, which stringifies as 1000000000000000 where the NV
	# literal is "1e+15"; on a 32-bit-IV one it stays an NV and stringifies
	# as "1e+15".  Comparing numerically is right at both widths.
	cmp_ok($collapsed[0], '==', 1e15, '... and that value is "from"');
	my @kept = seq(1e15, 1e15 + 200, 2);
	is(scalar @kept, 101, 'distinguishable endpoints do not collapse');
}

diag(sprintf('worst relative disagreement with R: %.3g%s',
             $worst, $worst ? " at $worst_at" : ''));

done_testing();
