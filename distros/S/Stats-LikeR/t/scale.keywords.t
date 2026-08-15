#!/usr/bin/env perl
#
# scale()'s option parsing: the string spellings of {center} and {scale}.
#
# t/01.t covers scale() with numeric options only ({center => 0},
# {center => 1, scale => 0}), so every string keyword the XS accepts --
# "mean", "sd", "none", "true", "false", "" -- and the case-insensitive
# matching behind them were entirely untested.  This file covers them.
#
# Provenance of the expected values: R 4.6.1 base::scale(), at
# options(digits=17).  R accepts only logical or numeric for center/scale, so
# the string keywords are a Stats::LikeR extension with no R equivalent to
# quote; they are pinned instead by requiring each keyword to produce exactly
# the numeric/logical form's result, and that form is what carries the frozen
# R values.  The commands were:
#
#   scale(1:5)                        # -> @R_DEFAULT
#   scale(1:5, center=FALSE)          # -> @R_NO_CENTER   (divisor is
#                                     #    sqrt(sum(x^2)/(n-1)), not the sd)
#   scale(1:5, scale=FALSE)           # -> @R_NO_SCALE
#   scale(1:5, center=FALSE, scale=FALSE)
#   scale(1:5, center=2)              # -> @R_CENTER_2
#   scale(1:5, center=2, scale=4)     # -> @R_CENTER_2_SCALE_4
#   scale(1:5, center=FALSE, scale=4)
#   scale(matrix(c(1,3,5,2,4,6), nrow=3))            # -> @R_MATRIX
#   scale(matrix(c(1,3,5,2,4,6), nrow=3), center=FALSE)
#
# No R is needed to run this file: the values above are frozen below.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'scale';

# Every value here is exact in binary except where noted, so the tolerance
# only has to absorb one divide's worth of rounding at any NV width.
my $TOL = 1e-15;

my @R_DEFAULT = (-1.26491106406735176, -0.63245553203367588, 0,
                  0.63245553203367588,  1.26491106406735176);
my @R_NO_CENTER = (0.26967994498529685, 0.53935988997059370,
                   0.80903983495589049, 1.07871977994118740,
                   1.34839972492648408);
my @R_NO_SCALE  = (-2, -1, 0, 1, 2);
my @R_NEITHER   = (1, 2, 3, 4, 5);
my @R_CENTER_2  = (-0.5163977794943222, 0, 0.5163977794943222,
                    1.0327955589886444, 1.5491933384829668);
my @R_CENTER_2_SCALE_4 = (-0.25, 0, 0.25, 0.5, 0.75);
my @R_NO_CENTER_SCALE_4 = (0.25, 0.5, 0.75, 1, 1.25);
# scale(matrix(c(1,3,5,2,4,6), nrow=3)) -- both columns become (-1, 0, 1)
my @R_MATRIX      = ([-1, -1], [0, 0], [1, 1]);
my @R_MATRIX_NO_C = ([0.23904572186687872, 0.37796447300922720],
                     [0.71713716560063612, 0.75592894601845440],
                     [1.19522860933439357, 1.13389341902768170]);

sub list_is {
	my ($got, $want, $name) = @_;
	is(scalar @$got, scalar @$want, "$name: element count") or return;
	for my $i (0 .. $#$want) {
		my $delta = abs($got->[$i] - $want->[$i]);
		ok($delta <= $TOL, "$name: [$i] = $want->[$i]")
			or diag("got $got->[$i], want $want->[$i], delta $delta");
	}
}

# ---------------------------------------------------------------------------
# 1. The numeric/logical forms, against R.  These are what the keyword forms
#    are then required to match.
# ---------------------------------------------------------------------------
list_is([scale(1..5)],                                \@R_DEFAULT,   'scale(1..5) vs R scale(1:5)');
list_is([scale(1..5, {center => 1, scale => 1})],      \@R_DEFAULT,   'center => 1, scale => 1');
list_is([scale(1..5, {center => 0})],                  \@R_NO_CENTER, 'center => 0 vs R center=FALSE');
list_is([scale(1..5, {scale  => 0})],                  \@R_NO_SCALE,  'scale => 0 vs R scale=FALSE');
list_is([scale(1..5, {center => 0, scale => 0})],       \@R_NEITHER,   'center => 0, scale => 0');
list_is([scale(1..5, {center => 2})],                  \@R_CENTER_2,  'center => 2 (numeric centre)');
list_is([scale(1..5, {center => 2, scale => 4})],       \@R_CENTER_2_SCALE_4, 'center => 2, scale => 4');
list_is([scale(1..5, {center => 0, scale => 4})],       \@R_NO_CENTER_SCALE_4, 'center => 0, scale => 4');

# ---------------------------------------------------------------------------
# 2. Keyword spellings.  "mean"/"sd"/"true"/"1" mean "compute it",
#    "none"/"false"/"0"/"" mean "do not".
# ---------------------------------------------------------------------------
for my $on ('mean', 'true', '1') {
	list_is([scale(1..5, {center => $on, scale => 'sd'})], \@R_DEFAULT,
	        "center => '$on', scale => 'sd'");
}
for my $off ('none', 'false', '0', '') {
	list_is([scale(1..5, {center => $off})], \@R_NO_CENTER, "center => '$off'");
	list_is([scale(1..5, {scale  => $off})], \@R_NO_SCALE,  "scale => '$off'");
	list_is([scale(1..5, {center => $off, scale => $off})], \@R_NEITHER,
	        "center => '$off', scale => '$off'");
}
list_is([scale(1..5, {scale => 'true'})], \@R_DEFAULT, "scale => 'true'");
list_is([scale(1..5, {scale => 'sd'})],   \@R_DEFAULT, "scale => 'sd'");

# ---------------------------------------------------------------------------
# 3. The keywords are ASCII case-insensitive, and the folding is exact rather
#    than approximate: each spelling must land on the identical NV, not merely
#    a close one.  This is the behaviour str_ieq_ascii() in LikeR.xs provides
#    (it replaced strcasecmp(), which is not available on every platform).
#
#    Only the "off" spellings below can actually detect a broken fold, and
#    that is worth knowing before trusting this section: an unmatched string
#    falls through to SvTRUE, which means "yes, compute it", so if folding
#    stopped working "MEAN" and "SD" and "TRUE" would take the fallback and
#    still produce the centred, scaled answer.  "NONE" and "FALSE" would flip
#    from off to on and fail loudly.  Verified by deleting the fold from
#    str_ieq_ascii(): 11 assertions here fail, all of them "off" cases.  The
#    "on" spellings are kept as documentation of the accepted vocabulary.
# ---------------------------------------------------------------------------
my @baseline = scale(1..5);
for my $spelling (qw(mean MEAN Mean mEaN meaN)) {
	my @got = scale(1..5, {center => $spelling, scale => 'sd'});
	is_deeply(\@got, \@baseline, "center => '$spelling' folds to 'mean'");
}
for my $spelling (qw(sd SD Sd sD)) {
	my @got = scale(1..5, {center => 'mean', scale => $spelling});
	is_deeply(\@got, \@baseline, "scale => '$spelling' folds to 'sd'");
}
for my $spelling (qw(true TRUE True tRuE)) {
	my @got = scale(1..5, {center => $spelling, scale => $spelling});
	is_deeply(\@got, \@baseline, "center/scale => '$spelling' folds to 'true'");
}
my @no_center = scale(1..5, {center => 'none'});
for my $spelling (qw(none NONE None nOnE false FALSE False fAlSe)) {
	my @got = scale(1..5, {center => $spelling});
	is_deeply(\@got, \@no_center, "center => '$spelling' folds to off");
}
my @neither = scale(1..5, {center => 'none', scale => 'none'});
for my $spelling (qw(NONE False FALSE nOnE)) {
	my @got = scale(1..5, {center => $spelling, scale => $spelling});
	is_deeply(\@got, \@neither, "center/scale => '$spelling' both off");
}

# ---------------------------------------------------------------------------
# 4. Edge cases in the same parser.
# ---------------------------------------------------------------------------
list_is([scale(1..5, {center => undef})], \@R_NO_CENTER, 'center => undef is off');
list_is([scale(1..5, {scale  => undef})], \@R_NO_SCALE,  'scale => undef is off');
list_is([scale(1..5, {})],                \@R_DEFAULT,   'empty options hash is the default');

# A truthy string that is neither a keyword nor a number falls through to
# SvTRUE, i.e. it means "yes, compute it".  Pinning current behaviour.
list_is([scale(1..5, {center => 'yes', scale => 'yes'})], \@R_DEFAULT,
        'unrecognised truthy string means "compute it"');
# Near-misses must not be truncated into a keyword match: "means" and "sdd"
# are not keywords, so they take the same SvTRUE path.
list_is([scale(1..5, {center => 'means', scale => 'sdd'})], \@R_DEFAULT,
        'near-miss keywords ("means", "sdd") are not keyword matches');

# scale => 0 as a *divisor* cannot divide by zero: the XS substitutes 1.0.
# (This is reached through the numeric branch, not the "0" keyword branch,
# by passing a numeric zero that is not the string "0".)
{
	my @got = scale(1..5, {center => 'none', scale => 0.0});
	list_is(\@got, \@R_NEITHER, 'scale => 0.0 divides by 1, not by 0');
	ok(!grep({ $_ != $_ || abs($_) == 9**9**9 } @got), 'scale => 0.0 yields no NaN/Inf');
}

# ---------------------------------------------------------------------------
# 5. Matrix mode reads the same options, per column.
# ---------------------------------------------------------------------------
my $mat = [[1, 2], [3, 4], [5, 6]];
for my $opts ({}, {center => 'mean', scale => 'sd'}, {center => 'MEAN', scale => 'SD'},
              {center => 'true', scale => 'TRUE'}) {
	my $got = scale($mat, $opts);
	is(ref $got, 'ARRAY', 'matrix mode returns an array ref');
	list_is($got->[$_], $R_MATRIX[$_], "matrix row $_ with " . join(',', %$opts))
		for 0 .. $#R_MATRIX;
}
{
	my $got = scale($mat, {center => 'none'});
	list_is($got->[$_], $R_MATRIX_NO_C[$_], "matrix row $_, center => 'none'")
		for 0 .. $#R_MATRIX_NO_C;
}
{
	my $got = scale($mat, {center => 'None', scale => 'False'});
	is_deeply($got, [[1, 2], [3, 4], [5, 6]], 'matrix with both off is unchanged');
}

done_testing();
