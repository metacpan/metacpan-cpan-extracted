#!/usr/bin/env perl
# min() and max() order -0 below +0, whatever the order of the arguments.
#
# Provenance: IEEE 754-2019, clause 9.6, maximum() and minimum(): maximum(-0,
# +0) is +0 and minimum(-0, +0) is -0, and a NaN operand gives NaN. There are
# no reference numbers to freeze -- every expected value is a signed zero, a
# NaN or a small integer -- and no reference implementation to take cases from:
# none of the suites CLAUDE.md names tests signed zeros in a max or min
# reduction. The references disagree with each other and with IEEE, and this
# file departs from all of them on purpose. What they return, checked on
# 2026-09-27:
#
#                          max(-0,+0)  max(+0,-0)  min(-0,+0)  min(+0,-0)
#     R 4.6.1 max()/min()     -0          +0          -0          +0     first seen
#     NumPy 2.4.6 np.max()    +0          -0          +0          -0     last seen
#     List::Util 1.70         +0          -0          -0          +0     last/first
#     Stats::LikeR, IEEE      +0          +0          -0          -0     by sign
#
# (R: max(-0, 0) with sign(1/x) to read the sign; NumPy: np.max(np.array(v))
# with math.copysign; List::Util: max(-0.0, 0.0) formatted with %g.) Before
# 0.3211 this module returned the first zero it saw, as R does; the four-lane
# scan 0.3211 introduced would have made the answer depend on which lane each
# zero fell in, which is what prompted choosing by sign instead.
#
# A zero's sign is read with sprintf "%g", which prints "-0" for negative zero
# on every perl and NV width here; 1/$x would croak "Illegal division by zero".
# Note that the perl literal -0 is the integer 0, which has no sign: only -0.0
# (or a computed negative zero) is one.
#
# Paths covered: plain scalar arguments; an array ref walked by the four-lane
# av_scan_min()/av_scan_max(), at every length from 1 to 11 and every position,
# so each lane, the lane combine and the one-at-a-time tail each see the +0/-0
# pair; an infinity beside the zeros at every placement, which sends the scan to
# its exact rescan because v * 0 is NaN for an infinite v; an array whose first
# element is a numeric string, which sends the whole walk to the av_fetch()
# fallback; a tied array, which skips the scan entirely; and zeros split across
# several arguments, where an earlier argument's value seeds the lanes.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(min max);

my ($nz, $pz) = (-0.0, 0.0);
sub sgn {
	my $x = shift;
	return 'NaN' if $x != $x;
	return "$x" if $x != 0;
	return sprintf('%g', $x) =~ /^-/ ? '-0' : '+0';
}
is(sgn($nz), '-0', 'the -0.0 literal is a negative zero on this perl');
is(sgn($pz), '+0', 'the 0.0 literal is a positive zero');
is(sgn(-0),  '+0', 'the -0 literal is the integer 0, which has no sign');

# plain scalar arguments
is(sgn(max($nz, $pz)), '+0', 'max(-0.0, 0.0) is +0');
is(sgn(max($pz, $nz)), '+0', 'max(0.0, -0.0) is +0');
is(sgn(min($nz, $pz)), '-0', 'min(-0.0, 0.0) is -0');
is(sgn(min($pz, $nz)), '-0', 'min(0.0, -0.0) is -0');
is(sgn(max($nz, $nz)), '-0', 'max(-0.0, -0.0) is -0');
is(sgn(min($pz, $pz)), '+0', 'min(0.0, 0.0) is +0');
is(sgn(max($nz)),      '-0', 'max(-0.0) alone is -0');
is(sgn(min($pz)),      '+0', 'min(0.0) alone is +0');
is(sgn(max($nz, 0)),   '+0', 'an integer 0 counts as +0 in max');
is(sgn(min(0, $nz)),   '-0', 'and -0.0 still wins min against an integer 0');
is(sgn(max(-0, 0)),    '+0', 'max(-0, 0) of integer literals is +0');

# the four-lane scan: every length and position
my @fail;
for my $len (1 .. 11) {
	for my $pos (0 .. $len - 1) {
		my @one_pos = ($nz) x $len; $one_pos[$pos] = $pz;	# a single +0 among -0s
		my @one_neg = ($pz) x $len; $one_neg[$pos] = $nz;	# a single -0 among +0s
		my %want = (
			max_pos => '+0',
			min_pos => $len == 1 ? '+0' : '-0',
			max_neg => $len == 1 ? '-0' : '+0',
			min_neg => '-0',
		);
		my %got = (
			max_pos => sgn(max(\@one_pos)), min_pos => sgn(min(\@one_pos)),
			max_neg => sgn(max(\@one_neg)), min_neg => sgn(min(\@one_neg)),
		);
		for my $k (sort keys %want) {
			push @fail, "len $len pos $pos $k: got $got{$k}, want $want{$k}"
				if $got{$k} ne $want{$k};
		}
	}
	my @all_neg = ($nz) x $len;
	my @all_pos = ($pz) x $len;
	push @fail, "len $len: max of all -0 is " . sgn(max(\@all_neg)) if sgn(max(\@all_neg)) ne '-0';
	push @fail, "len $len: min of all +0 is " . sgn(min(\@all_pos)) if sgn(min(\@all_pos)) ne '+0';
}
is_deeply(\@fail, [], 'array ref, lengths 1..11, the odd zero at every position')
	or diag join "\n", @fail;

# the av_fetch() fallback: a leading numeric string stops the scan at index 0
is(sgn(max(['-1', $nz, $nz, $pz, $nz])), '+0', 'max through the av_fetch() path');
is(sgn(min(['1',  $pz, $nz, $pz, $pz])), '-0', 'min through the av_fetch() path');
is(sgn(max([$nz, $nz, '-1', $pz])),      '+0', 'max with the +0 after the switch to av_fetch()');
is(sgn(min([$pz, $pz, '1', $nz])),       '-0', 'min with the -0 after the switch to av_fetch()');

{
	package TiedZeros;
	sub TIEARRAY  { my ($c, @v) = @_; bless [@v], $c }
	sub FETCH     { $_[0][$_[1]] }
	sub FETCHSIZE { scalar @{$_[0]} }
}
tie my @tied, 'TiedZeros', $nz, $nz, $pz, $nz, $nz;
is(sgn(max(\@tied)), '+0', 'max of a tied array, which skips the scan');
is(sgn(min(\@tied)), '-0', 'min of the same tied array');

# zeros split across arguments
is(sgn(max([$nz, $nz], $pz)),   '+0', 'max: +0 in a later scalar argument');
is(sgn(max([$nz], [$pz, $nz])), '+0', 'max: +0 in a later array ref');
is(sgn(min($pz, [$pz, $nz])),   '-0', 'min: -0 in a later array ref');
is(sgn(min([$pz, $pz], $nz)),   '-0', 'min: -0 in a later scalar argument');

# an infinity beside the zeros: v * 0 is NaN there, so the scan falls back to
# its exact one-at-a-time rescan (av_max_exact()/av_min_exact())
my $inf = 9**9**9;
my @inf_fail;
for my $len (2 .. 11) {
	for my $ipos (0 .. $len - 1) {
		for my $zpos (0 .. $len - 1) {
			next if $zpos == $ipos;
			my @mx = ($nz) x $len; $mx[$ipos] = -$inf; $mx[$zpos] = $pz;
			my @mn = ($pz) x $len; $mn[$ipos] =  $inf; $mn[$zpos] = $nz;
			push @inf_fail, "max len $len -Inf\@$ipos +0\@$zpos: " . sgn(max(\@mx)) if sgn(max(\@mx)) ne '+0';
			push @inf_fail, "min len $len +Inf\@$ipos -0\@$zpos: " . sgn(min(\@mn)) if sgn(min(\@mn)) ne '-0';
		}
		my @mx = ($nz) x $len; $mx[$ipos] = -$inf;
		my @mn = ($pz) x $len; $mn[$ipos] =  $inf;
		push @inf_fail, "max len $len -Inf\@$ipos, no +0: " . sgn(max(\@mx)) if sgn(max(\@mx)) ne '-0';
		push @inf_fail, "min len $len +Inf\@$ipos, no -0: " . sgn(min(\@mn)) if sgn(min(\@mn)) ne '+0';
	}
}
is_deeply(\@inf_fail, [], 'an infinity in the same array as the zeros, every placement')
	or diag join "\n", @inf_fail;
is(max([-$inf, -$inf, -$inf, -$inf, -$inf]), -$inf, 'max of all -Inf is -Inf');
is(min([ $inf,  $inf,  $inf,  $inf,  $inf]),  $inf, 'min of all +Inf is +Inf');
is(sgn(max([-$inf, 3, $nz, $pz, -1])), 3, 'max: a positive value still beats the zeros beside -Inf');

# the running value from an earlier argument seeds all four lanes
is(sgn(max($pz, [ ($nz) x 9 ])), '+0', 'max: a +0 argument before nine -0s');
is(sgn(max($nz, [ ($nz) x 9 ])), '-0', 'max: a -0 argument before nine -0s');
is(sgn(min($nz, [ ($pz) x 9 ])), '-0', 'min: a -0 argument before nine +0s');
is(sgn(min($pz, [ ($pz) x 9 ])), '+0', 'min: a +0 argument before nine +0s');

# nothing else moved: NaN still wins, nonzero ties and ordinary values are unchanged
my $nan = 9**9**9 / 9**9**9;
is(sgn(max($nz, $nan, $pz)),         'NaN', 'max: a NaN among zeros is still NaN');
is(sgn(min([$pz, $nz, $nan, $pz])),  'NaN', 'min: a NaN among zeros is still NaN');
is(max(3, 3, 3), 3,  'equal nonzero values: max is that value, not twice it');
is(min(-2, -2), -2,  'equal nonzero values: min is that value');
is(max([ (-5) x 9 ]), -5, 'equal negatives across every lane: not summed');
is(min([ (7) x 9 ]),   7, 'equal positives across every lane: not summed');
is(sgn(max(-1, $nz, -3)), '-0', 'max of negatives and -0 is -0');
is(sgn(min(1, $pz, 3)),   '+0', 'min of positives and +0 is +0');

done_testing();
