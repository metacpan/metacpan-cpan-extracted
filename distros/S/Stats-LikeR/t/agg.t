#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

dies_ok {
	agg(undef, 'x');
} 'agg: dies when given undefined data';
# shared fixture, expressed in every shape
#   sex  wt   age
#   M    70   30
#   F    60   25
#   M    80   40
#   F    55   undef
my $AoH = [
	{ sex => 'M', wt => 70, age => 30    },
	{ sex => 'F', wt => 60, age => 25    },
	{ sex => 'M', wt => 80, age => 40    },
	{ sex => 'F', wt => 55, age => undef },
];
my $HoA = {
	sex => [ 'M', 'F', 'M', 'F'     ],
	wt  => [ 70,  60,  80,  55      ],
	age => [ 30,  25,  40,  undef   ],
};
my $HoH = {
	p1 => { sex => 'M', wt => 70, age => 30    },
	p2 => { sex => 'F', wt => 60, age => 25    },
	p3 => { sex => 'M', wt => 80, age => 40    },
	p4 => { sex => 'F', wt => 55, age => undef },
};
# AoA: col 0 = sex, col 1 = wt, col 2 = age
my $AoA = [
	[ 'M', 70, 30    ],
	[ 'F', 60, 25    ],
	[ 'M', 80, 40    ],
	[ 'F', 55, undef ],
];

# grouped AoH, single aggregator keeps the column name
{
	my $g = agg($AoH, by => 'sex', agg => { wt => 'mean' });
	is(scalar @$g, 2, 'AoH/mean: two groups');
	my %by = map { $_->{sex} => $_ } @$g;
	is($g->[0]{sex}, 'F', 'AoH/mean: groups sorted (F first)');
	is_approx($by{F}{wt}, 57.5, 'AoH/mean: F mean wt');
	is_approx($by{M}{wt}, 75,   'AoH/mean: M mean wt');
	ok(!exists $by{F}{wt_mean}, 'AoH/mean: single func keeps bare column name');
}

# grouped AoH, multiple aggregators -> <col>_<func>, plus a count on a label col
{
	my $g  = agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] });
	my %by = map { $_->{sex} => $_ } @$g;
	is_approx($by{F}{wt_mean}, 57.5,          'AoH/multi: F wt_mean');
	is_approx($by{F}{wt_sd},   sqrt(12.5),    'AoH/multi: F wt_sd');
	is_approx($by{M}{wt_sd},   sqrt(50),      'AoH/multi: M wt_sd');
	is_approx($by{F}{age_mean}, 25,           'AoH/multi: F age mean skips undef');
	is($by{F}{age_count}, 1, 'AoH/multi: F age count excludes the undef');
}

# ungrouped: whole frame collapses to one row (pandas df.agg)
{
	my $u = agg($AoH, agg => { wt => 'mean', age => 'count' });
	is(scalar @$u, 1, 'ungrouped: single row');
	is_approx($u->[0]{wt}, 66.25, 'ungrouped: mean wt');
	is($u->[0]{age}, 3, 'ungrouped: count ignores the undef age');
}

# every shape yields the same grouped means (normalised to aoh output)
{
	for my $case ([ 'HoA', $HoA, 'sex', 'wt' ], [ 'HoH', $HoH, 'sex', 'wt' ], [ 'AoA', $AoA, 0, 1 ]) {
		my ($name, $df, $bycol, $wtcol) = @$case;
		my $g = agg($df, by => $bycol, agg => { $wtcol => 'mean' }, 'output_type' => 'aoh');
		my %by = map { $_->{$bycol} => $_->{$wtcol} } @$g;
		is_approx($by{F}, 57.5, "$name: F mean wt");
		is_approx($by{M}, 75,   "$name: M mean wt");
	}
	# default output type mirrors the input family
	is(ref agg($HoA, by => 'sex', agg => { wt => 'mean' }), 'HASH',
		'default output: HoA in -> hashref out');
	is(ref agg($AoA, by => 0, agg => { 1 => 'mean' }), 'ARRAY',
		'default output: AoA in -> arrayref out');
}

# output_type overrides
{
	my $hoh = agg($HoA, by => 'sex', agg => { wt => 'mean' }, 'output_type' => 'hoh');
	is_approx($hoh->{F}{wt}, 57.5, 'output hoh: keyed by group value');
	is($hoh->{M}{sex}, 'M', 'output hoh: retains grouping column');

	my $hoa = agg($AoH, by => 'sex', agg => { wt => 'mean' }, 'output_type' => 'hoa');
	is(ref $hoa, 'HASH', 'output hoa: is a hashref');
	is_approx($hoa->{wt}[0], 57.5, 'output hoa: column-major values');

	my $aoa = agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'max' ] }, 'output_type' => 'aoa');
	is_approx($aoa->[1][1], 75, 'output aoa: positional mean for M');
	is_approx($aoa->[1][2], 80, 'output aoa: positional max for M');

	throws_ok { agg($AoH, agg => { wt => 'mean' }, 'output_type' => 'bogus') }
		qr/output_type 'bogus' isn't allowed/, 'output_type validated';
}

# named aggregators, exercised on one column
{
	my $df = [ map { { g => 'x', v => $_ } } (2, 4, 4, 4, 5, 5, 7, 9) ];
	push @$df, { g => 'x', v => undef };            # one NA
	my %want = (
		mean    => 5,
		median  => 4.5,
		sum     => 40,
		sd      => sd(2, 4, 4, 4, 5, 5, 7, 9),
		var     => var(2, 4, 4, 4, 5, 5, 7, 9),
		min     => 2,
		max     => 9,
		count   => 8,                                # defined only
		n       => 9,                                # includes the undef
		nunique => 5,                                # 2,4,5,7,9
		first   => 2,
		last    => 9,
		mode    => 4,
	);
	for my $f (sort keys %want) {
		my $r = agg($df, agg => { v => $f });
		is_approx($r->[0]{v}, $want{$f}, "aggregator $f");
	}
}

# mode tie-breaking is deterministic
{
	my $num = agg([ map { { v => $_ } } (3, 1, 3, 1) ], agg => { v => 'mode' });
	is($num->[0]{v}, 1, 'mode: numeric tie -> smallest');
	my $str = agg([ map { { v => $_ } } qw(b a b a) ], agg => { v => 'mode' });
	is($str->[0]{v}, 'a', 'mode: string tie -> lowest');
}

# skipna
{
	my $keep = agg($AoH, by => 'sex', agg => { age => 'mean' }, skipna => 1);
	my %k = map { $_->{sex} => $_->{age} } @$keep;
	is_approx($k{F}, 25, 'skipna=1: undef dropped, mean over the rest');

	my $strict = agg($AoH, by => 'sex', agg => { age => 'mean' }, skipna => 0);
	my %s = map { $_->{sex} => $_ } @$strict;
	ok(!defined $s{F}{age}, 'skipna=0: any undef poisons a numeric reducer');
	is_approx($s{M}{age}, 35, 'skipna=0: clean group still aggregates');
}

# too few defined values -> undef (sd/var need >= 2, mean etc. need >= 1)
{
	my $one = agg([ { g => 'a', v => 5 } ], by => 'g', agg => { v => [ 'mean', 'sd', 'var' ] });
	is_approx($one->[0]{v_mean}, 5, 'single value: mean defined');
	ok(!defined $one->[0]{v_sd},  'single value: sd undef');
	ok(!defined $one->[0]{v_var}, 'single value: var undef');

	my $none = agg([ { g => 'a', v => undef } ], by => 'g', agg => { v => [ 'mean', 'count' ] });
	ok(!defined $none->[0]{v_mean}, 'all-NA group: mean undef');
	is($none->[0]{v_count}, 0, 'all-NA group: count 0');
}

# coderef aggregator receives every cell (undef included)
{
	my $r = agg($AoH, by => 'sex', agg => { age => sub {
		my $cells = shift;
		my $na = grep { !defined } @$cells;
		"$na NA of " . scalar(@$cells);
	} });
	my %by = map { $_->{sex} => $_->{age} } @$r;
	is($by{F}, '1 NA of 2', 'coderef: sees raw cells incl. undef');
	is($by{M}, '0 NA of 2', 'coderef: clean group');
}

# sort => 0 preserves first-seen group order
{
	my $seen = agg($AoH, by => 'sex', agg => { wt => 'mean' }, sort => 0);
	is($seen->[0]{sex}, 'M', 'sort=0: first-seen order (M appears first)');
}

# multiple grouping columns; hoh labels join with '.'
{
	my $df = [
		{ a => 1, b => 'x', v => 10 },
		{ a => 1, b => 'x', v => 20 },
		{ a => 1, b => 'y', v => 30 },
		{ a => 2, b => 'y', v => 40 },
	];
	my $aoh = agg($df, by => [ 'a', 'b' ], agg => { v => 'sum' });
	is(scalar @$aoh, 3, 'multi-key: three groups');
	my %by = map {; ( "$_->{a}.$_->{b}" => $_->{v} ) } @$aoh;
	is($by{'1.x'}, 30, 'multi-key: 1/x summed');
	my $hoh = agg($df, by => [ 'a', 'b' ], agg => { v => 'sum' }, 'output_type' => 'hoh');
	is_approx($hoh->{'1.x'}{v}, 30, 'multi-key hoh: label joined with dot');
	ok(exists $hoh->{'2.y'}, 'multi-key hoh: all labels present');
}

# error handling
throws_ok { agg('scalar', agg => { v => 'mean' }) }
	qr/data frame must be an ARRAY/, 'non-ref df dies';
throws_ok { agg($AoH) }
	qr/'agg' spec .* is required/, 'missing agg spec dies';
throws_ok { agg($AoH, agg => { wt => 'mean' }, bogus => 1) }
	qr/unknown argument/, 'unknown option dies';
throws_ok { agg($AoH, agg => { wt => 'bogus' }) }
	qr/unknown aggregator 'bogus'/, 'bad aggregator name dies';
throws_ok { agg($AoH, agg => { wt => [] }) }
	qr/empty aggregator list/, 'empty aggregator list dies';
throws_ok { agg($AoH, agg => { wt => 'mean' }, 'extra') }
	qr/name => value pairs/, 'odd trailing args die';

# ---- regressions fixed in 0.3213 ---------------------------------------------
# A coderef runs in scalar context.  Its return value used to be pushed in list
# context, so an empty list or several values shifted every later column of
# the row: { a => sub { grep .. } } put b's sum into a.
{
	my $df = [ { g => 1, a => 1, b => 2 } ];
	is_deeply(agg($df, by => 'g', agg => { a => sub { return }, b => 'sum' }, 'output_type' => 'aoa'),
		[ [ 1, undef, 2 ] ], 'coderef returning () yields undef, b stays in place');
	is_deeply(agg($df, by => 'g', agg => { a => sub { (7, 8) }, b => 'sum' }),
		[ { g => 1, a => 8, b => 2 } ], 'coderef returning a list yields its last value');
	is_deeply(agg($df, by => 'g', agg => { a => sub { grep { $_ > 5 } @{ $_[0] } }, b => 'sum' }),
		[ { g => 1, a => 0, b => 2 } ], 'grep in a coderef counts, as scalar context does');
}

# Output names never collide silently.
{
	my $df = [ { g => 'a' }, { g => 'a' }, { g => 'b' } ];
	is_deeply(agg($df, by => 'g', agg => { g => 'count' }),
		[ { g => 'a', g_count => 2 }, { g => 'b', g_count => 1 } ],
		'aggregating a by column names it <col>_<func>, keeping the key');
	is_deeply(agg($df, by => 'g', agg => { g => 'count' }, 'output_type' => 'hoa'),
		{ g => [ 'a', 'b' ], g_count => [ 2, 1 ] }, '... and hoa columns stay aligned');
	is_deeply(agg([ { v => 1 }, { v => 3 } ], agg => { v => [ sub { 'A' }, sub { 'B' } ] }),
		[ { v_fn1 => 'A', v_fn2 => 'B' } ], 'two coderefs are fn1 and fn2');
	is_deeply(agg([ { v => 1 }, { v => 3 } ], agg => { v => [ 'sum', sub { 'B' } ] }),
		[ { v_sum => 4, v_fn => 'B' } ], 'one coderef among names is fn');
	throws_ok { agg([ { v => 1, v_sum => 5 } ], agg => { v => [ 'sum', 'mean' ], v_sum => 'max' },
	                'output_type' => 'hoa') }
		qr/output column name\(s\) generated twice: v_sum/, 'a generated name colliding with a column dies';
	throws_ok { agg([ { v => 1 } ], agg => { v => [ 'mean', 'mean' ] }) }
		qr/generated twice: v_mean/, 'the same reducer twice dies for named output';
	is_deeply(agg([ [ 1 ] ], agg => { 0 => [ 'mean', 'mean' ] }), [ [ 1, 1 ] ],
		'... and is allowed for positional aoa output');
}

# Group order: each key column decides numeric-or-string by itself, undef sorts
# last, and NaN after the numbers.  One undef key, or one string column
# alongside, used to make every number sort as a string (10 before 2), and a
# NaN key died inside sort under FATAL warnings.
{
	my $ord = sub { [ map { $_->[0] } @{ agg([ map { { g => $_, v => 1 } } @_ ], by => 'g',
	                                         agg => { v => 'n' }, 'output_type' => 'aoa') } ] };
	is_deeply($ord->(10, 9, 2, undef), [ 2, 9, 10, undef ], 'undef key sorts last; numbers numerically');
	is_deeply($ord->('b', undef, 'a'), [ 'a', 'b', undef ], 'undef sorts last among strings too');
	is_deeply($ord->('nan', 1, 2, undef), [ 1, 2, 'nan', undef ], 'NaN after numbers, before undef');
	my $two = agg([ map { { s => 'a', g => $_, v => 1 } } 10, 9, 2 ], by => [ 's', 'g' ],
	              agg => { v => 'n' }, 'output_type' => 'aoa');
	is_deeply([ map { $_->[1] } @$two ], [ 2, 9, 10 ], 'a numeric column sorts numerically beside a string one');
	my $mix = agg([ map { { a => $_->[0], b => $_->[1], v => 1 } } [ 2, 'x' ], [ 10, 'x' ], [ 1, undef ] ],
	              by => [ 'a', 'b' ], agg => { v => 'n' }, 'output_type' => 'aoa');
	is_deeply([ map { $_->[0] } @$mix ], [ 1, 2, 10 ], 'an undef in another key column changes nothing');
}

# Group keys: cells are length-prefixed, so a tuple can no longer be built two
# ways (the "\x1e" separator used to make these one group), and a string is
# keyed the way a perl hash keys it.
{
	my $g = agg([ { a => "p\x1evq", b => 'r', v => 1 }, { a => 'p', b => "q\x1evr", v => 2 } ],
	            by => [ 'a', 'b' ], agg => { v => 'sum' });
	is(scalar @$g, 2, 'a separator inside a key value does not merge two groups');
	my $e9 = "\xe9"; my $u = "\xe9"; utf8::upgrade($u);
	is(scalar @{ agg([ { k => $e9, v => 1 }, { k => $u, v => 2 } ], by => 'k', agg => { v => 'n' }) }, 1,
		'Latin-1 bytes and their UTF-8 upgrade are one group, as in a perl hash');
	is(scalar @{ agg([ { k => "\x{263A}", v => 1 }, { k => "\xe2\x98\xba", v => 2 } ],
	                 by => 'k', agg => { v => 'n' }) }, 2,
		'a wide character and its UTF-8 bytes are two groups, as in a perl hash');
	is(scalar @{ agg([ { k => 1, v => 1 }, { k => 1.0, v => 1 }, { k => '1', v => 1 } ],
	                 by => 'k', agg => { v => 'n' }) }, 1,
		'IV 1, NV 1 and the string "1" are one group (they stringify alike)');
	is(scalar @{ agg([ { k => 1, v => 1 }, { k => '1.0', v => 1 } ], by => 'k', agg => { v => 'n' }) }, 2,
		'the string "1.0" is its own group: keys compare as strings');
}

# skipna => 0 now covers min and max, as pandas' skipna=False does
{
	my $r = agg([ { v => undef }, { v => 2 } ], agg => { v => [ 'min', 'max', 'mean', 'count', 'n' ] }, skipna => 0);
	is_deeply($r, [ { v_min => undef, v_max => undef, v_mean => undef, v_count => 1, v_n => 2 } ],
		'skipna=0: undef poisons min and max as well; count and n are untouched');
}

# Validation and edge cases
{
	for my $case ([ AoH => [ { wt => 1 } ] ], [ HoH => { r => { wt => 1 } } ], [ HoA => { wt => [1] } ]) {
		throws_ok { agg($case->[1], agg => { wgt => 'mean' }) }
			qr/agg: column 'wgt' not found/, "$case->[0]: a misspelled column dies";
		throws_ok { agg($case->[1], by => 'grp', agg => { wt => 'mean' }) }
			qr/agg: column 'grp' not found/, "$case->[0]: a misspelled by column dies";
	}
	throws_ok { agg([ [ 1 ] ], agg => { 5 => 'mean' }) }
		qr/agg: column '5' not found/, 'AoA: a position past every row dies';
	throws_ok { agg([ [ 1 ] ], agg => { x => 'mean' }) }
		qr/AoA columns are integer positions, not 'x'/, 'AoA: a non-integer column dies';
	is_deeply(agg([ [ 'a', 1, 5 ], [ 'a', 2, 7 ] ], by => 0, agg => { -1 => 'sum' }),
		[ [ 'a', 12 ] ], 'AoA: a negative position counts from the end, as $row->[-1]');
	throws_ok { agg({ v => 1 }, agg => { v => 'mean' }) }
		qr/column 'v' is not an ARRAY reference/, 'HoA: a non-array column dies';
	throws_ok { agg([ { v => 1 } ], by => [ undef ], agg => { v => 'mean' }) }
		qr/'by' contains an undefined column/, 'an undef by column dies';
	throws_ok { agg([ { v => 1 } ], agg => { v => [ undef ] }) }
		qr/must be a name or a coderef/, 'an undef aggregator dies';
	throws_ok { agg([ { v => 1 }, 'x' ], agg => { v => 'mean' }) }
		qr/row 1 is not a HASH reference/, 'a non-hash row in an AoH dies';
	is_deeply(agg([ { v => 1 }, undef, { v => 3 } ], agg => { v => [ 'sum', 'n' ] }),
		[ { v_sum => 4, v_n => 2 } ], 'an undef row is skipped, not counted');
	throws_ok { agg([ { g => 'F', v => 'abc' } ], by => 'g', agg => { v => 'mean' }) }
		qr/agg: mean of column 'v' over group \(g = 'F'\): mean: non-numeric value/,
		'a non-numeric cell names the reducer, column and group';
	throws_ok { agg([ { v => 'abc' } ], agg => { v => 'sum' }) }
		qr/agg: sum of column 'v' over the whole frame/, '... and the whole frame when ungrouped';
	throws_ok { agg([ { v => 1 } ], agg => { v => 'bogus' }) }
		qr/unknown aggregator 'bogus'/, 'an unknown aggregator dies even before any group';
	is_deeply(agg([], agg => { v => [ 'count', 'n', 'mean', 'first', 'nunique' ] }),
		[ { v_count => 0, v_n => 0, v_mean => undef, v_first => undef, v_nunique => 0 } ],
		'an empty frame, ungrouped, is one row (pandas df.agg)');
	is_deeply(agg({ v => [] }, agg => { v => sub { scalar @{ $_[0] } } }), { v => [ 0 ] },
		'... in every shape, with a coderef seeing no cells');
	is_deeply(agg([], by => 'g', agg => { v => 'count' }), [], 'an empty frame, grouped, has no groups');
	is_deeply(agg({ g => [ 'a', 'a', 'b' ], v => [ 1 ] }, by => 'g', agg => { v => [ 'n', 'count' ] }),
		{ g => [ 'a', 'b' ], v_n => [ 2, 1 ], v_count => [ 1, 0 ] },
		'a ragged HoA pads its short columns with undef');
}

# The caller's frame is left exactly as it was.  Grouping on a numeric column
# used to stringify every key cell ("v$v"), leaving a PV on each; mean() over
# shared string cells would cache an NV on them; and a coderef sees copies.
{
	require B;
	my $flags = sub { B::svref_2object($_[0])->FLAGS };
	my $num = [ map { { g => $_ % 3, x => $_ + 0.5, s => "$_" } } 1 .. 30 ];
	agg($num, by => 'g', agg => { x => [ 'mean', 'mode', 'nunique' ], s => [ 'mean', 'sd' ] });
	ok(!grep({ $flags->(\$_->{g}) & B::SVp_POK() } @$num), 'numeric key cells gain no string value');
	ok(!grep({ $flags->(\$_->{x}) & B::SVp_POK() } @$num), 'numeric cells read by mode/nunique gain no string value');
	ok(!grep({ $flags->(\$_->{s}) & (B::SVp_NOK() | B::SVp_IOK()) } @$num), 'string cells averaged gain no numeric value');
	agg($num, agg => { x => sub { $_[0][0] = 'clobbered'; 1 } });
	is($num->[0]{x}, 1.5, 'a coderef writing to its cells does not reach the frame');
}

# Tied frames are read through their FETCH, cell by cell
{
	require Tie::Array; require Tie::Hash;
	tie my @rows, 'Tie::StdArray';
	for my $r ([ 'a', 1 ], [ 'b', 2 ], [ 'a', 3 ]) {
		tie my %h, 'Tie::StdHash'; %h = (g => $r->[0], v => $r->[1]); push @rows, \%h;
	}
	is_deeply(agg(\@rows, by => 'g', agg => { v => [ 'sum', 'mean' ] }),
		[ { g => 'a', v_sum => 4, v_mean => 2 }, { g => 'b', v_sum => 2, v_mean => 2 } ],
		'a tied AoH of tied rows');
	tie my @col, 'Tie::StdArray'; @col = (5, 6, 7);
	is_deeply(agg({ g => [ 1, 2, 1 ], v => \@col }, by => 'g', agg => { v => 'sum' }),
		{ g => [ 1, 2 ], v => [ 12, 6 ] }, 'a HoA with a tied column');
}

# Against a plain-perl split, over many groups and every shape
{
	srand(20261001);
	my @aoh = map { { k => int(rand 400), h => (qw(x y z))[rand 3],
	                  v => (rand() < 0.1 ? undef : int(rand 1000) / 8) } } 1 .. 4000;
	my %ref;
	for my $r (@aoh) {
		my $k = join "\0", $r->{k}, $r->{h};
		my $e = $ref{$k} ||= [ $r->{k}, $r->{h}, 0, 0, 0 ];
		$e->[2]++;
		next unless defined $r->{v};
		$e->[3]++; $e->[4] += $r->{v};
	}
	my @want = map { [ $_->[0], $_->[1], $_->[3], $_->[2], $_->[3] ? $_->[4] : undef ] }
		sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } values %ref;
	my @cols = qw(k h v);
	my %hoa = map { my $c = $_; ($c => [ map { $_->{$c} } @aoh ]) } @cols;
	my %hoh = map { (sprintf('r%05d', $_) => $aoh[$_]) } 0 .. $#aoh;
	my @aoa = map { [ @{$_}{@cols} ] } @aoh;
	my $spec = { v => [ 'count', 'n', 'sum' ] };
	is_deeply(agg(\@aoh, by => [ 'k', 'h' ], agg => $spec, 'output_type' => 'aoa'), \@want,
		'AoH: 4000 rows in ~1200 groups match a plain-perl split');
	is_deeply(agg(\%hoa, by => [ 'k', 'h' ], agg => $spec, 'output_type' => 'aoa'), \@want, 'HoA: likewise');
	is_deeply(agg(\%hoh, by => [ 'k', 'h' ], agg => $spec, 'output_type' => 'aoa'), \@want, 'HoH: likewise');
	is_deeply(agg(\@aoa, by => [ 0, 1 ], agg => { 2 => $spec->{v} }), \@want, 'AoA: likewise');
}

# no memory leaks across shapes
no_leaks_ok {
	agg($AoH, by => 'sex', agg => { wt => [ 'mean', 'sd' ], age => 'count' });
} 'agg(): AoH grouped no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($HoA, by => 'sex', agg => { wt => 'mean' }, 'output_type' => 'hoh');
} 'agg(): HoA -> hoh no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($HoH, by => 'sex', agg => { wt => 'sum' });
} 'agg(): HoH no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($AoA, by => 0, agg => { 1 => [ 'mean', 'max' ] });
} 'agg(): AoA no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($AoH, agg => { age => sub { scalar @{ $_[0] } } });
} 'agg(): coderef no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg($AoH, by => 'sex', agg => { wt => [ 'mode', 'nunique', 'first' ], age => [ 'min', 'n' ] },
	    skipna => 0, 'output_type' => 'hoa');
} 'agg(): copied and shared cells, skipna=0, no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { agg([ { g => 'F', v => 'abc' }, { g => 'M', v => 1 } ], by => 'g', agg => { v => 'mean' }) };
} 'agg(): a reducer dying mid-way does not leak' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { agg([ { v => 1 }, 'x' ], agg => { v => 'mean' }) };
} 'agg(): the XS split croaking on a bad row does not leak' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	agg([], agg => { v => 'count' });
	agg([ { k => "\x{263A}", v => 1 }, { k => 'nan', v => 2 }, { k => undef, v => 3 } ],
	    by => 'k', agg => { v => 'sum' });
} 'agg(): empty frame, wide-character, NaN and undef keys, no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
