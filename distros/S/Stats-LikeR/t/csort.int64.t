# csort() on integers above 2**53, and min()/max() returning them exactly.
# Provenance: expected orders are perl 5.44's own `sort { $a <=> $b }` on the
# same data (exact IV/UV comparison), frozen as literals; min/max expectations
# are the exact integer extremes (List::Util::min/max are NOT used: they are
# inexact for IVs that differ only below 2**53 -- max(2**63-1, 2**63) gives
# 9223372036854775807 there).  Regenerate by sorting the inputs with perl.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More; use Config; use Stats::LikeR;
SKIP: {
	skip 'needs 64-bit IVs', 11 if $Config{ivsize} < 8;
	my @ids = (1800000000000000003, 1800000000000000001, 1800000000000000002);
	my $want = '1800000000000000001,1800000000000000002,1800000000000000003';
	is join(',', map {$_->{id}} @{csort([map {{id=>$_}} @ids], 'id')}), $want, 'AoH';
	is join(',', map {$_->[0]} @{csort([map {[$_]} @ids], 0)}), $want, 'AoA';
	is join(',', @{csort({id=>[@ids]}, 'id')->{id}}), $want, 'HoA';
	my @s = ('9223372036854775807', '9223372036854775806', '-9223372036854775807', '18446744073709551615', '18446744073709551614', '9223372036854775808');
	is join(',', @{csort({x=>[@s]}, 'x')->{x}}),
	  '-9223372036854775807,9223372036854775806,9223372036854775807,9223372036854775808,18446744073709551614,18446744073709551615', 'numeric strings, UVs, negatives';
	my @t = (9007199254740993, 9007199254740992, 9007199254740993, -9007199254740993, -9007199254740992);
	is join(',', @{csort({x=>[@t]}, 'x')->{x}}),
	  '-9007199254740993,-9007199254740992,9007199254740992,9007199254740993,9007199254740993', 'around 2**53';
	my @a = (9007199254740993, 9007199254740992, 12345678901234567);
	is Stats::LikeR::max(\@a), '12345678901234567', 'max array ref';
	is Stats::LikeR::max(@a), '12345678901234567', 'max list';
	is Stats::LikeR::min(\@a), '9007199254740992', 'min';
	is Stats::LikeR::min(9007199254740993, 9007199254740994), '9007199254740993', 'min tie of NVs';
	is Stats::LikeR::max(9223372036854775807, 9223372036854775808), '9223372036854775808', 'max IV vs UV';
	is Stats::LikeR::min(-9223372036854775807, -9223372036854775806), '-9223372036854775807', 'min negative';
	is Stats::LikeR::max(18446744073709551614, 18446744073709551615), '18446744073709551615', 'max UV';
}
is Stats::LikeR::max(1.5, 2.5, -1), 2.5, 'ordinary doubles';
is join(',', @{csort({x=>[3, 1, 2]}, 'x')->{x}}), '1,2,3', 'ordinary column';
done_testing;
