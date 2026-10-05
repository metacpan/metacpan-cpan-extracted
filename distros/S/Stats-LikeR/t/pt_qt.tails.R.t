#!/usr/bin/env perl
# pt() and qt() in the far tail, against R 4.6.1.
#
# Provenance: every expected value below was produced by t/pt_qt.tails.R.R
# (committed next to this file) under R 4.6.1 (2026-06-24) at
# options(digits = 17), except the two rows marked ADJUDICATED, which are
# mpmath 1.3 at mp.dps = 60.  Re-run the generator with
#     Rscript t/pt_qt.tails.R.R
# This test never invokes R, python3 or mpmath; it reads the frozen literals.
#
# What it pins.  Through 0.31, pt_upper() formed the tail as
# I_z(df/2, 1/2) with z = df/(df + t*t) and nothing else.  z underflows in the
# far tail and t*t overflows outright past sqrt(DBL_MAX) = 1.3407807929942597e154,
# so incbeta() was handed z = 0 and returned a flat 0:
#
#   pt(-1e160, 1)   gave 0            where the tail is 3.1830988618378451e-161
#   pt(-1e300, 1)   gave 0            where the tail is 3.1830988618377598e-301
#
# qt_tail() bisects against pt_upper(), and its doubling loop stopped at that
# same sqrt(DBL_MAX).  The bracket therefore saturated with the root still
# above it, and the bisection converged onto the ceiling and returned it as an
# answer -- indistinguishable, to a caller, from a converged one:
#
#   qt(1e-160, 1)   gave -1.3407807929942597e154   for -3.1830988618379068e159
#   qt(1e-300, 1)   gave -1.3407807929942597e154   for -3.183098861837907e299
#   qt(1e-16, 0.1)  gave -1.3407807929942597e154   for -1.6044257056664863e156
#
# The explicit saturation checks at the end are the point of the file: a
# regression here would not fail the table (the ceiling is a plausible number)
# unless something asks whether the ceiling is being returned.
#
# ADJUDICATED.  Two rows are mpmath's, not R's, because R and Stats::LikeR
# disagree there and R is the one in error.  Solving P(T > t) = p by bisection
# on the defining incomplete beta at mp.dps = 60 (not via any library inverse):
#
#   qt(1e-300, 5):   mpmath -1.5683925590993378011e+60
#                    LikeR  rel 2.366e-14      R 4.6.1  rel 1.804e-09
#   qt(1e-300, 10):  mpmath -2.5645257189481978216e+30
#                    LikeR  rel 9.740e-15      R 4.6.1  rel 1.179e-11
#
# R's qt() stops refining early that far out; the divergence is recorded here
# rather than absorbed into a tolerance, so that changing it later is
# deliberate.
#
# Tolerance.  1e-12 relative, against a worst observed disagreement of
# 9.844e-14 (pt, at df = 100) and 9.553e-14 (qt, at df = 1) on the double
# build -- about 10x headroom, which is what the long-double and __float128
# builds need: qt_tail() stops where pt_upper()'s rounding does, so its last
# bits move with NV width.
#
# Why the table stops at 1e-290.  The generator drops any expected value
# smaller than that, and both reasons are about the table rather than about
# pt() or qt().  They cost nothing here -- the collapse being pinned sets in
# at |t| > 1.3407807929942597e154 and is caught many rows above the floor --
# but they are worth knowing before adding a row below it.
#
#  * perl 5.10.1 misparses the literal.  Its numeric parser holds to the last
#    ulp or two down to about 1e-290 and then collapses:
#    3.1830988618377598e-295 becomes 2.9999999999999982e-295, off by 5.75e-02,
#    and past 1e-310 it yields 0.  A frozen table is decimal literals, so
#    below the floor the test is not comparing against the number in the file.
#    Mantissa-1 inputs such as 1e-300 survive to 6.4e-16 and so remain.
#
#  * below DBL_MIN = 2.2e-308 a double is subnormal and carries only a few
#    significant bits, so R's value is not the one a long-double or
#    __float128 build computes.  pt(-1e160, 2) is 4.999944335913415e-321 in R
#    and 5e-321 on the wider builds: a relative 1.1e-05 that is the double's
#    missing mantissa and nothing else.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(pt qt);

my $TOL = 1e-12;   # justified in the header

sub rel_ok {
	my ($got, $exp, $name) = @_;
	my $rel = $exp == 0 ? abs($got) : abs($got - $exp) / abs($exp);
	ok($rel <= $TOL, $name)
		or diag(sprintf "got %.17g, expected %.17g, rel %.3e", $got, $exp, $rel);
}

# [t, df, pt(t, df)]
my @PT = (
	[-1, 0.5, 0.30112161084132205],
	[-10, 0.5, 0.10133867638566559],
	[-1000, 0.5, 0.010141454540857096],
	[-10000000000, 0.5, 3.2070097541422295e-06],
	[-1.0000000000000001e+50, 0.5, 3.2070097541422051e-26],
	[-1e+100, 0.5, 3.2070097541422416e-51],
	[-9.9999999999999998e+149, 0.5, 3.2070097541423238e-76],
	[-1e+154, 0.5, 3.2070097541422939e-78],
	[-1.3407807929942597e+154, 0.5, 2.7696276794605102e-78],
	[-1e+155, 0.5, 1.0141455301466312e-78],
	[-1e+160, 0.5, 3.2070097541422949e-81],
	[-9.9999999999999997e+199, 0.5, 3.2070097541422692e-101],
	[-9.9999999999999992e+249, 0.5, 3.2070097541422149e-126],
	[-1e+280, 0.5, 3.2070097541421277e-141],
	[-1.0000000000000001e+300, 0.5, 3.2070097541422515e-151],
	[-1, 1, 0.24999999999999978],
	[-10, 1, 0.03172551743055356],
	[-1000, 1, 0.00031830978008055887],
	[-10000000000, 1, 3.1830988618379065e-11],
	[-1.0000000000000001e+50, 1, 3.1830988618378932e-51],
	[-1e+100, 1, 3.1830988618379209e-101],
	[-9.9999999999999998e+149, 1, 3.1830988618379033e-151],
	[-1e+154, 1, 3.1830988618378438e-155],
	[-1.3407807929942597e+154, 1, 2.3740635892682652e-155],
	[-1e+155, 1, 3.183098861837874e-156],
	[-1e+160, 1, 3.1830988618378451e-161],
	[-9.9999999999999997e+199, 1, 3.183098861837795e-201],
	[-9.9999999999999992e+249, 1, 3.1830988618376868e-251],
	[-1e+280, 1, 3.1830988618375133e-281],
	[-1, 2, 0.21132486540518713],
	[-10, 2, 0.0049262285116628462],
	[-1000, 2, 4.9999925000125002e-07],
	[-10000000000, 2, 4.9999999999999997e-21],
	[-1.0000000000000001e+50, 2, 4.9999999999999988e-101],
	[-1e+100, 2, 4.9999999999998897e-201],
	[-1, 5, 0.18160873382456127],
	[-10, 5, 8.5473787871481787e-05],
	[-1000, 5, 9.490065565989865e-15],
	[-10000000000, 5, 9.4901672455624471e-50],
	[-1.0000000000000001e+50, 5, 9.4901672455623721e-250],
	[-1, 30, 0.16265430771301492],
	[-10, 30, 2.2876257041148048e-11],
	[-1000, 30, 1.0360017415558858e-69],
	[-10000000000, 30, 1.0364534652561783e-279],
	[-1, 100, 0.15986207789206186],
	[-10, 100, 4.9508444922970468e-17],
	[-1000, 100, 3.9598093039741064e-202],
);

# [p, df, qt(p, df)]
my @QT = (
	[9.9999999999999998e-17, 0.10000000000000001, -1.6044257056664863e+156],
	[1e-08, 0.10000000000000001, -1.6044257056666033e+76],
	[0.001, 0.10000000000000001, -1.6044257056665733e+26],
	[0.025000000000000001, 0.10000000000000001, -1682362288745.0776],
	[0.25, 0.10000000000000001, -168.23607319770966],
	[1e-100, 0.5, -1.0284911563163961e+199],
	[1e-50, 0.5, -1.0284911563163468e+99],
	[9.9999999999999998e-17, 0.5, -1.0284911563163187e+31],
	[1e-08, 0.5, -1028491156316320],
	[0.001, 0.5, -102849.11563017513],
	[0.025000000000000001, 0.5, -164.55767348049446],
	[0.25, 0.5, -1.5537739740300793],
	[1e-300, 1, -3.183098861837907e+299],
	[9.9999999999999998e-201, 1, -3.1830988618379068e+199],
	[9.9999999999999999e-161, 1, -3.1830988618379068e+159],
	[1e-155, 1, -3.1830988618379068e+154],
	[1e-100, 1, -3.1830988618379069e+99],
	[1e-50, 1, -3.1830988618379065e+49],
	[9.9999999999999998e-17, 1, -3183098861837907],
	[1e-08, 1, -31830988.618379056],
	[0.001, 1, -318.30883898555044],
	[0.025000000000000001, 1, -12.706204736174707],
	[0.25, 1, -1],
	[1e-300, 2, -7.0710678118654748e+149],
	[9.9999999999999998e-201, 2, -7.0710678118654751e+99],
	[9.9999999999999999e-161, 2, -7.0710678118654754e+79],
	[1e-155, 2, -2.2360679774997899e+77],
	[1e-100, 2, -7.0710678118654751e+49],
	[1e-50, 2, -7.0710678118654747e+24],
	[9.9999999999999998e-17, 2, -70710678.118654743],
	[1e-08, 2, -7071.0677057994581],
	[0.001, 2, -22.327124770119873],
	[0.025000000000000001, 2, -4.3026527297494637],
	[0.25, 2, -0.81649658092772592],
	[1e-300, 5, -1.5683925590993378011e+60],
	[9.9999999999999998e-201, 5, -1.5683925590993379e+40],
	[9.9999999999999999e-161, 5, -1.568392559099347e+32],
	[1e-155, 5, -1.5683925590993469e+31],
	[1e-100, 5, -1.5683925590993401e+20],
	[1e-50, 5, -15683925590.993368],
	[9.9999999999999998e-17, 5, -2485.7338279612068],
	[1e-08, 5, -62.404506110967276],
	[0.001, 5, -5.8934295313560101],
	[0.025000000000000001, 5, -2.570581835636315],
	[0.25, 5, -0.72668684380042292],
	[1e-300, 10, -2.5645257189481978216e+30],
	[9.9999999999999998e-201, 10, -2.5645257189482057e+20],
	[9.9999999999999999e-161, 10, -25645257189482020],
	[1e-155, 10, -8109742389957140],
	[1e-100, 10, -25645257189.482021],
	[1e-50, 10, -256452.57187694783],
	[9.9999999999999998e-17, 10, -102.05070688222636],
	[1e-08, 10, -15.895687652513544],
	[0.001, 10, -4.1437004940465894],
	[0.025000000000000001, 10, -2.2281388519862744],
	[0.25, 10, -0.69981206131243168],
	[1e-300, 30, -50178575360.505234],
	[9.9999999999999998e-201, 30, -23290831.507991228],
	[9.9999999999999999e-161, 30, -1081064.6345170753],
	[1e-155, 30, -736520.76162495487],
	[1e-100, 30, -10810.645001144016],
	[1e-50, 30, -232.84591679865159],
	[9.9999999999999998e-17, 30, -16.264942502976727],
	[1e-08, 30, -7.5565346518854017],
	[0.001, 30, -3.3851848668293054],
	[0.025000000000000001, 30, -2.0422724563012382],
	[0.25, 30, -0.68275569332129227],
);

plan tests => scalar(@PT) + scalar(@QT) + 8;

for my $r (@PT) {
	rel_ok(pt($r->[0], $r->[1]), $r->[2],
	       sprintf("pt(%.17g, %g)", $r->[0], $r->[1]));
}
for my $r (@QT) {
	rel_ok(qt($r->[0], $r->[1]), $r->[2],
	       sprintf("qt(%.17g, %g)", $r->[0], $r->[1]));
}

# The saturation constant itself.  sqrt(DBL_MAX) was the old ceiling; on a
# long-double or __float128 build the bisection never had a reason to stop
# there either, so this is the same assertion at every NV width.
my $CEILING = 1.3407807929942597e154;
for my $c ([1e-160, 1], [1e-300, 1], [1e-16, 0.1], [1e-200, 1]) {
	my $q = qt($c->[0], $c->[1]);
	ok(abs(abs($q) - $CEILING) > 1e140,
	   sprintf("qt(%g, %g) is not the saturated sqrt(DBL_MAX) ceiling", @$c))
		or diag(sprintf "got %.17g, which is the old ceiling", $q);
}

# pt() must not collapse to zero where the tail is representable.
# These four sit below the 1e-290 floor the frozen table observes (see the
# header), so they carry no expected literal -- but "is it still exactly 0?"
# needs none, and 0 is precisely what the old code returned for all of them.
for my $c ([-1e160, 1], [-1e200, 1], [-1e300, 1], [-1e160, 2]) {
	cmp_ok(pt($c->[0], $c->[1]), '>', 0,
	       sprintf("pt(%g, %g) does not underflow to 0", @$c));
}
