#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Stats::LikeR;
use Test::LeakTrace 'no_leaks_ok';

#--------
# AoA -- all columns (default), keep => first
#--------
{
	my $df = [ [1, 'a'], [1, 'a'], [2, 'b'], [1, 'a'] ];
	is_deeply(drop_duplicates($df),
		[ [1, 'a'], [2, 'b'] ], 'AoA all cols, keep first');
	is_deeply($df, [ [1, 'a'], [1, 'a'], [2, 'b'], [1, 'a'] ],
		'AoA original untouched');
}

#--------
# AoA -- keep => last and keep => 0 (drop all dups)
#--------
{
	my $df = [ [1, 'a'], [2, 'b'], [1, 'a'], [3, 'c'] ];
	is_deeply(drop_duplicates($df, keep => 'last'),
		[ [2, 'b'], [1, 'a'], [3, 'c'] ], 'AoA keep last');
	is_deeply(drop_duplicates($df, keep => 0),
		[ [2, 'b'], [3, 'c'] ], 'AoA keep 0 drops every duplicated row');
	is_deeply(drop_duplicates($df, keep => 'none'),
		[ [2, 'b'], [3, 'c'] ], "AoA keep 'none' same as 0");
}

#--------
# AoA -- subset of positions
#--------
{
	my $df = [ [1, 'x'], [1, 'y'], [2, 'z'] ];
	is_deeply(drop_duplicates($df, subset => 0),
		[ [1, 'x'], [2, 'z'] ], 'AoA subset on position 0 (scalar)');
	is_deeply(drop_duplicates($df, subset => [0, 1]),
		[ [1, 'x'], [1, 'y'], [2, 'z'] ], 'AoA subset [0,1] keeps distinct pairs');
}

#--------
# AoH -- default (union of keys), missing key == undef so rows collapse
#--------
{
	my $df = [ { A => 1, B => 2 }, { A => 1, B => 2 }, { A => 1 } ];
	is_deeply(drop_duplicates($df),
		[ { A => 1, B => 2 }, { A => 1 } ],
		'AoH default: exact dup dropped; {A=>1} differs (B missing != B=2)');
}

#--------
# AoH -- subset
#--------
{
	my $df = [ { id => 1, v => 'a' }, { id => 1, v => 'b' }, { id => 2, v => 'c' } ];
	is_deeply(drop_duplicates($df, subset => 'id'),
		[ { id => 1, v => 'a' }, { id => 2, v => 'c' } ],
		'AoH subset id, keep first');
	is_deeply(drop_duplicates($df, subset => 'id', keep => 'last'),
		[ { id => 1, v => 'b' }, { id => 2, v => 'c' } ],
		'AoH subset id, keep last');
}

#--------
# AoH -- surviving rows are the SAME refs (shared, not copied)
#--------
{
	my $r0 = { A => 1 };
	my $df = [ $r0, { A => 1 }, { A => 2 } ];
	my $out = drop_duplicates($df);
	is($out->[0], $r0, 'AoH survivor reuses the original row ref');
}

#--------
# HoA -- default (all cols), unchecked-vs-checked realignment
#--------
{
	my $df = { A => [1, 1, 2, 1], B => ['a', 'a', 'b', 'a'] };
	is_deeply(drop_duplicates($df),
		{ A => [1, 2], B => ['a', 'b'] }, 'HoA all cols, keep first');
	is_deeply($df, { A => [1, 1, 2, 1], B => ['a', 'a', 'b', 'a'] },
		'HoA original untouched');
}

#--------
# HoA -- subset keeps every column aligned to the survivors
#--------
{
	my $df = { id => [1, 1, 2], v => [10, 20, 30] };
	is_deeply(drop_duplicates($df, subset => 'id'),
		{ id => [1, 2], v => [10, 30] },
		'HoA subset id: v realigned to surviving rows');
	is_deeply(drop_duplicates($df, subset => 'id', keep => 'last'),
		{ id => [1, 2], v => [20, 30] }, 'HoA subset id, keep last');
}

#--------
# undef (NA) is a comparable value: two all-undef rows are duplicates
#--------
{
	my $df = [ [undef, 1], [undef, 1], [1, undef] ];
	is_deeply(drop_duplicates($df),
		[ [undef, 1], [1, undef] ], 'AoA: undef cells compare equal to each other');
}

#--------
# numeric vs string: stringified comparison (like merge); values survive intact
#--------
{
	my $df = { x => [1, 1.0, 22.8], 'y' => [9, 8, 7] };
	my $out = drop_duplicates($df, subset => 'x');
	is_deeply($out, { x => [1, 22.8], 'y' => [9, 7] },
		'HoA: 1 and 1.0 stringify equal, so second dropped');
	ok(looks_like_number($out->{x}[1]), 'surviving cell still numeric');
}

#--------
# empty / edge
#--------
is_deeply(drop_duplicates([]), [], 'empty AoA/AoH -> empty');
is_deeply(drop_duplicates({}), {}, 'empty HoA -> empty');
is_deeply(drop_duplicates([ [1], [1] ]), [ [1] ], 'AoA collapses to one');

#--------
# errors
#--------
dies_ok { drop_duplicates(undef) } 'undefined data dies';
throws_ok { drop_duplicates('scalar') } qr/data frame/,
	'scalar data frame dies';
throws_ok { drop_duplicates({ r => { A => 1 }, s => { A => 2 } }) } qr/HoH .* not supported/,
	'HoH dies';
throws_ok { drop_duplicates([ [1] ], keep => 'maybe') } qr/'keep' must be/,
	'invalid keep dies';
throws_ok { drop_duplicates([ [1] ], foo => 1) } qr/unknown argument/,
	'unknown argument dies';
throws_ok { drop_duplicates([ [1] ], subset => []) } qr/'subset' is empty/,
	'empty subset dies';
throws_ok { drop_duplicates([ [1, 2] ], subset => [0, 0]) } qr/duplicate column '0'/,
	'duplicate subset column dies';
throws_ok { drop_duplicates([ [1, 2] ], subset => 5) } qr/out of range/,
	'AoA out-of-range position dies';
throws_ok { drop_duplicates([ [1, 2] ], subset => 'A') } qr/not a non-negative integer/,
	'AoA non-integer position dies';
throws_ok { drop_duplicates([ { A => 1 } ], subset => 'Z') } qr/column 'Z' not found/,
	'AoH missing column dies';
throws_ok { drop_duplicates({ A => [1] }, subset => 'Z') } qr/column 'Z' not found/,
	'HoA missing column dies';
lives_ok { drop_duplicates([ [1], [1] ]) } 'a well-formed call lives';

#--------
# memory
#--------
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok {
	my $x = drop_duplicates([ [1, 'a'], [1, 'a'], [2, 'b'] ]);
} 'drop_duplicates: no memory leaks (AoA)';

no_leaks_ok {
	my $x = drop_duplicates([ { A => 1 }, { A => 1 } ], subset => 'A');
} 'drop_duplicates: no memory leaks (AoH)';

no_leaks_ok {
	my $x = drop_duplicates({ A => [1, 1, 2], B => [3, 3, 4] });
} 'drop_duplicates: no memory leaks (HoA)';

no_leaks_ok {
	eval { drop_duplicates([ { A => 1 } ], subset => 'Z') };
} 'drop_duplicates: no memory leaks (die path)';

done_testing();
