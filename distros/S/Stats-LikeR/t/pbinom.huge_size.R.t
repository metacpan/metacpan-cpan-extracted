#!/usr/bin/env perl
# pbinom() with a size beyond a 32-bit long, against R 4.6.1.
#
# Provenance: values produced by R 4.6.1 with options(digits=17), as
# pbinom(q, size, prob), pbinom(..., lower.tail=FALSE) and pbinom(...,
# log.p=TRUE); columns are [q, size, prob, lower, upper, log lower].  Before
# the fix any size > LONG_MAX was NaN, which is 2**31-1 on Windows and i686.
#
# Tolerance: relative 1e-12.  Worst observed disagreement is 1.4e-15 on a
# double perl (the incomplete beta differs from R's TOMS 708 in the last
# digits); the headroom covers long double and quadmath builds.  The
# log-scale column near 0 (q = 2^31-1, upper 6.6e-112) is compared relative too.
#
# That row's prob is 1 - 2**-23, written as an expression: its upper tail is
# prob**size, so a prob that is not exactly representable (0.9999999 was tried
# first) is a different number on a long double or quadmath perl and moved the
# answer by 5.7e-9 there.  For this row mpmath (mp.dps = 60) gives
# 6.61616010133984559e-112, 2.6e-14 from R's value, well inside the tolerance.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

sub rel_ok {
	my ($got, $exp, $name) = @_;
	my $err = $exp == 0 ? abs($got) : abs(($got - $exp) / $exp);
	ok($err <= 1e-12, $name) or diag("got $got expected $exp rel err $err");
}
my @cases = (
	[5, 1e19, 1.0000000000000001e-18, 0.067085962879032124, 0.93291403712096788, -2.701780453923051],
	[3, 2147483648, 1.0000000000000001e-09, 0.82957825325384593, 0.17042174674615407, -0.18683783594240838],
	[10, 4294967296, 2.0000000000000001e-09, 0.75335691602476729, 0.24664308397523271, -0.28321617141623351],
	[2147483653, 4294967296, 0.5, 0.50006696113683669, 0.49993303886316331, -0.69301326725306134],
	[7, 9007199254740992, 1.0000000000000001e-15, 0.3230544902168046, 0.67694550978319534, -1.1299342696261623],
	[2147483647, 2147483648, 1 - 2**-23, 1, 6.6161601013396735e-112, -6.6161601013396735e-112],
	[0, 1099511627776, 9.9999999999999998e-13, 0.33303368839192349, 0.66696631160807651, -1.09951162777655],
	[100, 10000000000, 1e-08, 0.52656219852999819, 0.47343780147000181, -0.64138581852615406],
);
for my $c (@cases) {
	my ($q, $n, $p, $lo, $up, $lg) = @$c;
	my $nm = "pbinom($q, $n, $p)";
	rel_ok(pbinom($q, $n, $p), $lo, "$nm lower");
	rel_ok(pbinom($q, $n, $p, lower_tail => 0), $up, "$nm upper");
	rel_ok(pbinom($q, $n, $p, log => 1), $lg, "$nm log");
}
done_testing();
