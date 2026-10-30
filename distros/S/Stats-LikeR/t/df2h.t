#!/usr/bin/env perl
#
# df2h(): two columns of any data frame -- AoH, AoA, HoA or HoH -- folded down
# into a plain hash.
#
# 0.33 generalised aoh2h(), which took an AoH alone, into df2h(), and made aoh2h
# a second name for the same sub. t/aoh2h.regressions.t and t/h2aoh_aoh2h.t
# still hold the AoH path to everything it did in 0.3218; this file covers what
# 0.33 added: the other three shapes, the reading of a frame's shape, and the
# options that mean something different for one of them.
#
# Reference cases, with where each came from:
#
#  - tibble 3.3.1, tests/testthat/test-enframe.R, from the CRAN source tarball
#    (~/Scripts/r-pkg-sources/tibble_3.3.1.tar.gz): "can deframe two-column
#    data frame", "can deframe tibble with list column", "can deframe
#    three-column data frame with warning", and the enframe() cases that, read
#    back through deframe(), are the round trip below. deframe() takes the
#    names from the first column and the values from the second, which is
#    df2h()'s default for an AoA; the other shapes name the same two columns.
#  - pandas 3.0.4, tests/frame/methods/test_to_dict.py:
#    test_to_dict_index_not_unique_with_index_orient (GH#22801, a repeated key
#    raises), test_to_dict_na_to_none (GH#50795, a missing value is kept as
#    None), test_to_dict_numeric_names (GH#24940, numeric names become string
#    keys), test_to_dict_wide (GH#24939, 256 columns); and
#    tests/series/methods/test_to_dict.py: test_to_dict_return_types (GH25969,
#    an integer value comes back an integer).
#  - pandas 3.0.4, run by hand rather than taken from a test: Series.to_dict()
#    and df.set_index('k')['v'].to_dict() on a repeated key keep the last value,
#    pd.Series([1, 2], index=['A', 'A']).to_dict() giving {'A': 2} and the
#    frame {'k': ['A', 'A', 'B'], 'v': [1, 2, 3]} giving {'A': 2, 'B': 3}. That
#    is duplicates => 'last'.
#
# Where df2h() departs from them, on purpose:
#
#  - deframe() on a one-column frame returns the bare column. df2h() needs two
#    columns, and an AoA row of one cell dies as missing column 1.
#  - deframe() warns on a third column and ignores it; df2h() ignores it
#    silently, as aoh2h() always has.
#  - A named vector, and pandas' Series.to_dict(), allow a repeated key;
#    df2h() dies on one by default, as to_dict(orient='index') does, and keeps
#    the first or the last only when asked.
#
# Every other case is invented here, to reach a path in df2h() or df2h_fold().

require 5.010;
use strict;
use warnings FATAL => 'all';
use B ();
use Scalar::Util qw(refaddr);
use Stats::LikeR;
use Test::More;
use Tie::Array ();	# Tie::StdArray
use Tie::Hash ();	# Tie::StdHash

# Imported at compile time for no_leaks_ok's (&;$) prototype, as
# t/tied.frames.t does. Without the module only the leak checks are skipped.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

sub err (&) { my $code = shift; eval { $code->(); 1 } ? '' : "$@" }

# The same three-row table in each of the four shapes, as deframe()'s test
# builds it: tibble(name = letters[1:3], value = 3:1).
my %abc = (a => 3, b => 2, c => 1);
my %as = (
	AoH => [ { name => 'a', value => 3 }, { name => 'b', value => 2 }, { name => 'c', value => 1 } ],
	AoA => [ [ 'a', 3 ], [ 'b', 2 ], [ 'c', 1 ] ],
	HoA => { name => [ 'a', 'b', 'c' ], value => [ 3, 2, 1 ] },
	HoH => { r1 => { name => 'a', value => 3 }, r2 => { name => 'b', value => 2 },
	         r3 => { name => 'c', value => 1 } },
);
my %opt = (AoA => []);	# an AoA's defaults are tibble's positions; the rest are named
$opt{$_} = [ var_name => 'name' ] for qw(AoH HoA HoH);

#----------------------------------------------------------------------------
# tibble: "can deframe two-column data frame", in every shape
for my $shape (qw(AoH AoA HoA HoH)) {
	is_deeply(df2h($as{$shape}, @{ $opt{$shape} }), \%abc, "deframe two columns: $shape");
}
ok(\&aoh2h == \&df2h, 'aoh2h is df2h, the same sub');
is_deeply(aoh2h($as{HoA}, var_name => 'name'), \%abc, 'so aoh2h takes a HoA too');

# tibble: "can deframe three-column data frame with warning" -- the third
# column is ignored (silently here)
is_deeply(df2h([ [ 'a', 3, 1 ], [ 'b', 2, 2 ], [ 'c', 1, 3 ] ]), \%abc, 'AoA: a third column is ignored');
is_deeply(df2h({ name => [qw(a b c)], value => [ 3, 2, 1 ], oops => [ 1, 2, 3 ] }, var_name => 'name'),
	\%abc, 'HoA: a third column is ignored');

# tibble: "can deframe tibble with list column" -- a value that is a
# reference is kept, and shared with the input
{
	my @cells = ([3], [2], [1]);
	my $h = df2h([ map { [ $_, shift @cells ] } qw(a b c) ]);
	is_deeply($h, { a => [3], b => [2], c => [1] }, 'AoA: reference values');
	my $col = [ [3], [2], [1] ];
	my $g = df2h({ variable => [qw(a b c)], value => $col });
	is(refaddr($g->{b}), refaddr($col->[1]), 'HoA: a reference value is shared, not cloned');
}

# tibble: "can deframe one-column data frame" returns the column; df2h dies
is(err { df2h([ [3], [2], [1] ]) }, "df2h: index 0 has no column 1\n",
	'AoA: a one-column frame has no value column');

#----------------------------------------------------------------------------
# pandas: repeated keys (GH#22801 raises; Series.to_dict keeps the last)
{
	my %dup = (
		AoH => [ { k => 'A', v => 1 }, { k => 'A', v => 2 }, { k => 'B', v => 3 } ],
		AoA => [ [ 'A', 1 ], [ 'A', 2 ], [ 'B', 3 ] ],
		HoA => { k => [qw(A A B)], v => [ 1, 2, 3 ] },
	);
	for my $shape (qw(AoH AoA HoA)) {
		my @o = $shape eq 'AoA' ? () : (var_name => 'k', value_name => 'v');
		is(err { df2h($dup{$shape}, @o) },
			"df2h: duplicate key 'A' has >= 2 occurrences, the first repeat at index 1\n",
			"$shape: a repeated key dies, naming the first repeat");
		is_deeply(df2h($dup{$shape}, @o, duplicates => 'last'), { A => 2, B => 3 },
			"$shape: 'last' is pandas' to_dict()");
		is_deeply(df2h($dup{$shape}, @o, duplicates => 'first'), { A => 1, B => 3 },
			"$shape: 'first' keeps the earliest");
	}
}

# pandas GH#50795: a missing value is kept, as undef
for my $shape (qw(AoA HoA)) {
	my $df = $shape eq 'AoA' ? [ [ 'x', 1 ], [ 'y', undef ] ] : { variable => [qw(x y)], value => [ 1, undef ] };
	my $h = df2h($df);
	ok(exists $h->{y} && !defined $h->{y}, "$shape: an undef value is kept as undef");
	is($h->{x}, 1, "$shape: beside a defined one");
}

# pandas GH25969: an integer value comes back an integer, and a string a string
{
	my $h = df2h({ variable => [qw(a b c)], value => [ 64, 10, 'ABC' ] });
	is_deeply($h, { a => 64, b => 10, c => 'ABC' }, 'HoA: mixed values');
	my $f = B::svref_2object(\$h->{a})->FLAGS;
	ok(($f & B::SVf_IOK) && !($f & B::SVf_POK), 'an integer value stays an integer, with no string');
	$f = B::svref_2object(\$h->{c})->FLAGS;
	ok(($f & B::SVf_POK) && !($f & (B::SVf_IOK | B::SVf_NOK)), 'a string value stays a string');
}

# pandas GH#24940: numeric names become string keys
{
	my $h = df2h([ map { [ $_, $_ ] } 0 .. 4 ]);
	is_deeply([ sort keys %$h ], [qw(0 1 2 3 4)], 'numeric key cells give the keys "0" to "4"');
	is_deeply($h, { map { ("$_" => $_) } 0 .. 4 }, 'each with its value');
}

# pandas GH#24939: wide -- 256 columns, read from either end of a row
{
	my @row = map { ("A_$_", $_) } 0 .. 255;	# 512 cells: name, value, name, value, ...
	is_deeply(df2h([ \@row ], var_name => 510, value_name => 511), { A_255 => 255 },
		'AoA: positions 510 and 511 of a 512-cell row');
	is_deeply(df2h([ \@row ], var_name => -2, value_name => -1), { A_255 => 255 },
		'AoA: the same cells counted from the end');
	my %wide = map { ("A_$_" => $_) } 0 .. 255;
	is_deeply(df2h({ variable => [ map { "A_$_" } 0 .. 255 ], value => [ 0 .. 255 ] }), \%wide,
		'HoA: 256 rows');
}

#----------------------------------------------------------------------------
# tibble's enframe() / deframe() round trip, through every shape: h2aoh()
# unfolds the hash, the converters reshape the frame, and df2h() folds it back
{
	my %h = (a => 2, b => 1, 10 => 'x', 2.5 => undef);
	my $aoh = h2aoh(\%h);
	is_deeply(df2h($aoh), \%h, 'round trip: AoH');
	is_deeply(df2h(aoh2hoa($aoh)), \%h, 'round trip: HoA');
	is_deeply(df2h(aoh2hoh($aoh, 'variable')), \%h, 'round trip: HoH');
	is_deeply(df2h([ map { [ $_->{variable}, $_->{value} ] } @$aoh ]), \%h, 'round trip: AoA');
	is_deeply(df2h(h2aoh(\%h, var_name => 'name', value_name => 'v'), var_name => 'name', value_name => 'v'),
		\%h, "round trip: tibble's custom names");
}

#----------------------------------------------------------------------------
# Reading the shape
{
	# the help screen df2h() prints, argparse-style, above a call-form error
	my $usage = do {
		my $err = err { df2h() };
		like($err, qr/\Ausage: df2h\(DF .*^options:\n.*^example:\n.*\n\ndf2h: error: /ms,
			'a call-form error is usage, options and example, then the error last');
		$err =~ s/df2h: error: .*\z//s;
		$err;
	};
	is_deeply(df2h([]), {}, 'an empty array is an empty frame');
	is_deeply(df2h({}), {}, 'so is an empty hash');
	is(err { df2h([ undef, [ 'a', 1 ] ]) }, "df2h: index 0 is not an arrayref\n",
		'an AoA is read from its first defined row, and a hole before it is still a bad row');
	is(err { df2h([ undef, { variable => 'a', value => 1 } ]) }, "df2h: index 0 is not a hashref\n",
		'so is an AoH');
	is(err { df2h([ 'x' ]) }, "df2h: index 0 is not a hashref\n", 'a row that is no reference is a bad AoH row');
	is(err { df2h([ [ 'a', 1 ], { variable => 'b', value => 2 } ]) }, "df2h: index 1 is not an arrayref\n",
		'a hash among arrays is a bad AoA row');
	is(err { df2h([ { variable => 'b', value => 2 }, [ 'a', 1 ] ]) }, "df2h: index 1 is not a hashref\n",
		'an array among hashes is a bad AoH row');
	is(err { df2h({ a => [1], b => {} }) }, "df2h: hashref mixes array and hash values (ambiguous HoA/HoH)\n",
		'a hash of both arrays and hashes dies');
	is(err { df2h({ a => 1 }) },
		"df2h: first argument is a flat hash, not a data frame: none of its values is an array or hash ref\n",
		'a flat hash dies');
	is(err { df2h('x') }, "${usage}df2h: error: first argument must be a data frame (AoA, AoH, HoA or HoH)\n", 'a string dies');
	is(err { df2h(\'x') }, "${usage}df2h: error: first argument must be a data frame (AoA, AoH, HoA or HoH)\n",
		'a scalar ref dies');
	is(err { df2h(undef) }, "${usage}df2h: error: first argument is undefined\n", 'undef dies');

	# blessed frames, rows and columns are what they are underneath
	is_deeply(df2h(bless([ bless([ 'a', 1 ], 'Row') ], 'Frame')), { a => 1 }, 'a blessed AoA of blessed rows');
	is_deeply(df2h(bless({ variable => bless([ 'a' ], 'Col'), value => [1] }, 'Frame')), { a => 1 },
		'a blessed HoA with a blessed column');
	is_deeply(df2h(bless({ r => bless({ variable => 'a', value => 1 }, 'Row') }, 'Frame')), { a => 1 },
		'a blessed HoH of blessed rows');
}

#----------------------------------------------------------------------------
# AoA: positions
{
	my $aoa = [ [ 'a', 1, 'x' ], [ 'b', 2, 'y' ] ];
	is_deeply(df2h($aoa, var_name => 2, value_name => 0), { x => 'a', y => 'b' }, 'any two positions');
	is_deeply(df2h($aoa, var_name => -1, value_name => -3), { x => 'a', y => 'b' }, 'negative positions');
	is_deeply(df2h($aoa, var_name => '02', value_name => '-0'), { x => 'a', y => 'b' },
		"'02' is 2 and '-0' is 0");
	is_deeply(df2h([ [ 'a', 1 ], [ 'q', 'r', 'b', 2 ] ], var_name => -2, value_name => -1), { a => 1, b => 2 },
		'a negative position is counted from the end of each row, however long');

	for my $bad ('x', '1.5', '1e3', ' 1', '1 ', '+1', '', '0x1') {
		is(err { df2h($aoa, var_name => $bad) }, "df2h: an AoA's columns are integer positions, not '$bad'\n",
			"var_name '$bad' is not a position");
	}
	is(err { df2h($aoa, value_name => 'value') }, "df2h: an AoA's columns are integer positions, not 'value'\n",
		'nor is a name, in value_name');
	is(err { df2h($aoa, var_name => '9' x 30) }, 'df2h: column position ' . ('9' x 30) . " is past the end of any array\n",
		'a position no IV can hold');
	is(err { df2h($aoa, var_name => 1) }, "df2h: var_name and value_name must differ\n",
		'var_name 1 against the default value_name 1');
	is(err { df2h($aoa, var_name => '-0', value_name => '00') }, "df2h: var_name and value_name must differ\n",
		"'-0' and '00' are one position");

	is(err { df2h([ [ 'a', 1 ], [ 'b' ] ]) }, "df2h: index 1 has no column 1\n", 'a short row lacks the value');
	is(err { df2h([ [ 'a', 1 ], [] ]) }, "df2h: index 1 has no column 0\n", 'an empty row lacks the key first');
	is(err { df2h([ [ 'a', 1 ] ], var_name => -3) }, "df2h: index 0 has no column -3\n",
		'a negative position before the start of the row');
	is(err { df2h([ [ 'a', 1, 2 ], [ 'b' ] ], var_name => 0, value_name => -1) },
		"df2h: index 1 has column 0 and column -1 at the same place, so they are one column\n",
		'two positions that meet in a one-cell row');

	my @holey; $holey[2] = 'v';	# cells 0 and 1 never assigned
	is(err { df2h([ \@holey ]) }, "df2h: index 0 has an undefined column 0; a hash key has to be defined\n",
		'a hole as the key is an undef key');
	my @hv = ('k'); $hv[2] = 'z';	# cell 1 a hole
	my $h = df2h([ \@hv ]);
	ok(exists $h->{k} && !defined $h->{k}, 'a hole as the value is an undef value');
	is(err { df2h([ [ [1], 1 ] ]) },
		"df2h: index 0 has a reference in column 0 (ARRAY); a hash key would be its address, not its contents\n",
		'a reference key names the position');
}

#----------------------------------------------------------------------------
# HoA: two columns of one length
{
	is(err { df2h({ variable => ['a'] }) }, "df2h: no 'value' column\n", 'a missing value column');
	is(err { df2h({ value => [1] }) }, "df2h: no 'variable' column\n", 'a missing key column');
	is(err { df2h({ gene => [1], value => [1] }, var_name => 'genes') }, "df2h: no 'genes' column\n",
		'a mistyped name');
	is(err { df2h({ variable => 'a', value => [1] }) }, "df2h: column 'variable' is not an arrayref\n",
		'a column that is not an array');
	is(err { df2h({ variable => ['a'], value => undef, x => [] }) }, "df2h: column 'value' is not an arrayref\n",
		'an undef column');
	is(err { df2h({ variable => ['a'], value => [ 1, 2 ] }) },
		"df2h: column 'variable' has length 1 and 'value' has length 2; the two must be the same length\n",
		'columns of two lengths');
	is_deeply(df2h({ variable => [], value => [] }), {}, 'two empty columns');
	is(err { df2h({ variable => [ 'a', undef ], value => [ 1, 2 ] }) },
		"df2h: index 1 has an undefined 'variable'; a hash key has to be defined\n", 'an undef key');
	my @kc = ('a', 'b'); my @vc; $vc[1] = 2; $#vc = 1;	# value cell 0 a hole
	my $h = df2h({ variable => \@kc, value => \@vc });
	ok(exists $h->{a} && !defined $h->{a} && $h->{b} == 2, 'a hole in the value column is an undef value');
	is(err { df2h({ variable => [ { } ], value => [1] }) },
		"df2h: index 0 has a reference in 'variable' (HASH); a hash key would be its address, not its contents\n",
		'a reference key');
	my %names = ("\x{e9}t\x{e9}" => [ 'k' ], "\x{436}" => [ 'v' ]);
	is_deeply(df2h(\%names, var_name => "\x{e9}t\x{e9}", value_name => "\x{436}"), { k => 'v' },
		'column names outside ASCII');
}

#----------------------------------------------------------------------------
# HoH: rows have names, and no order
{
	is(err { df2h($as{HoH}, var_name => 'name', duplicates => 'first') },
		"df2h: duplicates 'first' needs ordered rows, and a HoH's are not; use 'die', or give an AoH, AoA or HoA\n",
		"'first' is refused");
	like(err { df2h($as{HoH}, var_name => 'name', duplicates => 'LAST') }, qr/^df2h: duplicates 'last' needs ordered rows/,
		"and 'last', in any case");
	is_deeply(df2h($as{HoH}, var_name => 'name', duplicates => 'die'), \%abc, "'die' is taken");

	is(err { df2h({ r => 1, s => { variable => 'a', value => 1 } }) }, "df2h: row 'r' is not a hashref\n",
		'a row that is not a hash is named');
	is(err { df2h({ r => { variable => 'a' } }) }, "df2h: row 'r' has no 'value' column\n", 'a missing column');
	is(err { df2h({ r => { variable => undef, value => 1 } }) },
		"df2h: row 'r' has an undefined 'variable'; a hash key has to be defined\n", 'an undef key');
	is(err { df2h({ "\x{263A}" => { variable => [], value => 1 } }) },
		"df2h: row '\x{263A}' has a reference in 'variable' (ARRAY); a hash key would be its address, not its contents\n",
		'a row name outside Latin-1');

	# With many bad rows, the message names the first in sorted order, which
	# hash order -- what the first reading follows -- is very unlikely to be.
	my %many = map { (sprintf('r%03d', $_) => { variable => "k$_", value => $_ }) } 1 .. 200;
	$many{$_}{variable} = 'dup' for qw(r150 r020 r170 r090);
	$many{r077}{variable} = 'k1';	# r001's key, so r077 repeats it
	is(err { df2h(\%many) }, "df2h: duplicate key 'k1' has >= 2 occurrences, the first repeat at row 'r077'\n",
		'a repeated key: the first repeat in sorted row order (r077 repeats r001, before r090 repeats r020)');
	my %miss = map { (sprintf('r%03d', $_) => { variable => "k$_", value => $_ }) } 1 .. 200;
	delete $miss{$_}{value} for qw(r150 r033 r170);
	is(err { df2h(\%miss) }, "df2h: row 'r033' has no 'value' column\n",
		'a missing column: the first bad row in sorted order');
	my %mixed = map { (sprintf('r%03d', $_) => { variable => "k$_", value => $_ }) } 1 .. 200;
	$mixed{r140} = 'not a row';
	$mixed{r060}{variable} = undef;
	is(err { df2h(\%mixed) }, "df2h: row 'r060' has an undefined 'variable'; a hash key has to be defined\n",
		'two kinds of bad row: the first in sorted order, whichever kind');
}

#----------------------------------------------------------------------------
# Tied frames, rows and columns
our @LOG;
{	package LogArray;
	our @ISA = ('Tie::StdArray');
	sub FETCH     { push @main::LOG, "FETCH($_[1])"; $_[0]->SUPER::FETCH($_[1]) }
	sub FETCHSIZE { push @main::LOG, 'SIZE'; $_[0]->SUPER::FETCHSIZE() }
}
sub logged { my @t; tie @t, 'LogArray'; @t = @_; @LOG = (); \@t }
{
	# a tied AoA row: its length, then the key, then the value only once the
	# row is known to be kept
	my @rows = (logged('a', 1), logged('a', 2), logged('b', 3));
	@LOG = ();
	is_deeply(df2h(\@rows, duplicates => 'first'), { a => 1, b => 3 }, 'tied AoA rows fold');
	is("@LOG", 'SIZE FETCH(0) FETCH(1) SIZE FETCH(0) SIZE FETCH(0) FETCH(1)',
		"tied AoA rows under 'first': a repeat's value is never fetched");
	@LOG = ();
	is(err { df2h(\@rows) }, "df2h: duplicate key 'a' has >= 2 occurrences, the first repeat at index 1\n",
		"tied AoA rows under 'die'");
	is("@LOG", 'SIZE FETCH(0) FETCH(1) SIZE FETCH(0)', "and nor is it under 'die'");
	@LOG = ();
	is_deeply(df2h(\@rows, var_name => -2, value_name => -1, duplicates => 'last'), { a => 2, b => 3 },
		'tied AoA rows, negative positions');

	# tied HoA columns: one FETCHSIZE each in df2h, then the cells
	my $k = logged(qw(a a b));
	my $v = logged(1, 2, 3);
	@LOG = ();
	is_deeply(df2h({ variable => $k, value => $v }, duplicates => 'first'), { a => 1, b => 3 }, 'tied HoA columns');
	is(scalar(grep { $_ eq 'FETCH(1)' } @LOG), 1, "under 'first' a repeat's value cell is never fetched");

	# a tied frame of each shape is copied once and then read as any other
	my @aoa; tie @aoa, 'Tie::StdArray'; @aoa = ([ 'a', 1 ], [ 'b', 2 ]);
	is_deeply(df2h(\@aoa), { a => 1, b => 2 }, 'a tied AoA');
	my %hoa; tie %hoa, 'Tie::StdHash'; %hoa = (variable => [ 'a', 'b' ], value => [ 1, 2 ]);
	is_deeply(df2h(\%hoa), { a => 1, b => 2 }, 'a tied HoA');
	my %hoh; tie %hoh, 'Tie::StdHash'; %hoh = (r1 => { variable => 'a', value => 1 });
	is_deeply(df2h(\%hoh), { a => 1 }, 'a tied HoH');
	my %row; tie %row, 'Tie::StdHash'; %row = (variable => 'a', value => 1);
	is_deeply(df2h({ r1 => \%row }), { a => 1 }, 'a HoH of a tied row');
	is(err { df2h({ r1 => \%row }, value_name => 'n') }, "df2h: row 'r1' has no 'n' column\n",
		'a tied HoH row missing a column');
}

#----------------------------------------------------------------------------
# The input is left as it was
{
	my @rows = map { [ $_ * 1, $_ * 1.5 ] } 1 .. 3;
	df2h(\@rows);
	ok(!grep({ B::svref_2object(\$_->[0])->FLAGS & (B::SVf_POK | B::SVp_POK) } @rows),
		'AoA: a numeric key cell is not given a cached string');
	my %hoa = (variable => [ 1, 2 ], value => [ 3, 4 ]);
	df2h(\%hoa);
	ok(!grep({ B::svref_2object(\$_)->FLAGS & (B::SVf_POK | B::SVp_POK) } @{ $hoa{variable} }),
		'HoA: nor a numeric key in a column');
	my $h = df2h(\%hoa);
	$h->{1} = 99;
	is($hoa{value}[0], 3, 'editing the result does not touch the input');
}

#----------------------------------------------------------------------------
# Nothing leaks, on the way out or on a croak.
SKIP: {
	skip 'Test::LeakTrace not installed', 12 unless $HAVE_LEAKTRACE;
	my @aoa = map { [ "k$_", "v$_" ] } 1 .. 50;
	my %hoa = (variable => [ map { "k$_" } 1 .. 50 ], value => [ 1 .. 50 ]);
	my %hoh = map { ("r$_" => { variable => "k$_", value => $_ }) } 1 .. 50;
	my %bad = %hoh; $bad{r7} = { variable => 'k8', value => 0 }; $bad{r30} = 'x';
	my @ta; tie @ta, 'Tie::StdArray'; @ta = @aoa;
	no_leaks_ok { my $h = df2h(\@aoa) } 'no leak: AoA';
	no_leaks_ok { my $h = df2h(\@aoa, var_name => -1, value_name => -2, duplicates => 'last') }
		'no leak: AoA, negative positions';
	no_leaks_ok { my $h = df2h(\%hoa, duplicates => 'first') } 'no leak: HoA';
	no_leaks_ok { my $h = df2h(\%hoh) } 'no leak: HoH';
	no_leaks_ok { my $h = df2h(\@ta) } 'no leak: a tied AoA';
	no_leaks_ok { eval { df2h([ @aoa, ['x'] ]) } } 'no leak: a croak on a short AoA row';
	no_leaks_ok { eval { df2h([ @aoa, [ 'k1', 1 ] ]) } } 'no leak: a croak on an AoA repeat';
	no_leaks_ok { eval { df2h({ %hoa, value => [1] }) } } 'no leak: a croak on HoA lengths';
	no_leaks_ok { eval { df2h({ variable => [ @{ $hoa{variable} }, [] ], value => [ 1 .. 51 ] }) } }
		'no leak: a croak on a HoA reference key';
	no_leaks_ok { eval { df2h(\%bad) } } 'no leak: a croak on a HoH, read twice';
	no_leaks_ok { eval { df2h(\%hoh, duplicates => 'first') } } "no leak: 'first' refused for a HoH";
	no_leaks_ok { eval { df2h({ a => 1 }) } } 'no leak: a flat hash';
}

done_testing();
