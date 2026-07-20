#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# interpolate: linear NA (undef) imputation along the row axis, like pandas
# DataFrame.interpolate(method='linear').  The numeric sibling of ffill/bfill:
#   * interior gaps (numeric anchor on both sides) are linearly interpolated
#   * with the default limit_direction='forward', trailing gaps are held
#     constant (last value) and leading gaps are left NA
#   * limit_direction 'backward' / 'both' flips / enables the edge fills
#   * limit_area 'inside' | 'outside' restricts to interior / edge gaps
#   * limit caps cells filled per run; cols restricts the columns
#   * only numeric neighbours anchor; a defined non-numeric cell blocks a fill
#   * all shapes: positional AoA/AoH/HoA, sorted-key HoH
#   * returns a NEW frame; the original is never modified

#========
# core linear interpolation, all four shapes
#========

is_deeply(
	interpolate({ v => [ undef, 1, undef, undef, 4, undef ] }),
	{ v => [ undef, 1, 2, 3, 4, 4 ] },
	'HoA: interior interpolated, trailing held, leading NA (default forward)');

is_deeply(
	interpolate([ { v => 1 }, { v => undef }, { v => 3 } ]),
	[ { v => 1 }, { v => 2 }, { v => 3 } ],
	'AoH: single interior gap');

is_deeply(
	interpolate([ [ 1 ], [ undef ], [ 5 ] ], cols => [ 0 ]),
	[ [ 1 ], [ 3 ], [ 5 ] ],
	'AoA: positional col 0');

is_deeply(
	interpolate({ r1 => { x => 0 }, r2 => { x => undef }, r3 => { x => 10 } }),
	{ r1 => { x => 0 }, r2 => { x => 5 }, r3 => { x => 10 } },
	'HoH: sorted-key order r1,r2,r3');

#--------
# non-integer / fractional result
#--------
is_deeply(
	interpolate({ v => [ 1, undef, 2 ] }),
	{ v => [ 1, 1.5, 2 ] },
	'HoA: fractional interpolated value');

#--------
# original not mutated
#--------
{
	my $df = { v => [ 1, undef, 3 ] };
	interpolate($df);
	is_deeply($df, { v => [ 1, undef, 3 ] }, 'input frame not mutated');
}

#========
# limit_direction
#========

is_deeply(
	interpolate({ v => [ undef, 1, undef, 3, undef ] }, limit_direction => 'backward'),
	{ v => [ 1, 1, 2, 3, undef ] },
	'backward: leading held, trailing NA, interior still linear');

is_deeply(
	interpolate({ v => [ undef, 1, undef, 3, undef ] }, limit_direction => 'both'),
	{ v => [ 1, 1, 2, 3, 3 ] },
	'both: leading and trailing held constant');

#========
# limit_area
#========

is_deeply(
	interpolate({ v => [ undef, 1, undef, 4, undef ] },
		limit_direction => 'both', limit_area => 'inside'),
	{ v => [ undef, 1, 2.5, 4, undef ] },
	'limit_area inside: only the interior gap filled');

is_deeply(
	interpolate({ v => [ undef, 1, undef, 4, undef ] },
		limit_direction => 'both', limit_area => 'outside'),
	{ v => [ 1, 1, undef, 4, 4 ] },
	'limit_area outside: only leading/trailing filled');

#========
# limit
#========

is_deeply(
	interpolate({ v => [ 1, undef, undef, undef, 5 ] }, limit => 1),
	{ v => [ 1, 2, undef, undef, 5 ] },
	'limit=1 forward: only first cell of the interior run filled');

is_deeply(
	interpolate({ v => [ 1, undef, undef, undef, 5 ] },
		limit => 1, limit_direction => 'backward'),
	{ v => [ 1, undef, undef, 4, 5 ] },
	'limit=1 backward: only last cell of the interior run filled');

#========
# anchoring / barriers
#========

#--------
# a defined non-numeric cell blocks interpolation across it and is preserved
#--------
is_deeply(
	interpolate({ v => [ 1, 'x', undef, 4 ] }, limit_direction => 'both'),
	{ v => [ 1, 'x', 4, 4 ] },
	'non-numeric barrier: no interior fit across it; right anchor holds constant');

#--------
# no numeric anchor at all -> unchanged
#--------
is_deeply(
	interpolate({ v => [ undef, undef, undef ] }),
	{ v => [ undef, undef, undef ] },
	'no anchor: sequence unchanged');

#--------
# cols restriction: untouched column keeps its NA
#--------
is_deeply(
	interpolate([ { a => 1, b => 1 }, { a => undef, b => undef }, { a => 3, b => 3 } ],
		cols => [ 'a' ]),
	[ { a => 1, b => 1 }, { a => 2, b => undef }, { a => 3, b => 3 } ],
	'cols=[a]: only a interpolated');

#--------
# AoA short row not extended past its length
#--------
is_deeply(
	interpolate([ [ 1, 1 ], [ undef ], [ 3, 3 ] ], cols => [ 0, 1 ]),
	[ [ 1, 1 ], [ 2 ], [ 3, 3 ] ],
	'AoA: short row filled at col 0 only, not extended to col 1');

#--------
# non-ref row preserved, not fabricated
#--------
is_deeply(
	interpolate([ { v => 1 }, undef, { v => 3 } ]),
	[ { v => 1 }, undef, { v => 3 } ],
	'AoH: undef row preserved (no anchor bridge across it)');

#========
# error paths
#========
dies_ok { interpolate(undef) } 'undef data dies';
throws_ok { interpolate([ { a => 1 } ], 'oddarg') }
	qr/name => value pairs/, 'odd trailing args die';
throws_ok { interpolate([ { a => 1 } ], bogus => 1) }
	qr/unknown argument/, 'unknown argument dies';
throws_ok { interpolate([ { a => 1 } ], cols => [ 'Z' ]) }
	qr/column 'Z' not found/, 'unknown column dies';
throws_ok { interpolate([ { a => 1 } ], cols => 'a') }
	qr/'cols' must be an arrayref/, 'non-arrayref cols dies';
throws_ok { interpolate([ { a => 1 } ], limit => 0) }
	qr/positive integer/, 'limit=0 dies';
throws_ok { interpolate([ { a => 1 } ], limit => 1.5) }
	qr/positive integer/, 'non-integer limit dies';
throws_ok { interpolate([ { a => 1 } ], method => 'bogus') }
	qr/unknown method/, 'unknown method dies';
throws_ok { interpolate([ { a => 1 } ], method => 'polynomial') }
	qr/requires an integer 'order'/, 'polynomial without order dies';
throws_ok { interpolate([ { a => 1 } ], limit_direction => 'sideways') }
	qr/limit_direction/, 'bad limit_direction dies';
throws_ok { interpolate([ { a => 1 } ], limit_area => 'edge') }
	qr/limit_area/, 'bad limit_area dies';

#========
# memory
#========
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
no_leaks_ok {
	my $x = interpolate({ v => [ undef, 1, undef, undef, 4, undef ] });
} 'interpolate: no memory leaks (HoA)';

no_leaks_ok {
	my $x = interpolate([ { v => 1 }, { v => undef }, { v => 3 } ],
		limit_direction => 'both', limit => 1);
} 'interpolate: no memory leaks (AoH, options)';

no_leaks_ok {
	eval { interpolate([ { a => 1 } ], cols => [ 'Z' ]) };
} 'interpolate: no memory leaks (die path)';

done_testing;
