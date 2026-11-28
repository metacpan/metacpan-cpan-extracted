#!/usr/bin/env perl
# A value exactly halfway between two printed results rounds to the even one,
# whatever the platform's C library does.
#
# 0.3431 failed t/table_one.R.datasets.t 120 on Strawberry Perl 5.24
# (MSWin32-x64-multi-thread): 18 of 32 is exactly 56.25%, and its MSVCRT
# printf rounds that tie away from zero, to "56.3%", where glibc, UCRT and R
# give "56.2%".  table_one(), summary() and write_table(tex_format => 1) now
# format through Stats::LikeR::_format_nv (sv_set_nv_even() in LikeR.xs).
#
# On Linux these pass with or without the fix, since glibc already rounds
# ties to even.  To see them fail, emulate the MSVCRT with an LD_PRELOAD shim
# whose __vsnprintf_chk and __sprintf_chk move an exact %.Nf or %.Ng tie one
# ulp away from zero before formatting; 0.3431 under it fails this file and
# t/table_one.R.datasets.t 120, and nothing else.
#
# The same MSVCRT prints every exponent with at least three digits, so 0.35
# failed 33 subtests here (the %g rows, summary() and write_table()) with
# "1.234e+004" for "1.234e+04"; sv_set_nv_even() now trims it to two, as
# C99, glibc, UCRT and R print it.  The rows from 1e+05 on add exponents
# that are not ties, including three-digit ones, which must stay three.  An
# LD_PRELOAD shim whose vsnprintf, vsprintf, snprintf, sprintf and their
# _chk forms insert a 0 into a two-digit exponent, for a format that is one
# %e or %g conversion, makes 0.35 fail exactly those 33 subtests and nothing
# else in the suite.  An unbounded sprintf must go to the real vsprintf, not
# to vsnprintf with a huge size, or glibc truncates perl's stringification.
#
# Provenance: every expected string is R 4.6.2's sprintf() on glibc (Linux),
# printed by t/format.ties.R.R; run `Rscript t/format.ties.R.R` to reproduce
# @R.  The inputs follow R's own documentation and tests:
#   - R 4.6.1 src/library/base/man/Round.Rd, the example
#     round(.5 + -2:4) == c(-2, 0, 0, 2, 2, 4, 4) ("IEEE / IEC rounding"),
#     divided by 2^k for ties at k decimals and scaled by 10^e for ties at
#     one significant digit; for e < 0 those are near-ties, as Round.Rd's
#     round(0.15, 1) is, rounded by their stored value;
#   - R 4.6.1 tests/reg-tests-3.R, sprintf("%.7g"/"%.5g"/"%.4g", 12345.6789);
#   - the 56.25% of the failing report, and summary()'s statistics of
#     c(1.0625, 2, 12345) as R's quantile() and mean() give them.
#   - for exponent widths, 1e5, 2^-30, 2^400 and 2^-900, chosen here (no R
#     test pins %g exponents), at 1, 4 and 15 significant digits.
# Each input is written n / 2**s, exact on every perl (see the generator).
#
# Tolerance: none; strings are compared exactly.
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(:all);

# [style, precision, n, s, R's sprintf("%.<precision><style>", n / 2^s)]
my @R = (
	['f', 0, -3, 1, '-2'], # -1.5
	['f', 0, -1, 1, '-0'], # -0.5
	['f', 0, 1, 1, '0'], # 0.5
	['f', 0, 3, 1, '2'], # 1.5
	['f', 0, 5, 1, '2'], # 2.5
	['f', 0, 7, 1, '4'], # 3.5
	['f', 0, 9, 1, '4'], # 4.5
	['f', 1, -3, 2, '-0.8'], # -0.75
	['f', 1, -1, 2, '-0.2'], # -0.25
	['f', 1, 1, 2, '0.2'], # 0.25
	['f', 1, 3, 2, '0.8'], # 0.75
	['f', 1, 5, 2, '1.2'], # 1.25
	['f', 1, 7, 2, '1.8'], # 1.75
	['f', 1, 9, 2, '2.2'], # 2.25
	['f', 2, -3, 3, '-0.38'], # -0.375
	['f', 2, -1, 3, '-0.12'], # -0.125
	['f', 2, 1, 3, '0.12'], # 0.125
	['f', 2, 3, 3, '0.38'], # 0.375
	['f', 2, 5, 3, '0.62'], # 0.625
	['f', 2, 7, 3, '0.88'], # 0.875
	['f', 2, 9, 3, '1.12'], # 1.125
	['f', 3, -3, 4, '-0.188'], # -0.1875
	['f', 3, -1, 4, '-0.062'], # -0.0625
	['f', 3, 1, 4, '0.062'], # 0.0625
	['f', 3, 3, 4, '0.188'], # 0.1875
	['f', 3, 5, 4, '0.312'], # 0.3125
	['f', 3, 7, 4, '0.438'], # 0.4375
	['f', 3, 9, 4, '0.562'], # 0.5625
	['f', 4, -3, 5, '-0.0938'], # -0.09375
	['f', 4, -1, 5, '-0.0312'], # -0.03125
	['f', 4, 1, 5, '0.0312'], # 0.03125
	['f', 4, 3, 5, '0.0938'], # 0.09375
	['f', 4, 5, 5, '0.1562'], # 0.15625
	['f', 4, 7, 5, '0.2188'], # 0.21875
	['f', 4, 9, 5, '0.2812'], # 0.28125
	['f', 5, -3, 6, '-0.04688'], # -0.046875
	['f', 5, -1, 6, '-0.01562'], # -0.015625
	['f', 5, 1, 6, '0.01562'], # 0.015625
	['f', 5, 3, 6, '0.04688'], # 0.046875
	['f', 5, 5, 6, '0.07812'], # 0.078125
	['f', 5, 7, 6, '0.10938'], # 0.109375
	['f', 5, 9, 6, '0.14062'], # 0.140625
	['f', 6, -3, 7, '-0.023438'], # -0.0234375
	['f', 6, -1, 7, '-0.007812'], # -0.0078125
	['f', 6, 1, 7, '0.007812'], # 0.0078125
	['f', 6, 3, 7, '0.023438'], # 0.0234375
	['f', 6, 5, 7, '0.039062'], # 0.0390625
	['f', 6, 7, 7, '0.054688'], # 0.0546875
	['f', 6, 9, 7, '0.070312'], # 0.0703125
	['g', 1, -3458764513820541, 61, '-0.002'], # -0.0015
	['g', 1, -1152921504606847, 61, '-0.0005'], # -0.00050000000000000001
	['g', 1, 1152921504606847, 61, '0.0005'], # 0.00050000000000000001
	['g', 1, 3458764513820541, 61, '0.002'], # 0.0015
	['g', 1, 5764607523034235, 61, '0.003'], # 0.0025000000000000001
	['g', 1, 8070450532247929, 61, '0.004'], # 0.0035000000000000001
	['g', 1, 1297036692682703, 58, '0.005'], # 0.0045000000000000005
	['g', 1, -1080863910568919, 56, '-0.01'], # -0.014999999999999999
	['g', 1, -5764607523034235, 60, '-0.005'], # -0.0050000000000000001
	['g', 1, 5764607523034235, 60, '0.005'], # 0.0050000000000000001
	['g', 1, 1080863910568919, 56, '0.01'], # 0.014999999999999999
	['g', 1, 3602879701896397, 57, '0.03'], # 0.025000000000000001
	['g', 1, 1261007895663739, 55, '0.04'], # 0.035000000000000003
	['g', 1, 3242591731706757, 56, '0.04'], # 0.044999999999999998
	['g', 1, -1351079888211149, 53, '-0.2'], # -0.15000000000000002
	['g', 1, -3602879701896397, 56, '-0.05'], # -0.050000000000000003
	['g', 1, 3602879701896397, 56, '0.05'], # 0.050000000000000003
	['g', 1, 1351079888211149, 53, '0.2'], # 0.15000000000000002
	['g', 1, 1, 2, '0.2'], # 0.25
	['g', 1, 6305039478318695, 54, '0.4'], # 0.35000000000000003
	['g', 1, 8106479329266893, 54, '0.5'], # 0.45000000000000001
	['g', 1, -3, 1, '-2'], # -1.5
	['g', 1, -1, 1, '-0.5'], # -0.5
	['g', 1, 1, 1, '0.5'], # 0.5
	['g', 1, 3, 1, '2'], # 1.5
	['g', 1, 5, 1, '2'], # 2.5
	['g', 1, 7, 1, '4'], # 3.5
	['g', 1, 9, 1, '4'], # 4.5
	['g', 1, -15, 0, '-2e+01'], # -15
	['g', 1, -5, 0, '-5'], # -5
	['g', 1, 5, 0, '5'], # 5
	['g', 1, 15, 0, '2e+01'], # 15
	['g', 1, 25, 0, '2e+01'], # 25
	['g', 1, 35, 0, '4e+01'], # 35
	['g', 1, 45, 0, '4e+01'], # 45
	['g', 1, -75, -1, '-2e+02'], # -150
	['g', 1, -25, -1, '-5e+01'], # -50
	['g', 1, 25, -1, '5e+01'], # 50
	['g', 1, 75, -1, '2e+02'], # 150
	['g', 1, 125, -1, '2e+02'], # 250
	['g', 1, 175, -1, '4e+02'], # 350
	['g', 1, 225, -1, '4e+02'], # 450
	['g', 1, -375, -2, '-2e+03'], # -1500
	['g', 1, -125, -2, '-5e+02'], # -500
	['g', 1, 125, -2, '5e+02'], # 500
	['g', 1, 375, -2, '2e+03'], # 1500
	['g', 1, 625, -2, '2e+03'], # 2500
	['g', 1, 875, -2, '4e+03'], # 3500
	['g', 1, 1125, -2, '4e+03'], # 4500
	['g', 1, -1875, -3, '-2e+04'], # -15000
	['g', 1, -625, -3, '-5e+03'], # -5000
	['g', 1, 625, -3, '5e+03'], # 5000
	['g', 1, 1875, -3, '2e+04'], # 15000
	['g', 1, 3125, -3, '2e+04'], # 25000
	['g', 1, 4375, -3, '4e+04'], # 35000
	['g', 1, 5625, -3, '4e+04'], # 45000
	['g', 4, 17, 4, '1.062'], # 1.0625
	['g', 4, 19, 4, '1.188'], # 1.1875
	['g', 4, -17, 4, '-1.062'], # -1.0625
	['g', 4, 12345, 0, '1.234e+04'], # 12345
	['g', 4, 12355, 0, '1.236e+04'], # 12355
	['g', 4, -12345, 0, '-1.234e+04'], # -12345
	['g', 4, 12347, 1, '6174'], # 6173.5
	['g', 4, 199, 1, '99.5'], # 99.5
	['g', 4, 3, 3, '0.375'], # 0.375
	['g', 4, 1, 10, '0.0009766'], # 0.0009765625
	['g', 4, 2047, 1, '1024'], # 1023.5
	['g', 2, 199, 1, '1e+02'], # 99.5
	['g', 2, 3, 3, '0.38'], # 0.375
	['g', 2, 1, 3, '0.12'], # 0.125
	['g', 7, 6787108751669409, 39, '12345.68'], # 12345.678900000001
	['g', 5, 6787108751669409, 39, '12346'], # 12345.678900000001
	['g', 4, 6787108751669409, 39, '1.235e+04'], # 12345.678900000001
	['f', 1, 225, 2, '56.2'], # 56.25
	['f', 2, 225, 2, '56.25'], # 56.25
	['f', 3, 225, 2, '56.250'], # 56.25
	['f', 1, 175, 2, '43.8'], # 43.75
	['f', 2, 175, 2, '43.75'], # 43.75
	['f', 3, 175, 2, '43.750'], # 43.75
	['f', 1, 1, 3, '0.1'], # 0.125
	['f', 2, 1, 3, '0.12'], # 0.125
	['f', 3, 1, 3, '0.125'], # 0.125
	['f', 1, 19, 3, '2.4'], # 2.375
	['f', 2, 19, 3, '2.38'], # 2.375
	['f', 3, 19, 3, '2.375'], # 2.375
	['f', 1, 493827156049381, 2, '123456789012345.2'], # 123456789012345.25
	['f', 2, 493827156049381, 2, '123456789012345.25'], # 123456789012345.25
	['f', 3, 493827156049381, 2, '123456789012345.250'], # 123456789012345.25
	['f', 1, 3011782250804019, 50, '2.7'], # 2.6749999999999998
	['f', 2, 3011782250804019, 50, '2.67'], # 2.6749999999999998
	['f', 3, 3011782250804019, 50, '2.675'], # 2.6749999999999998
	['f', 1, 5404319552844595, 55, '0.1'], # 0.14999999999999999
	['f', 2, 5404319552844595, 55, '0.15'], # 0.14999999999999999
	['f', 3, 5404319552844595, 55, '0.150'], # 0.14999999999999999
	['g', 1, 3125, -5, '1e+05'], # 100000
	['g', 4, 3125, -5, '1e+05'], # 100000
	['g', 15, 3125, -5, '100000'], # 100000
	['g', 1, -3125, -5, '-1e+05'], # -100000
	['g', 4, -3125, -5, '-1e+05'], # -100000
	['g', 15, -3125, -5, '-100000'], # -100000
	['g', 1, 1, 30, '9e-10'], # 9.3132257461547852e-10
	['g', 4, 1, 30, '9.313e-10'], # 9.3132257461547852e-10
	['g', 15, 1, 30, '9.31322574615479e-10'], # 9.3132257461547852e-10
	['g', 1, 1, -400, '3e+120'], # 2.5822498780869086e+120
	['g', 4, 1, -400, '2.582e+120'], # 2.5822498780869086e+120
	['g', 15, 1, -400, '2.58224987808691e+120'], # 2.5822498780869086e+120
	['g', 1, -1, -400, '-3e+120'], # -2.5822498780869086e+120
	['g', 4, -1, -400, '-2.582e+120'], # -2.5822498780869086e+120
	['g', 15, -1, -400, '-2.58224987808691e+120'], # -2.5822498780869086e+120
	['g', 1, 1, 900, '1e-271'], # 1.1830521861667747e-271
	['g', 4, 1, 900, '1.183e-271'], # 1.1830521861667747e-271
	['g', 15, 1, 900, '1.18305218616677e-271'], # 1.1830521861667747e-271
);
for my $c (@R) {
	my ($style, $prec, $n, $s, $want) = @$c;
	my $x = $n / 2**$s;
	is(Stats::LikeR::_format_nv($style, $prec, $x), $want,
		sprintf('%%.%d%s of %s / 2**%s', $prec, $style, $n, $s));
}

# A precision is read as perl's sprintf reads it: a negative one is dropped
# (6 places), a fraction truncated, a string numified.  Non-finite values are
# printed as this perl prints them.  None is a tie, so sprintf is right even
# where its C library rounds ties the other way.  The expectations come from
# the running perl, since inf and nan are spelled differently before 5.22.
{
	my $inf = 9**9**9;
	my $nan = -sin($inf);
	for my $case ([-1, 2 / 3], [2.7, 2 / 3], ['3', 1 / 7], ['1e1', 0.5], [1, $inf], [1, -$inf], [1, $nan]) {
		my ($p, $x) = @$case;
		for my $style ('f', 'g') {
			is(Stats::LikeR::_format_nv($style, $p, $x), sprintf("%.*$style", $p, $x),
				"%.*$style with precision '$p' of $x reads like sprintf's");
		}
	}
	throws_ok { Stats::LikeR::_format_nv('e', 2, 1) } qr/style must be 'f' or 'g'/, 'an unknown style croaks';
	throws_ok { Stats::LikeR::_format_nv('ff', 2, 1) } qr/style must be 'f' or 'g'/, 'a style is one letter';
}

# table_one(): the report's tie, and a mean of 2.125 shown to 2 places.
# R: sprintf("%.1f", 100 * 18 / 32) is "56.2"; sprintf("%.2f", mean(c(2,
# 2.25))) is "2.12" and sprintf("%.2f", sd(c(2, 2.25))) "0.18".
{
	my $t1 = table_one({ g => [('a') x 18, ('b') x 14] }, vars => ['g']);
	my ($a) = grep { defined $_->{level} && $_->{level} eq 'a' } @$t1;
	is($a && $a->{Overall}, '18 (56.2%)', 'table_one: 18 of 32 is 56.2%');
	my ($c) = @{ table_one({ x => [2, 2.25] }, vars => ['x'], types => { x => 'continuous' }) };
	is($c->{Overall}, '2.12 (0.18)', 'table_one: a mean of 2.125 is 2.12');
}

# summary(): R's min, quartiles, median, mean and max of c(1.0625, 2, 12345)
# as %.4g are 1.062 1.531 2 4116 6174 1.234e+04.
{
	my $s = summary([1.0625, 2, 12345], return_only => 1, color => 0);
	my @cells = grep { /^[-0-9.e+]+$/ } split ' ', (grep { /\d/ && !/#/ } split /\n/, $s)[-1];
	is("@cells[1 .. 6]", '1.062 1.531 2 4116 6174 1.234e+04', 'summary: ties at 4 significant digits round to even')
		or diag($s);
}

# write_table(tex_format => 1) renders a numeric cell as %.4g.
{
	my $dir = File::Temp->newdir;
	my $tex = "$dir/ties.tex";
	write_table([[qw(a b)], [1.0625, 12345]], $tex, tex_format => 1, row_names => 0);
	open my $fh, '<', $tex or die "cannot read $tex: $!";
	my $t = do { local $/; <$fh> };
	close $fh;
	ok(index($t, '\textbf{1.062} & 1.234e+04') != -1, 'write_table tex_format: ties round to even') or diag($t);
}

no_leaks_ok {
	for my $style ('f', 'g') {
		Stats::LikeR::_format_nv($style, 2, 0.125);
		Stats::LikeR::_format_nv($style, 2, 9**9**9);
	}
	Stats::LikeR::_format_nv('g', 4, 12345);
} '_format_nv does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
