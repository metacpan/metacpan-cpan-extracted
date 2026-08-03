#!/usr/bin/env perl
# h2aoh / aoh2h -- the flat hash as a two-column frame, and back.
#
# The contract under test:
#   * h2aoh unfolds a plain hash into one row per pair, under column names the
#     caller chooses (var_name / value_name, as in melt);
#   * row order is deterministic by default, and the three sort modes each do
#     what they say;
#   * aoh2h folds a two-column AoH back down, with a say in what happens to a
#     repeated key;
#   * the two are exact inverses under their defaults;
#   * both reject malformed input loudly, naming the offending key or row.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Scalar::Util qw(looks_like_number reftype);
use Stats::LikeR;
use Test::Exception;    # dies_ok, throws_ok, lives_ok
use Test::More;

# ---------------------------------------------------------------------------
# h2aoh: the basic unfold
# ---------------------------------------------------------------------------
{
	my $aoh = h2aoh({ a => 1, b => 2 });
	is(reftype($aoh), 'ARRAY', 'h2aoh: returns an arrayref');
	is_deeply($aoh,
		[ { variable => 'a', value => 1 }, { variable => 'b', value => 2 } ],
		'h2aoh: one row per pair, under the default column names');
	is(scalar @$aoh, 2, 'h2aoh: row count is the number of pairs');
	is_deeply([ sort keys %{ $aoh->[0] } ], [ 'value', 'variable' ],
		'h2aoh: each row carries exactly the two columns');
}

# custom column names
{
	my $aoh = h2aoh({ TP53 => 12 }, var_name => 'gene', value_name => 'n');
	is_deeply($aoh, [ { gene => 'TP53', n => 12 } ],
		'h2aoh: var_name and value_name rename both columns');
}

# the result is a frame the rest of the distribution will take
{
	my $aoh = h2aoh({ a => 1, b => 2 }, var_name => 'k', value_name => 'v');
	is(nrow($aoh), 2, 'h2aoh: nrow() reads the result as a frame');
	is_deeply([ sort @{ [ colnames($aoh) ] } ], [ 'k', 'v' ],
		'h2aoh: colnames() sees the two named columns');
	is_deeply(vals($aoh, 'v'), [ 1, 2 ], 'h2aoh: vals() reads the value column');
}

# ---------------------------------------------------------------------------
# h2aoh: row order
# ---------------------------------------------------------------------------
{
	# numeric keys sort numerically, not as strings ('10' lt '2')
	my $aoh = h2aoh({ 10 => 'x', 2 => 'y', 1 => 'z' });
	is_deeply([ map { $_->{variable} } @$aoh ], [ 1, 2, 10 ],
		'h2aoh: all-numeric keys sort numerically');

	# one non-numeric key drops the whole sort back to string order
	my $mixed = h2aoh({ 10 => 'x', 2 => 'y', a => 'z' });
	is_deeply([ map { $_->{variable} } @$mixed ], [ '10', '2', 'a' ],
		'h2aoh: a non-numeric key makes the key sort alphabetical');

	is_deeply([ map { $_->{variable} } @{ h2aoh({ b => 1, a => 2, c => 3 }) } ],
		[ 'a', 'b', 'c' ], 'h2aoh: string keys sort alphabetically');
}

# sort => 'value'
{
	my $counts = { one => 216, two => 184, three => 491 };
	my $aoh = h2aoh($counts, sort => 'value');
	is_deeply([ map { $_->{variable} } @$aoh ], [ 'three', 'one', 'two' ],
		"h2aoh: sort => 'value' puts the biggest count first");

	# non-numeric values have no biggest-first convention, so they go up
	my $words = h2aoh({ a => 'zebra', b => 'apple' }, sort => 'value');
	is_deeply([ map { $_->{variable} } @$words ], [ 'b', 'a' ],
		"h2aoh: sort => 'value' orders non-numeric values alphabetically");

	# undef last, ties broken on the key
	my $gaps = h2aoh({ a => undef, b => 1, c => 1 }, sort => 'value');
	is_deeply([ map { $_->{variable} } @$gaps ], [ 'b', 'c', 'a' ],
		"h2aoh: sort => 'value' sorts undef last and breaks ties on the key");
}

# sort => 'none' keeps every pair, whatever order it lands in
{
	my %h = map { $_ => 1 } 'a' .. 'j';
	my $aoh = h2aoh(\%h, sort => 'none');
	is(scalar @$aoh, 10, "h2aoh: sort => 'none' keeps every pair");
	is_deeply([ sort map { $_->{variable} } @$aoh ], [ 'a' .. 'j' ],
		"h2aoh: sort => 'none' loses no keys");
}

# ---------------------------------------------------------------------------
# h2aoh: values and edges
# ---------------------------------------------------------------------------
{
	is_deeply(h2aoh({}), [], 'h2aoh: empty hash gives an empty frame');
	is_deeply(h2aoh({}, sort => 'value'), [],
		"h2aoh: empty hash is fine under sort => 'value' too");

	is_deeply(h2aoh({ x => undef }), [ { variable => 'x', value => undef } ],
		'h2aoh: an undef value is carried through as undef');

	my $frac = h2aoh({ mpg => 22.8 });
	ok(looks_like_number($frac->[0]{value}), 'h2aoh: a numeric value stays numeric');
	cmp_ok($frac->[0]{value}, '==', 22.8, 'h2aoh: a fractional value is unharmed');

	# the empty string is a perfectly good key
	is_deeply(h2aoh({ '' => 5 }), [ { variable => '', value => 5 } ],
		'h2aoh: the empty-string key survives');
}

# the result is independent of the input
{
	my %h = ( a => 1 );
	my $aoh = h2aoh(\%h);
	$aoh->[0]{value} = 99;
	is($h{a}, 1, 'h2aoh: editing the frame does not touch the hash');
}

# ---------------------------------------------------------------------------
# h2aoh: errors
# ---------------------------------------------------------------------------
{
	throws_ok { h2aoh(undef) } qr/first argument is undefined/,
		'h2aoh: undef argument dies';
	throws_ok { h2aoh([ 1, 2 ]) } qr/must be a hashref/,
		'h2aoh: arrayref argument dies';
	throws_ok { h2aoh('scalar') } qr/must be a hashref/,
		'h2aoh: scalar argument dies';
	throws_ok { h2aoh({ a => 1 }, 'var_name') } qr/name => value pairs/,
		'h2aoh: an odd trailing argument list dies';
	throws_ok { h2aoh({ a => 1 }, colour => 'red') } qr/unknown argument\(s\): colour/,
		'h2aoh: an unknown option dies, naming it';
	throws_ok { h2aoh({ a => 1 }, var_name => 'x', value_name => 'x') }
		qr/var_name and value_name must differ/,
		'h2aoh: two columns of the same name die';
	throws_ok { h2aoh({ a => 1 }, sort => 'sideways') }
		qr/sort 'sideways' isn't allowed/,
		'h2aoh: an unknown sort mode dies, listing the allowed ones';

	# a nested value is the commonest mistake: say which converter was meant
	throws_ok { h2aoh({ a => [ 1, 2 ] }) }
		qr/value for key 'a' is an? ARRAY reference/,
		'h2aoh: an arrayref value dies, naming the key';
	throws_ok { h2aoh({ a => [ 1, 2 ] }) } qr/hoa2aoh/,
		'h2aoh: the arrayref message points at hoa2aoh';
	throws_ok { h2aoh({ a => { b => 1 } }) } qr/hoh2hoa/,
		'h2aoh: a hashref value points at hoh2hoa';

	lives_ok { h2aoh({ a => 1, b => 2 }) } 'h2aoh: a well-formed flat hash lives';
}

# ---------------------------------------------------------------------------
# aoh2h: the basic fold
# ---------------------------------------------------------------------------
{
	my $h = aoh2h([ { variable => 'a', value => 1 },
	                { variable => 'b', value => 2 } ]);
	is(reftype($h), 'HASH', 'aoh2h: returns a hashref');
	is_deeply($h, { a => 1, b => 2 }, 'aoh2h: default columns fold down');
}

# custom column names, and columns that are along for the ride
{
	my $aoh = [ { gene => 'TP53',  n => 12, chr => 17 },
	            { gene => 'BRCA1', n =>  7, chr => 17 } ];
	is_deeply(aoh2h($aoh, var_name => 'gene', value_name => 'n'),
		{ TP53 => 12, BRCA1 => 7 },
		'aoh2h: names the two columns and ignores the rest');
}

{
	is_deeply(aoh2h([]), {}, 'aoh2h: an empty frame gives an empty hash');
	is_deeply(aoh2h([ { variable => 'x', value => undef } ]), { x => undef },
		'aoh2h: an undef value folds down as undef');
}

# duplicates
{
	my $dupes = [ { variable => 'a', value => 1 },
	              { variable => 'a', value => 9 },
	              { variable => 'b', value => 5 } ];
	throws_ok { aoh2h($dupes) } qr/duplicate key 'a'/,
		'aoh2h: a repeated key is fatal by default';
	is_deeply(aoh2h($dupes, duplicates => 'first'), { a => 1, b => 5 },
		"aoh2h: duplicates => 'first' keeps the earliest row");
	is_deeply(aoh2h($dupes, duplicates => 'last'), { a => 9, b => 5 },
		"aoh2h: duplicates => 'last' keeps the latest row");
	throws_ok { aoh2h($dupes, duplicates => 'maybe') }
		qr/duplicates 'maybe' isn't allowed/,
		'aoh2h: an unknown duplicates mode dies, listing the allowed ones';
}

# ---------------------------------------------------------------------------
# aoh2h: errors
# ---------------------------------------------------------------------------
{
	throws_ok { aoh2h(undef) } qr/first argument is undefined/,
		'aoh2h: undef argument dies';
	throws_ok { aoh2h({ a => 1 }) } qr/must be an arrayref of hashrefs/,
		'aoh2h: hashref argument dies';
	throws_ok { aoh2h([ { variable => 'a', value => 1 } ], 'var_name') }
		qr/name => value pairs/, 'aoh2h: an odd trailing argument list dies';
	throws_ok { aoh2h([], colour => 'red') } qr/unknown argument\(s\): colour/,
		'aoh2h: an unknown option dies, naming it';
	throws_ok { aoh2h([], var_name => 'x', value_name => 'x') }
		qr/var_name and value_name must differ/,
		'aoh2h: two columns of the same name die';

	throws_ok { aoh2h([ 'not a row' ]) } qr/index 0 is not a hashref/,
		'aoh2h: a non-hashref row dies, naming the index';
	throws_ok { aoh2h([ { variable => 'a', value => 1 }, { value => 2 } ]) }
		qr/index 1 has no 'variable' column/,
		'aoh2h: a row missing the key column dies, naming the index';
	throws_ok { aoh2h([ { variable => 'a' } ]) }
		qr/index 0 has no 'value' column/,
		'aoh2h: a row missing the value column dies, naming the index';
	throws_ok { aoh2h([ { variable => undef, value => 1 } ]) }
		qr/index 0 has an undefined 'variable'/,
		'aoh2h: an undef key cell dies, naming the index';

	# a typo in a column name reads as a missing column, which is the point
	throws_ok { aoh2h([ { gene => 'TP53', n => 1 } ], var_name => 'genes',
	                  value_name => 'n') }
		qr/index 0 has no 'genes' column/,
		'aoh2h: a mistyped column name is caught rather than silently empty';

	lives_ok { aoh2h([ { variable => 'a', value => 1 } ]) }
		'aoh2h: a well-formed two-column frame lives';
}

# ---------------------------------------------------------------------------
# the two are inverses
# ---------------------------------------------------------------------------
{
	my %h = ( a => 1, b => 2, c => undef, '' => 0 );
	is_deeply(aoh2h(h2aoh(\%h)), \%h, 'aoh2h(h2aoh(%h)) is %h');
	ok(is_equivalent([ sort keys %{ aoh2h(h2aoh(\%h)) } ], [ sort keys %h ]),
		'the round trip returns exactly the original key set');

	# and under renamed columns, so long as both ends agree
	my %named = ( TP53 => 12, BRCA1 => 7 );
	is_deeply(
		aoh2h(h2aoh(\%named, var_name => 'gene', value_name => 'n'),
		      var_name => 'gene', value_name => 'n'),
		\%named, 'the round trip survives renamed columns');

	# the sort mode is presentation only: it cannot change what comes back
	for my $how (qw(key value none)) {
		is_deeply(aoh2h(h2aoh(\%h, sort => $how)), \%h,
			"the round trip is unaffected by sort => '$how'");
	}

	# the other direction, starting from a frame
	my $aoh = [ { variable => 'a', value => 1 }, { variable => 'b', value => 2 } ];
	is_deeply(h2aoh(aoh2h($aoh)), $aoh, 'h2aoh(aoh2h($aoh)) is $aoh');
}

# value_counts feeds straight in -- the reason the pair exists
{
	my $rows = [ map { { grp => $_ } } qw(a b a c a b) ];
	my $tbl  = h2aoh(value_counts($rows, 'grp'),
	                 var_name => 'grp', value_name => 'n', sort => 'value');
	is_deeply($tbl,
		[ { grp => 'a', n => 3 }, { grp => 'b', n => 2 }, { grp => 'c', n => 1 } ],
		'h2aoh turns value_counts output into a sorted frame');
	is_deeply(aoh2h($tbl, var_name => 'grp', value_name => 'n'),
		{ a => 3, b => 2, c => 1 }, 'and aoh2h folds it back');
}

# ---------------------------------------------------------------------------
# both are exported
# ---------------------------------------------------------------------------
{
	ok(defined &main::h2aoh, 'h2aoh is exported into the caller');
	ok(defined &main::aoh2h, 'aoh2h is exported into the caller');
	for my $f (qw(h2aoh aoh2h)) {
		ok(scalar(grep { $_ eq $f } @Stats::LikeR::EXPORT_OK),
			"$f is in \@EXPORT_OK");
	}
}

done_testing();
