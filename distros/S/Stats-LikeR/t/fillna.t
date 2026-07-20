#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# fillna / ffill / bfill: NA (undef) imputation, like pandas.
#   * fillna(value => $scalar)            fill every NA (or only within `cols`)
#   * fillna(value => { col => v, ... })  per-column fill; unknown keys ignored,
#                                         and `cols` is then forbidden
#   * ffill / bfill propagate the last / next valid value along the row axis;
#     `limit` caps consecutive fills per gap, `cols` restricts the columns
#   * column ids are names (AoH/HoA/HoH) or 0-based positions (AoA); a missing
#     hash key counts as NA and is materialised on fill; AoA rows are not
#     extended past their own length; HoH uses sorted-key row order
#   * all three return a NEW frame; the original is never modified

#========
# fillna: scalar
#========

#--------
# scalar fill, all four shapes
#--------
is_deeply(fillna([ { a => 1, b => undef }, { a => undef, b => 4 } ], value => 0),
	[ { a => 1, b => 0 }, { a => 0, b => 4 } ], 'fillna scalar AoH');

is_deeply(fillna({ r1 => { a => undef }, r2 => { a => 2 } }, value => 0),
	{ r1 => { a => 0 }, r2 => { a => 2 } }, 'fillna scalar HoH');

is_deeply(fillna({ a => [ 1, undef, 3 ], b => [ undef ] }, value => 0),
	{ a => [ 1, 0, 3 ], b => [ 0, 0, 0 ] },
	'fillna scalar HoA (ragged extended to max length)');

is_deeply(fillna([ [ 1, undef ], [ undef, 4 ] ], value => 0),
	[ [ 1, 0 ], [ 0, 4 ] ], 'fillna scalar AoA');

#--------
# original untouched
#--------
{
	my $df = [ { a => 1, b => undef } ];
	fillna($df, value => 0);
	is_deeply($df, [ { a => 1, b => undef } ], 'fillna: input not mutated');
}

#--------
# per-column dict; unknown dict key ignored
#--------
is_deeply(fillna([ { a => undef, b => undef } ], value => { a => 9, Z => 1 }),
	[ { a => 9, b => undef } ],
	'fillna dict: named col filled, unknown key ignored, others left NA');

#--------
# scalar + cols restriction
#--------
is_deeply(fillna([ { a => undef, b => undef } ], value => 7, cols => [ 'b' ]),
	[ { a => undef, b => 7 } ], 'fillna scalar cols=[b] restricts fill');

#--------
# missing hash key counts as NA and is materialised
#--------
is_deeply(fillna([ { a => 1 }, { a => 2, b => 5 } ], value => 0, cols => [ 'b' ]),
	[ { a => 1, b => 0 }, { a => 2, b => 5 } ],
	'fillna materialises missing hash key');

#--------
# AoA short row not extended past its length
#--------
is_deeply(fillna([ [ 1, undef ], [ undef ] ], value => 0),
	[ [ 1, 0 ], [ 0 ] ], 'fillna AoA: short row not extended');

#--------
# a structurally-undef/non-ref row is preserved, not fabricated into data
# (consistent across all shapes and with ffill/bfill)
#--------
is_deeply(
	fillna([ { a => 1, b => undef }, undef, { a => undef, b => 4 } ], value => 0),
	[ { a => 1, b => 0 }, undef, { a => 0, b => 4 } ],
	'fillna AoH: undef row preserved, not fabricated');
is_deeply(
	fillna({ r1 => { a => 1, b => undef }, r2 => undef, r3 => { a => undef, b => 4 } },
		value => 0),
	{ r1 => { a => 1, b => 0 }, r2 => undef, r3 => { a => 0, b => 4 } },
	'fillna HoH: undef row preserved, not fabricated');
is_deeply(
	fillna([ [ 1, undef ], undef, [ undef, 4 ] ], value => 0),
	[ [ 1, 0 ], undef, [ 0, 4 ] ],
	'fillna AoA: undef row preserved, not fabricated');

#========
# ffill / bfill
#========

#--------
# ffill / bfill basic, AoH
#--------
is_deeply(
	ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 }, { v => undef } ], cols => [ 'v' ]),
	[ { v => 1 }, { v => 1 }, { v => 1 }, { v => 4 }, { v => 4 } ],
	'ffill AoH: forward propagation');

is_deeply(
	bfill([ { v => undef }, { v => 2 }, { v => undef } ], cols => [ 'v' ]),
	[ { v => 2 }, { v => 2 }, { v => undef } ],
	'bfill AoH: backward propagation, trailing NA stays');

#--------
# limit caps consecutive fills, and resets each gap
#--------
is_deeply(
	ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 }, { v => undef } ],
		cols => [ 'v' ], limit => 1),
	[ { v => 1 }, { v => 1 }, { v => undef }, { v => 4 }, { v => 4 } ],
	'ffill limit=1: one fill per gap, gap resets after a real value');

#--------
# cols restriction: untouched column keeps its NA
#--------
is_deeply(
	ffill([ { a => 1, b => 1 }, { a => undef, b => undef } ], cols => [ 'a' ]),
	[ { a => 1, b => 1 }, { a => 1, b => undef } ],
	'ffill cols=[a]: only a propagated');

#--------
# default cols = every column
#--------
is_deeply(
	ffill([ { a => 1, b => 2 }, { a => undef, b => undef } ]),
	[ { a => 1, b => 2 }, { a => 1, b => 2 } ],
	'ffill default: all columns propagated');

#--------
# HoA
#--------
is_deeply(ffill({ v => [ 1, undef, undef, 4 ] }),
	{ v => [ 1, 1, 1, 4 ] }, 'ffill HoA');

#--------
# AoA positional column
#--------
is_deeply(ffill([ [ 1, 10 ], [ undef, undef ] ], cols => [ 0 ]),
	[ [ 1, 10 ], [ 1, undef ] ], 'ffill AoA positional col 0');

#--------
# HoH uses sorted-key row order
#--------
is_deeply(
	ffill({ b => { x => undef }, a => { x => 5 }, c => { x => undef } }, cols => [ 'x' ]),
	{ a => { x => 5 }, b => { x => 5 }, c => { x => 5 } },
	'ffill HoH: sorted-key order a,b,c propagates forward');

is_deeply(
	bfill({ b => { x => undef }, a => { x => 5 }, c => { x => undef } }, cols => [ 'x' ]),
	{ a => { x => 5 }, b => { x => undef }, c => { x => undef } },
	'bfill HoH: nothing after a to back-fill from');

#--------
# original untouched (ffill)
#--------
{
	my $df = [ { v => 1 }, { v => undef } ];
	ffill($df);
	is_deeply($df, [ { v => 1 }, { v => undef } ], 'ffill: input not mutated');
}

#========
# error paths
#========
dies_ok { fillna(undef, value => 0) } 'fillna undef data dies';
throws_ok { fillna([ { a => 1 } ]) }
	qr/a 'value' is required/, 'fillna without value dies';
throws_ok { fillna([ { a => 1 } ], 'oddarg') }
	qr/name => value pairs/, 'fillna odd trailing args die';
throws_ok { fillna([ { a => 1 } ], value => 0, bogus => 1) }
	qr/unknown argument/, 'fillna unknown argument dies';
throws_ok { fillna([ { a => 1 } ], value => 0, cols => [ 'Z' ]) }
	qr/column 'Z' not found/, 'fillna scalar cols: missing column dies';
throws_ok { fillna([ { a => 1 } ], value => { a => 1 }, cols => [ 'a' ]) }
	qr/cannot be combined/, 'fillna dict + cols conflict dies';

dies_ok { ffill(undef) } 'ffill undef data dies';
throws_ok { ffill([ { a => 1 } ], 'oddarg') }
	qr/name => value pairs/, 'ffill odd trailing args die';
throws_ok { ffill([ { a => 1 } ], bogus => 1) }
	qr/unknown argument/, 'ffill unknown argument dies';
throws_ok { ffill([ { a => 1 } ], cols => [ 'Z' ]) }
	qr/column 'Z' not found/, 'ffill unknown column dies';
throws_ok { ffill([ { a => 1 } ], limit => 0) }
	qr/positive integer/, 'ffill limit=0 dies';
throws_ok { bfill([ { a => 1 } ], limit => 1.5) }
	qr/positive integer/, 'bfill non-integer limit dies';

#========
# memory
#========
no_leaks_ok {
	my $x = fillna([ { a => 1, b => undef }, { a => undef, b => 4 } ], value => 0);
} 'fillna: no memory leaks (scalar AoH)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = fillna([ { a => undef } ], value => { a => 9 });
} 'fillna: no memory leaks (dict)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = ffill([ { v => 1 }, { v => undef }, { v => 3 } ], limit => 1);
} 'ffill: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = bfill({ v => [ undef, 2, undef ] });
} 'bfill: no memory leaks (HoA)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { fillna([ { a => 1 } ], value => 0, cols => [ 'Z' ]) };
} 'fillna: no memory leaks (die path)' unless $INC{'Devel/Cover.pm'};

done_testing;
