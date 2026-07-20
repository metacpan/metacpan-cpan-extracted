#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# pivot_table: long -> wide with aggregation, like pandas pivot_table.
#   * 'columns' is required; rows whose columns-tuple contains NA are skipped
#   * 'values' defaults to every column that is neither index nor columns
#   * a single value + single aggfunc names each output column after the
#     columns-tuple alone; multiple values and/or funcs prefix value / func
#     (aggfunc-major ordering), joined with 'sep' (default '.')
#   * rows/columns are sorted by default (numeric-if-all-numeric else string);
#     sort => 0 keeps first-seen order
#   * skipna => 0 makes a numeric reducer return NA if the bucket has any NA
#   * fill_value substitutes NA result cells
#   * 'output.type' defaults to the input family

# floating-point scalar comparison (per project convention)
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
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

my $wide = [
	{ city => 'NY', year => 2020, temp => 10 },
	{ city => 'NY', year => 2020, temp => 20 },
	{ city => 'NY', year => 2021, temp => 30 },
	{ city => 'LA', year => 2020, temp => 40 },
	{ city => 'LA', year => 2021, temp => 50 },
];

#--------
# default aggfunc = mean, AoH -> AoH (rows & columns sorted)
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', values => 'temp'),
	[ { city => 'LA', 2020 => 40, 2021 => 50 },
	  { city => 'NY', 2020 => 15, 2021 => 30 } ],
	'mean pivot, single value/func flat column names, sorted rows/cols');

#--------
# original frame untouched
#--------
is_deeply($wide, [
	{ city => 'NY', year => 2020, temp => 10 },
	{ city => 'NY', year => 2020, temp => 20 },
	{ city => 'NY', year => 2021, temp => 30 },
	{ city => 'LA', year => 2020, temp => 40 },
	{ city => 'LA', year => 2021, temp => 50 },
], 'input frame not mutated');

#--------
# aggfunc = sum
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', values => 'temp', aggfunc => 'sum'),
	[ { city => 'LA', 2020 => 40, 2021 => 50 },
	  { city => 'NY', 2020 => 30, 2021 => 30 } ],
	'sum aggfunc');

#--------
# aggfunc = count
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', values => 'temp', aggfunc => 'count'),
	[ { city => 'LA', 2020 => 1, 2021 => 1 },
	  { city => 'NY', 2020 => 2, 2021 => 1 } ],
	'count aggfunc');

#--------
# coderef aggfunc (receives every cell, incl undef)
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
		aggfunc => sub { my $c = shift; scalar grep { defined } @$c }),
	[ { city => 'LA', 2020 => 1, 2021 => 1 },
	  { city => 'NY', 2020 => 2, 2021 => 1 } ],
	'coderef aggfunc');

#--------
# fractional mean value (float compare)
#--------
{
	my $d = [ { g => 'x', k => 'A', v => 10 },
	          { g => 'x', k => 'A', v => 20 },
	          { g => 'x', k => 'A', v => 25 } ];
	my $got = pivot_table($d, index => 'g', columns => 'k', values => 'v');
	is_approx($got->[0]{A}, 18.3333333333333, 'fractional mean cell');
}

#--------
# multiple aggfuncs -> aggfunc-major, func-prefixed names
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
		aggfunc => [ 'count', 'sum' ]),
	[ { city => 'LA', 'count.2020' => 1, 'count.2021' => 1, 'sum.2020' => 40, 'sum.2021' => 50 },
	  { city => 'NY', 'count.2020' => 2, 'count.2021' => 1, 'sum.2020' => 30, 'sum.2021' => 30 } ],
	'multi aggfunc: func-prefixed names');

#--------
# multiple value columns -> value-prefixed names
#--------
{
	my $d = [ { g => 'x', k => 'A', a => 1, b => 100 },
	          { g => 'x', k => 'B', a => 2, b => 200 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => 'k', values => [ 'a', 'b' ], aggfunc => 'sum'),
		[ { g => 'x', 'a.A' => 1, 'a.B' => 2, 'b.A' => 100, 'b.B' => 200 } ],
		'multi value: value-prefixed names');
}

#--------
# multi-column 'columns' tuple, missing combo cell stays NA
#--------
{
	my $d = [ { g => 'x', a => 1, b => 2, v => 10 },
	          { g => 'x', a => 1, b => 3, v => 20 },
	          { g => 'y', a => 1, b => 2, v => 30 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => [ 'a', 'b' ], values => 'v', aggfunc => 'sum'),
		[ { g => 'x', '1.2' => 10, '1.3' => 20 },
		  { g => 'y', '1.2' => 30, '1.3' => undef } ],
		'multi-column tuple, missing combo -> undef');
}

#--------
# default values = non-index, non-columns
#--------
is_deeply(
	pivot_table($wide, index => 'city', columns => 'year', aggfunc => 'sum'),
	[ { city => 'LA', 2020 => 40, 2021 => 50 },
	  { city => 'NY', 2020 => 30, 2021 => 30 } ],
	'default values = remaining columns');

#--------
# fill_value substitutes NA result cells
#--------
{
	my $d = [ { g => 'x', a => 1, b => 2, v => 10 },
	          { g => 'x', a => 1, b => 3, v => 20 },
	          { g => 'y', a => 1, b => 2, v => 30 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => [ 'a', 'b' ], values => 'v',
			aggfunc => 'sum', fill_value => 0),
		[ { g => 'x', '1.2' => 10, '1.3' => 20 },
		  { g => 'y', '1.2' => 30, '1.3' => 0 } ],
		'fill_value fills empty buckets');
}

#--------
# skipna: default 1 drops NA; 0 poisons the bucket
#--------
{
	my $d = [ { g => 'x', k => 'A', v => 10 },
	          { g => 'x', k => 'A', v => undef },
	          { g => 'x', k => 'A', v => 20 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => 'k', values => 'v'),
		[ { g => 'x', A => 15 } ],
		'skipna=1 (default): NA ignored in mean');
	is_deeply(
		pivot_table($d, index => 'g', columns => 'k', values => 'v', skipna => 0, fill_value => -1),
		[ { g => 'x', A => -1 } ],
		'skipna=0: NA in bucket -> NA result -> fill_value');
}

#--------
# sort => 0 keeps first-seen column order
#--------
{
	my $d = [ { k => 'B', v => 1 }, { k => 'A', v => 2 } ];
	is_deeply(
		pivot_table($d, columns => 'k', values => 'v', aggfunc => 'sum', sort => 0, 'output.type' => 'aoa'),
		[ [ 1, 2 ] ], 'sort=0: first-seen column order B,A');
	is_deeply(
		pivot_table($d, columns => 'k', values => 'v', aggfunc => 'sum', 'output.type' => 'aoa'),
		[ [ 2, 1 ] ], 'sort=1 (default): sorted column order A,B');
}

#--------
# no index -> single 'all' row
#--------
is_deeply(
	pivot_table($wide, columns => 'year', values => 'temp', aggfunc => 'sum', 'output.type' => 'hoh'),
	{ all => { 2020 => 70, 2021 => 80 } },
	'no index -> single all row');

#--------
# rows whose columns-tuple contains NA are skipped
#--------
{
	my $d = [ { g => 'x', k => 'A', v => 5 },
	          { g => 'x', k => undef, v => 99 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => 'k', values => 'v', aggfunc => 'sum'),
		[ { g => 'x', A => 5 } ],
		'NA in columns-tuple -> row skipped');
}

#--------
# custom sep
#--------
{
	my $d = [ { g => 'x', k => 'A', v => 10 },
	          { g => 'x', k => 'A', v => undef },
	          { g => 'x', k => 'A', v => 20 } ];
	is_deeply(
		pivot_table($d, index => 'g', columns => 'k', values => 'v', aggfunc => [ 'count', 'sum' ], sep => '_'),
		[ { g => 'x', 'count_A' => 2, 'sum_A' => 30 } ],
		'custom sep applied to generated names');
}

#--------
# output.type overrides
#--------
{
	# hoh: label from index join
	is_deeply(
		pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
			aggfunc => 'sum', 'output.type' => 'hoh'),
		{ NY => { city => 'NY', 2020 => 30, 2021 => 30 },
		  LA => { city => 'LA', 2020 => 40, 2021 => 50 } },
		'output.type hoh: index-value labels');
	# hoa
	is_deeply(
		pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
			aggfunc => 'sum', 'output.type' => 'hoa'),
		{ city => [ 'LA', 'NY' ], 2020 => [ 40, 30 ], 2021 => [ 50, 30 ] },
		'output.type hoa');
	# aoa
	is_deeply(
		pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
			aggfunc => 'sum', 'output.type' => 'aoa'),
		[ [ 'LA', 40, 50 ], [ 'NY', 30, 30 ] ],
		'output.type aoa: [index, cols...]');
}

#--------
# hoh label uniquification when index join collides
#--------
{
	# two index columns whose '.' join collides: ('1','2.3') vs ('1.2','3')
	my $d = [ { a => '1',   b => '2.3', k => 'X', v => 1 },
	          { a => '1.2', b => '3',   k => 'X', v => 2 } ];
	my $got = pivot_table($d, index => [ 'a', 'b' ], columns => 'k', values => 'v',
		aggfunc => 'sum', 'output.type' => 'hoh');
	is(scalar keys %$got, 2, 'hoh: colliding labels both kept (uniquified)');
	ok(exists $got->{'1.2.3'} && exists $got->{'1.2.3.1'},
		'hoh: second colliding label suffixed');
}

#--------
# error paths
#--------
dies_ok { pivot_table(undef) } 'undef data dies';
throws_ok { pivot_table([ { a => 1 } ], 'oddarg') }
	qr/name => value pairs/, 'odd trailing args die';
throws_ok { pivot_table([ { a => 1 } ], bogus => 1) }
	qr/unknown argument/, 'unknown argument dies';
throws_ok { pivot_table([ { a => 1 } ]) }
	qr/'columns' is required/, 'missing columns dies';
throws_ok { pivot_table([ { a => 1 } ], columns => 'Z') }
	qr/column 'Z' not found/, 'unknown column dies';
throws_ok { pivot_table([ { k => 1, v => 2 } ], columns => 'k', values => 'v', aggfunc => 'nope') }
	qr/unknown aggfunc/, 'unknown aggfunc dies';
throws_ok { pivot_table([ { k => 1, v => 2 } ], columns => 'k', values => 'v', aggfunc => []) }
	qr/empty aggfunc list/, 'empty aggfunc list dies';
throws_ok { pivot_table([ { k => 1, v => 2 } ], columns => 'k', values => 'v', 'output.type' => 'xxx') }
	qr/output\.type/, 'bad output.type dies';
throws_ok {
	pivot_table([ { a => 1, b => 23, v => 1 }, { a => 12, b => 3, v => 1 } ],
		index => undef, columns => [ 'a', 'b' ], values => 'v', aggfunc => 'sum', sep => '')
} qr/duplicate column name/, 'generated duplicate names die';

#--------
# memory
#--------
no_leaks_ok {
	my $x = pivot_table($wide, index => 'city', columns => 'year', values => 'temp', aggfunc => 'sum');
} 'pivot_table: no memory leaks (numeric reducer)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $x = pivot_table($wide, index => 'city', columns => 'year', values => 'temp',
		aggfunc => sub { scalar @{ $_[0] } });
} 'pivot_table: no memory leaks (coderef)' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { pivot_table([ { a => 1 } ], columns => 'Z') };
} 'pivot_table: no memory leaks (die path)' unless $INC{'Devel/Cover.pm'};

done_testing;
