#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Regressions from the 2026-11-26 review: frame-shape detection in nrow() and
# ncol(), AoA column positions in drop_cols()/select_cols(), HoH row names in
# concat(), probabilities and interval labels in qcut(), and seq()'s IV path.

my $inf = 9**9**9;
my $nan = $inf - $inf;

#--------
# nrow
#--------
# A hash with both HASH and ARRAY values is neither a HoH nor a HoA. The form
# was chosen from the first defined value in hash order, so it was counted or
# refused depending on PERL_HASH_SEED. Key names change the order within one
# process, so 50 differently named pairs cover both orders.
{
	my $counted = 0;
	for my $i (1 .. 50) {
		my $r = eval { nrow({ "k$i" => { x => 1 }, "m$i" => [1, 2, 3] }) };
		$counted++ if defined $r;
	}
	is($counted, 0, 'nrow: a mixed HASH/ARRAY hash is refused whatever the hash order');
}
throws_ok { nrow({ a => { x => 1 }, b => [1, 2, 3] }) }
	qr/\Anrow: hash mixes HASH values \(key 'a'\) and ARRAY values \(key 'b'\), so it is neither a HoH nor a HoA\n\z/,
	'nrow: the mixed-hash message names the lowest-sorting key of each kind';
throws_ok { nrow({ r1 => { a => 1 }, r2 => undef }) }
	qr/\Anrow: HoH row 'r2' is not a hash ref\n\z/,
	'nrow: a HoH with a non-hash row dies, as ncol does';
is(nrow({ r1 => { a => 1 }, r2 => { a => 2 }, r3 => {} }), 3, 'nrow: a HoH still counts one row per key');
is(nrow({ a => [1, 2], b => [3, 4] }), 2, 'nrow: a HoA still counts its column length');
# the messages end in a newline, so perl appends no " at .../LikeR.pm line N"
throws_ok { nrow({ a => [1, 2, 3], b => [1, 2] }) }
	qr/\Anrow: ragged HoA — column 'b' has 2 rows, but 'a' has 3\n\z/,
	'nrow: a ragged HoA names the sorted-first column as the reference, no line number';
throws_ok { nrow({ a => 1, b => 2 }) }
	qr/neither ARRAY refs \(HoA\) nor HASH refs \(HoH\)\n\z/,
	'nrow: the neither-form message ends in a newline';
no_leaks_ok {
	nrow({ r1 => { a => 1 }, r2 => { a => 2 } });
	nrow({ a => [1, 2], b => [3, 4] });
} 'nrow(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# ncol
#--------
# An AoH or HoH has the union of its rows' keys as columns, the set colnames()
# lists. ncol() counted row 0's keys and required every row to have as many,
# so rows with equal counts but different keys came out too few, and a sparse
# frame died.
{
	my @frames = (
		[ 'AoH, different keys',  [ { a => 1, b => 2 }, { c => 3, d => 4 } ],             4 ],
		[ 'AoH, sparse',          [ { a => 1 }, { a => 2, b => 3 } ],                     2 ],
		[ 'AoH, one row differs', [ { a => 1, b => 2 }, { a => 3, b => 4 }, { a => 5, z => 6 } ], 3 ],
		[ 'AoH, an empty row',    [ { a => 1, b => 2 }, {} ],                             2 ],
		[ 'HoH, different keys',  { r1 => { a => 1, b => 2 }, r2 => { c => 3, d => 4 } }, 4 ],
		[ 'HoH, sparse',          { r1 => { a => 1, b => 2 }, r2 => { a => 1 } },         2 ],
	);
	for my $f (@frames) {
		my ($name, $df, $want) = @$f;
		# lives_and: up to 0.3430 the sparse frames died, which would end the file
		lives_and { is(ncol($df), $want) } "ncol: $name counts the union of the row keys";
		lives_and { is(ncol($df), scalar colnames($df)) } "ncol: $name agrees with colnames()";
	}
}
# A blessed row is counted too: ncol() goes by reftype, and colnames()'s
# _aoh_key_union() would skip it.
lives_and { is(ncol([ { a => 1 }, bless({ b => 2 }, 'My::Row') ]), 2) } 'ncol: a blessed AoH row adds its keys';
throws_ok { ncol([ { a => 1 }, undef ]) }
	qr/\Ancol: AoH row 1 is not a hash ref\n\z/,
	'ncol: an AoH row that is not a hash still dies';
throws_ok { ncol({ a => { x => 1 }, b => [1, 2] }) }
	qr/\Ancol: hash mixes HASH values \(key 'a'\) and ARRAY values \(key 'b'\)/,
	'ncol: a mixed HASH/ARRAY hash gets one message whatever the hash order';
is(ncol([ { a => 1, b => 2 }, { b => 3, a => 4 } ]), 2, 'ncol: AoH rows with the same keys in any order');
is(ncol({ r1 => { a => 1, b => 2 }, r2 => { b => 3, a => 4 } }), 2, 'ncol: HoH rows with the same keys');
is(ncol([ {}, {} ]), 0, 'ncol: empty AoH rows are still zero columns');
# eval: up to 0.3430 these sparse frames died, which would end the file
no_leaks_ok {
	eval {
		ncol([ { a => 1, b => 2 }, { c => 3 } ]);
		ncol({ r1 => { a => 1 }, r2 => { b => 2 } });
	};
} 'ncol(): no memory leaks on the key union' unless $INC{'Devel/Cover.pm'};

#--------
# drop_cols / select_cols on an AoA
#--------
# /^\d+$/ took "1\n" and a non-ASCII digit, which then matched no position, so
# drop_cols() validated the call and dropped nothing.
{
	my $aoa = [ [1, 2, 3], [4, 5, 6] ];
	throws_ok { drop_cols($aoa, "1\n") }
		qr/is not a non-negative integer/,
		'drop_cols: an AoA position with a trailing newline is refused';
	throws_ok { drop_cols($aoa, "\x{661}") }
		qr/is not a non-negative integer/,
		'drop_cols: a non-ASCII digit is not an AoA position';
	throws_ok { select_cols($aoa, "0\n") }
		qr/is not a non-negative integer/,
		'select_cols: an AoA position with a trailing newline is refused';
	is_deeply(drop_cols($aoa, 1), [ [1, 3], [4, 6] ], 'drop_cols: a plain AoA position still drops');
	is_deeply(select_cols($aoa, [2, 0]), [ [3, 1], [6, 4] ], 'select_cols: plain AoA positions still select');
	no_leaks_ok {
		my $d = drop_cols($aoa, 1);
	} 'drop_cols(): AoA, no memory leaks' unless $INC{'Devel/Cover.pm'};
}

#--------
# concat (HoH)
#--------
# A suffixed name took a later frame's real row name: { a } + { a, 'a.1' }
# renamed the second frame's real 'a.1' to 'a.1.1'.
{
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	my $h = concat({ a => { v => 1 } }, { a => { v => 2 }, 'a.1' => { v => 3 } });
	is_deeply([ sort keys %$h ], [ 'a', 'a.1', 'a.2' ], 'concat: HoH suffixes skip every real row name');
	is($h->{'a.1'}{v}, 3, "concat: the real 'a.1' row keeps its name");
	is($h->{'a.2'}{v}, 2, "concat: the second 'a' takes the first free suffix");
	is($h->{a}{v}, 1, "concat: the first 'a' keeps its name");
	is(scalar @warn, 1, 'concat: one collision warning');
	@warn = ();
	my $same = concat({ 'a.1' => { v => 1 } }, { 'a.1' => { v => 2 } });
	is_deeply([ sort keys %$same ], [ 'a.1', 'a.1.1' ], 'concat: a real name repeated across frames is still suffixed');
	@warn = ();
	my $none = concat({ a => { v => 1 } }, { b => { v => 2 } });
	is_deeply([ sort keys %$none ], [ 'a', 'b' ], 'concat: distinct HoH names are untouched');
	is(scalar @warn, 0, 'concat: no warning without a collision');
}
{
	# the collision warning is discarded, not collected: a push onto an outer
	# array from inside the block would itself count as a leak
	local $SIG{__WARN__} = sub { };
	no_leaks_ok {
		my $c = concat({ a => { v => 1 } }, { a => { v => 2 }, 'a.1' => { v => 3 } });
	} 'concat(): HoH collision, no memory leaks' unless $INC{'Devel/Cover.pm'};
}

#--------
# qcut
#--------
# A word was read as 0, and a NaN reached an (IV) cast of NaN in the XS.
throws_ok { qcut([1 .. 10], [0, 'abc', 1]) }
	qr/probability at index 1 is not a number/,
	'qcut: a word in the probability vector dies naming its index';
throws_ok { qcut([1 .. 10], [0, undef, 1]) }
	qr/probability at index 1 is not a number/,
	'qcut: an undef probability dies';
throws_ok { qcut([1 .. 10], [0, 0.5, [1]]) }
	qr/probability at index 2 is not a number/,
	'qcut: a reference is not a probability';
throws_ok { qcut([1 .. 10], [0, $nan, 1]) }
	qr/probability at index 1 is NaN/,
	'qcut: a NaN probability dies naming its index';
throws_ok { Stats::LikeR::_qcut_core([1 .. 10], [0, $nan, 1], 0, 0) }
	qr/_qcut_core: probability at index 1 is NaN/,
	'_qcut_core: a NaN probability croaks rather than reaching the cast';
is_deeply([ qcut([1 .. 10], [0, 0.5, 2]) ], [ 1, 5.5, 10 ], 'qcut: out-of-range probabilities are still clamped');
# A vector without 0 or 1 stretches the end bins, so their labels are open.
is_deeply(qcut([1 .. 10], [0.25, 0.75], labels => 'interval'),
	[ ('(-Inf, Inf)') x 10 ],
	'qcut: one bin stretched both ways is (-Inf, Inf)');
is_deeply(qcut([1 .. 10], [0, 0.5, 0.9], labels => 'interval'),
	[ ('[1, 5.5]') x 5, ('(5.5, Inf)') x 5 ],
	'qcut: a missing 1 opens the last bin to Inf');
is_deeply(qcut([1 .. 10], [0.1, 0.5, 1], labels => 'interval'),
	[ ('(-Inf, 5.5]') x 5, ('(5.5, 10]') x 5 ],
	'qcut: a missing 0 opens the first bin to -Inf');
{
	my $iv = qcut([1 .. 10], 4, labels => 'interval');
	is($iv->[0],  '[1, 3.25]',  'qcut: integer q still closes the first bin on the minimum');
	is($iv->[-1], '(7.75, 10]', 'qcut: integer q still closes the last bin on the maximum');
}
no_leaks_ok {
	my $l = qcut([1 .. 10], [0.1, 0.5, 0.9], labels => 'interval');
} 'qcut(): interval labels, no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# seq
#--------
# The IV path cast 'by' to an IV without bounding it. A one-element sequence
# never uses its step; a two-element one whose step is past IV_MAX (on a
# 32-bit-IV perl, 4e9) now takes the NV path. In a normal build the old cast
# was undefined but harmless, so these pin the values rather than the fault.
is_deeply([ seq(0, 10, 1e20) ], [ 0 ], 'seq: a huge by with one element is just from');
{
	my @s = seq(-2e9, 2e9, 4e9);
	is(scalar @s, 2, 'seq: a step past a 32-bit IV_MAX gives two elements');
	ok($s[0] == -2e9 && $s[1] == 2e9, 'seq: and they are from and to');
}
{
	my @s = seq(-2**53, 2**53, 2**54);
	ok(@s == 2 && $s[0] == -2**53 && $s[1] == 2**53, 'seq: a sequence straddling zero with a step of 2**54');
}
no_leaks_ok {
	my @s = seq(0, 10, 1e20);
	my @t = seq(-2e9, 2e9, 4e9);
} 'seq(): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# value_counts: a column no row has
#--------
# Up to 0.3430 a key or index no row has returned {} without a word, where
# dropna() and drop_duplicates() die on an absent column; a typo in the name
# looked like a column of nothing but missing values.
for my $c (
	[ 'AoH',            [ { a => 1 }, { a => 2 } ],     'b'  ],
	[ 'AoA',            [ [1, 2], [3, 4] ],             5    ],
	[ 'HoA',            { a => [1, 2] },                'zz' ],
	[ 'HoH',            { r1 => { a => 1 } },           'b'  ],
	[ 'hash of scalars', { a => 1, b => 2 },            'zz' ],
) {
	my ($shape, $df, $key) = @$c;
	throws_ok { value_counts($df, $key) } qr/\Avalue_counts: column '\Q$key\E' not found/,
		"value_counts: $shape, a column no row has dies naming it";
}
is_deeply(value_counts([ { a => 1 }, { b => 2 } ], 'b'), { 2 => 1 }, 'value_counts: a key some rows have still skips the rest');
is_deeply(value_counts([ { a => undef } ], 'a'), {}, 'value_counts: a key present only as undef is a column of missing values');
is_deeply(value_counts([ [1, 2] ], -2), { 1 => 1 }, 'value_counts: a negative AoA index inside the row');
is_deeply(value_counts([], 'a'), {}, 'value_counts: an empty AoH is still {}');
is_deeply(value_counts({}, 'a'), {}, 'value_counts: an empty hash is still {}');
no_leaks_ok {
	eval { value_counts([ { a => 1 } ], 'b') };
} 'value_counts: the absent-column croak, no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
