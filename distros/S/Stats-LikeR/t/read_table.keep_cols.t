#!/usr/bin/env perl
# read_table(..., keep_cols => ...): only the columns named or matched are
# stored, given as whole names, as qr// patterns, or as a list of either, and
# alone or beside drop_cols.
#
# Provenance. The nearest reference is pandas' read_csv(usecols = ...), which
# keeps the columns named in a list, or those a callable on the name accepts
# (a qr// here). The "pandas" block below ports every name-based case of
# pandas 3.0.4 tests/io/parser/usecols/test_usecols_basic.py and
# test_strings.py, each labeled with the test function it comes from and, where
# pandas gives one, its GitHub issue. Expected values are the cells of each
# expected DataFrame as the text the CSV holds, which is what read_table
# stores: pandas' 0.056674972999999997 is its float of the file's 0.056674973.
# Where read_table differs from pandas, on purpose, the case pins
# read_table's behavior and says so:
#   - a name that is no column is a warning, not pandas' ValueError ("Usecols
#     do not match columns, columns expected but not found"), as it is for
#     drop_cols. The wording is R 4.6.1's for the same mistake in colClasses,
#     src/library/utils/R/readtable.R: "not all columns named in 'colClasses'
#     exist". The read goes on with the names that are columns;
#   - keeping no column is an error, where pandas returns an empty frame for
#     usecols = set() and for a callable that is always false; read_table
#     refuses an empty list outright, as drop_cols does;
#   - a field position is not a column; a number is a name, as in
#     test_usecols_with_integer_like_header's name-based half;
#   - a row with more or fewer fields than the header is an alignment error,
#     with or without keep_cols, so test_incomplete_first_row,
#     test_uneven_length_cols, test_usecols_additional_columns and the
#     trailing-comma half of test_usecols_index_col_false have no port here,
#     beyond pinning that refusal once;
#   - test_usecols_with_mixed_encoding_strings refuses a mix of str and bytes;
#     a perl string has no such split, and the UTF-8 block covers names held
#     both ways.
# What every other case is held to:
#   - a table written out in full in this file, in all four output types;
#   - the perl row closure (_closure => 1), which builds the same table without
#     the parser's plan, so the two implementations check each other;
#   - a plain read with the columns chosen afterwards, on a 600 x 40 table, and
#     drop_cols given the complement.
# Nothing here is floating point, so there is no tolerance to justify.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use File::Temp 'tempdir';
use IO::Compress::Gzip '$GzipError';
use Stats::LikeR;
use Test::Exception; # throws_ok, lives_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $dir = tempdir(CLEANUP => 1);
my $n_file = 0;

# Write $text to a new file with extension $ext, byte for byte.
sub spew {
	my ($ext, $text) = @_;
	my $file = File::Spec->catfile($dir, 'f' . ++$n_file . ".$ext");
	open my $fh, '>:raw', $file or die "$file: $!";
	print {$fh} $text;
	close $fh or die "$file: $!";
	return $file;
}

# The four output types of one table, from its header and its rows; a hoh is
# keyed by the first column, and is left out when that column has an empty
# cell, which no hoh can be keyed by.
sub shapes {
	my ($hdr, $rows) = @_;
	my %s;
	$s{aoa} = [ [ @$hdr ], map { [ @$_ ] } @$rows ];
	$s{aoh} = [ map {
		my $r = $_;
		+{ map { $hdr->[$_] => $r->[$_] } 0 .. $#$hdr }
	} @$rows ];
	$s{hoa} = @$rows ? { map {
		my $c = $_;
		$hdr->[$c] => [ map { $_->[$c] } @$rows ]
	} 0 .. $#$hdr } : {};
	return \%s if grep { !defined $_->[0] } @$rows;
	$s{hoh} = { map {
		my $r = $_;
		$r->[0] => +{ map { $hdr->[$_] => $r->[$_] } 1 .. $#$hdr }
	} @$rows };
	return \%s;
}

# read_table, with what it warned.
sub read_w {
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	my $t = read_table(@_);
	return ($t, \@w);
}

# One table, in every output type, by the parser's plan and by the closure.
# $warn is a regex each read must warn with, once, or undef for silence. The
# hoh is keyed by $hdr->[0], named outright.
sub check_all {
	my ($label, $file, $hdr, $rows, $args, $warn) = @_;
	my $want = shapes($hdr, $rows);
	for my $otype (qw(aoa aoh hoa hoh)) {
		for my $closure (0, 1) {
			my $how = $closure ? 'closure' : 'plan';
			my ($got, $w) = read_w($file, output_type => $otype, @$args,
				_closure => $closure, $otype eq 'hoh' ? (row_names => $hdr->[0]) : ());
			is_deeply($got, $want->{$otype}, "$label: $otype, $how");
			if (defined $warn) {
				ok(@$w == 1 && $w->[0] =~ $warn, "$label: $otype, $how warns")
					or diag("warnings: @$w");
			} else {
				is(scalar @$w, 0, "$label: $otype, $how is silent")
					or diag("warnings: @$w");
			}
		}
	}
}

# One read, by the plan and by the closure: the same table, and the same
# warnings, each matching one of @$warn in order.
sub check_both {
	my ($label, $want, $warn, @args) = @_;
	for my $closure (0, 1) {
		my $how = $closure ? 'closure' : 'plan';
		my ($got, $w) = read_w(@args, _closure => $closure);
		is_deeply($got, $want, "$label, $how");
		ok(@$w == @$warn && !grep({ $w->[$_] !~ $warn->[$_] } 0 .. $#$warn),
			"$label, $how: " . scalar(@$warn) . ' warning(s)') or diag("warnings: @$w");
	}
}

# Both paths must refuse the read in the same words.
sub dies_all {
	my ($label, $file, $re, $args, $otypes) = @_;
	for my $otype (@{ $otypes || [qw(aoa aoh hoa hoh)] }) {
		for my $closure (0, 1) {
			my $how = $closure ? 'closure' : 'plan';
			throws_ok {
				local $SIG{__WARN__} = sub { };
				read_table($file, output_type => $otype, @$args, _closure => $closure)
			} $re, "$label: $otype, $how";
		}
	}
}

# What read_table warns of names that are no column of $file.
sub absent {
	my ($opt, $file, @names) = @_;
	my $list = join ', ', map { "'$_'" } @names;
	return qr/\Aread_table: not all columns named in '\Q$opt\E' exist in \Q$file\E: \Q$list\E\n\z/;
}

#--------
# pandas 3.0.4, tests/io/parser/usecols/
#--------
my $abc = spew('csv', "a,b,c\n1,2,3\n4,5,6\n7,8,9\n10,11,12");
# test_usecols, usecols = ("b", "c")
check_all('pandas test_usecols', $abc, [qw(b c)],
	[ [2, 3], [5, 6], [8, 9], [11, 12] ], [ keep_cols => [qw(b c)] ]);
{
	my $f = spew('csv', "1,2,3\n4,5,6\n7,8,9\n10,11,12");
	# test_usecols_relative_to_names, names = ["a", "b", "c"], header = None
	check_all('pandas test_usecols_relative_to_names', $f, [qw(b c)],
		[ [2, 3], [5, 6], [8, 9], [11, 12] ],
		[ header => 0, col_names => [qw(a b c)], keep_cols => [qw(b c)] ]);
}
{
	# test_usecols_index_col_false (gh-9082), the first of its two files
	my $f = spew('csv', "a,b,c,d\n1,2,3,4\n5,6,7,8");
	check_all('pandas test_usecols_index_col_false', $f, [qw(a c d)],
		[ [1, 3, 4], [5, 7, 8] ], [ keep_cols => [qw(a c d)] ]);
	# test_raises_on_usecols_names_mismatch, every case: pandas raises where a
	# name is missing, read_table warns and keeps the rest
	check_all('pandas names_mismatch, all four', $f, [qw(a b c d)],
		[ [1, 2, 3, 4], [5, 6, 7, 8] ], [ keep_cols => [qw(a b c d)] ]);
	check_all("pandas names_mismatch, ['a','b','c','f']", $f, [qw(a b c)],
		[ [1, 2, 3], [5, 6, 7] ], [ keep_cols => [qw(a b c f)] ], absent('keep_cols', $f, 'f'));
	check_all("pandas names_mismatch, ['a','b','f']", $f, [qw(a b)],
		[ [1, 2], [5, 6] ], [ keep_cols => [qw(a b f)] ], absent('keep_cols', $f, 'f'));
	check_all("pandas names_mismatch, ['a','b','f','g']", $f, [qw(a b)],
		[ [1, 2], [5, 6] ], [ keep_cols => [qw(a b f g)] ], absent('keep_cols', $f, 'f', 'g'));
	# gh-14671: names replacing a header
	check_all('pandas names_mismatch, names and no usecols', $f, [qw(A B C D)],
		[ [1, 2, 3, 4], [5, 6, 7, 8] ], [ col_names => [qw(A B C D)], keep_cols => undef ]);
	check_all("pandas names_mismatch, names, ['A','B','C','f']", $f, [qw(A B C)],
		[ [1, 2, 3], [5, 6, 7] ], [ col_names => [qw(A B C D)], keep_cols => [qw(A B C f)] ],
		absent('keep_cols', $f, 'f'));
	# names without header = 0: the file's header line is a data row
	check_all("pandas names_mismatch, names, header = None, ['A','B','f']", $f, [qw(A B)],
		[ [qw(a b)], [1, 2], [5, 6] ],
		[ header => 0, col_names => [qw(A B C D)], keep_cols => [qw(A B f)] ],
		absent('keep_cols', $f, 'f'));
	# test_usecols_subset_names_mismatch_orig_columns, usecols = ["A", "C"]
	check_all('pandas test_usecols_subset_names_mismatch_orig_columns', $f, [qw(A C)],
		[ [1, 3], [5, 7] ], [ col_names => [qw(A B C D)], keep_cols => [qw(A C)] ]);
	# the trailing-comma file of test_usecols_index_col_false is a ragged row
	# here, as it is without keep_cols
	my $g = spew('csv', "a,b,c,d\n1,2,3,4,\n5,6,7,8,");
	dies_all('pandas test_usecols_index_col_false, trailing comma', $g,
		qr/\AAlignment error on .* data row 1 \(5 fields vs 4 headers\)\.$/,
		[ keep_cols => [qw(a c d)] ]);
}
{
	# index_col is a hoh's row_names
	my $f = spew('csv', "a,b,c,d\nA,a,1,one\nB,b,2,two");
	# test_usecols_index_col_conflict (gh-4201), usecols ["b", "c"], index_col "b"
	check_both('pandas test_usecols_index_col_conflict', { a => { c => 1 }, b => { c => 2 } }, [],
		$f, output_type => 'hoh', row_names => 'b', keep_cols => [qw(b c)]);
	# and without naming the key column: it is the key, so it is kept
	check_both('index_col left out of keep_cols', { a => { c => 1 }, b => { c => 2 } }, [],
		$f, output_type => 'hoh', row_names => 'b', keep_cols => 'c');
	my $g = spew('csv', "a,b,c,d\n1,2,3,4\n");
	# test_usecols_index_col_middle (GH#9098)
	check_both('pandas test_usecols_index_col_middle', { 3 => { b => 2, d => 4 } }, [],
		$g, output_type => 'hoh', row_names => 'c', keep_cols => [qw(b c d)]);
	# test_usecols_index_col_end (GH#9098)
	check_both('pandas test_usecols_index_col_end', { 4 => { b => 2, c => 3 } }, [],
		$g, output_type => 'hoh', row_names => 'd', keep_cols => [qw(b c d)]);
}
{
	# test_usecols_regex_sep (gh-2733) and test_usecols_with_whitespace: the
	# header is a field short, so its first column is the row names, which is
	# auto_row_names here and pandas' implicit index
	my $f = spew('txt', "a  b  c\n4  apple  bat  5.7\n8  orange  cow  10");
	my @args = ($f, sep => qr/\s+/, auto_row_names => 1, keep_cols => [qw(a b)]);
	check_both('pandas test_usecols_regex_sep, hoh',
		{ 4 => { a => 'apple', b => 'bat' }, 8 => { a => 'orange', b => 'cow' } }, [],
		@args, output_type => 'hoh');
	check_both('pandas test_usecols_regex_sep, aoh',
		[ { a => 'apple', b => 'bat' }, { a => 'orange', b => 'cow' } ], [],
		@args, output_type => 'aoh');
	check_both('pandas test_usecols_regex_sep, aoa',
		[ [qw(a b)], [qw(apple bat)], [qw(orange cow)] ], [], @args, output_type => 'aoa');
}
{
	# test_usecols_with_integer_like_header, by name: the names are kept in
	# the file's order, which is also the order they were given in here
	my $f = spew('csv', "2,0,1\n1000,2000,3000\n4000,5000,6000");
	check_all('pandas test_usecols_with_integer_like_header', $f, [qw(0 1)],
		[ [2000, 3000], [5000, 6000] ], [ keep_cols => [qw(0 1)] ]);
	# given as numbers, and in another order: still names, still file order
	check_all('integer-like names given as numbers, reversed', $f, [qw(0 1)],
		[ [2000, 3000], [5000, 6000] ], [ keep_cols => [1, 0] ]);
}
{
	my $f = spew('csv', join "\n", 'AaA,bBb,CCC,ddd',
		'0.056674973,8,True,a', '2.613230982,2,False,b', '3.568935038,7,False,a');
	my @rows = ( ['0.056674973', 8, 'a'], ['2.613230982', 2, 'b'], ['3.568935038', 7, 'a'] );
	# test_callable_usecols (gh-14154), lambda x: x.upper() in ["AAA", "BBB", "DDD"]
	check_all('pandas test_callable_usecols', $f, [qw(AaA bBb ddd)], \@rows,
		[ keep_cols => qr/\A(?:AAA|BBB|DDD)\z/i ]);
	# lambda x: False is an empty frame in pandas, and refused here
	dies_all('pandas test_callable_usecols, always false', $f,
		qr/\Aread_table: 'keep_cols' keeps no column of /, [ keep_cols => qr/(?!)/ ], [qw(aoa aoh hoa)]);
	# test_np_array_usecols (gh-12546)
	my $g = spew('csv', "a,b,c\n1,2,3");
	check_all('pandas test_np_array_usecols', $g, [qw(a b)], [ [1, 2] ], [ keep_cols => [qw(a b)] ]);
}
{
	# test_usecols_with_unicode_strings (gh-13219)
	my $f = spew('csv', join "\n", 'AAA,BBB,CCC,DDD',
		'0.056674973,8,True,a', '2.613230982,2,False,b', '3.568935038,7,False,a');
	my @rows = ( ['0.056674973', 8], ['2.613230982', 2], ['3.568935038', 7] );
	check_all('pandas test_usecols_with_unicode_strings', $f, [qw(AAA BBB)], \@rows,
		[ keep_cols => [qw(AAA BBB)] ]);
	# test_usecols_with_single_byte_unicode_strings (gh-13219)
	my $g = spew('csv', join "\n", 'A,B,C,D',
		'0.056674973,8,True,a', '2.613230982,2,False,b', '3.568935038,7,False,a');
	check_all('pandas test_usecols_with_single_byte_unicode_strings', $g, [qw(A B)], \@rows,
		[ keep_cols => [qw(A B)] ]);
	# test_usecols_with_multi_byte_characters: the names in UTF-8, given as
	# characters and as the bytes the file holds
	my ($aaa, $ii) = ("\xe3\x81\x82" x 3, "\xe3\x81\x84" x 2);
	my $h = spew('csv', join "\n", "$aaa,$ii,\xe3\x81\x86\xe3\x81\x86\xe3\x81\x86,"
		. "\xe3\x81\x88" x 4, '0.056674973,8,True,a', '2.613230982,2,False,b',
		'3.568935038,7,False,a');
	check_all('pandas test_usecols_with_multi_byte_characters', $h, [ $aaa, $ii ], \@rows,
		[ keep_cols => [ "\x{3042}" x 3, "\x{3044}" x 2 ] ]);
	check_all('pandas test_usecols_with_multi_byte_characters, as bytes', $h, [ $aaa, $ii ], \@rows,
		[ keep_cols => [ $aaa, $ii ] ]);
}
{
	# test_usecols_dtype: a class for a column that is not kept is not applied
	my $f = spew('csv', "\ncol1,col2,col3\na,1,x\nb,2,y\n");
	check_all('pandas test_usecols_dtype', $f, [qw(col1 col2)], [ ['a', 1], ['b', 2] ],
		[ keep_cols => [qw(col1 col2)],
		  colClasses => { col1 => 'character', col2 => 'integer', col3 => 'integer' } ]);
}
# test_empty_usecols: usecols = set() is an empty frame in pandas; an empty
# list is refused here, as it is for drop_cols
throws_ok { read_table($abc, keep_cols => []) }
	qr/read_table: error: 'keep_cols' must be a column name, a qr\/\/ regex, or an ARRAY reference of them/,
	'pandas test_empty_usecols: an empty list is refused';

#--------
# names and patterns
#--------
my $npi = spew('csv', join "\n",
	'NPI,Provider License Number_1,Provider Last Name,Provider License Number State Code_1,Entity Type Code,provider license number_2,score',
	'1003000126,MD-0481,ENKESHAFI,MD,1,x9,1.50',
	'1003000134,,CIBULL,IL,1,,2.0',
	'1003000142,35.0921,KHALIL,OH,2,NA,3e1',
	'');
my @all_hdr = ('NPI', 'Provider License Number_1', 'Provider Last Name',
	'Provider License Number State Code_1', 'Entity Type Code',
	'provider license number_2', 'score');
my @all_rows = (
	[1003000126, 'MD-0481', 'ENKESHAFI', 'MD', 1, 'x9',  '1.50'],
	[1003000134, undef,     'CIBULL',    'IL', 1, undef, '2.0'],
	[1003000142, '35.0921', 'KHALIL',    'OH', 2, 'NA',  '3e1'],
);
# The columns @k of the NPI table, as check_all takes them.
sub npi_cols {
	my @k = @_;
	return ([ @all_hdr[@k] ], [ map { [ @{$_}[@k] ] } @all_rows ]);
}
my $rx_lic = qr/^Provider License Number/;
{
	check_all('one name', $npi, npi_cols(0), [ keep_cols => 'NPI' ]);
	check_all('a list of one name', $npi, npi_cols(0), [ keep_cols => ['NPI'] ]);
	check_all('a pattern', $npi, npi_cols(0, 1, 3), [ keep_cols => [ 'NPI', $rx_lic ] ]);
	check_all('a case-insensitive pattern', $npi, npi_cols(0, 1, 3, 5),
		[ keep_cols => [ 'NPI', qr/^provider license number/i ] ]);
	check_all('an unanchored pattern', $npi, npi_cols(0, 1, 3), [ keep_cols => [ 'NPI', qr/License Number/ ] ]);
	# the order given is not the order kept: the file's is
	check_all('names out of order', $npi, npi_cols(0, 2, 6),
		[ keep_cols => [ 'score', 'Provider Last Name', 'NPI' ] ]);
	check_all('names and patterns', $npi, npi_cols(0, 1, 3, 4, 6),
		[ keep_cols => [ 'score', $rx_lic, 'NPI', qr/^Entity/ ] ]);
	# a name a pattern also matches, and a name given twice
	check_all('a name a pattern also matches', $npi, npi_cols(0, 1, 3),
		[ keep_cols => [ 'Provider License Number_1', $rx_lic, 'NPI', 'NPI' ] ]);
	# every column, by a pattern and by name
	check_all('every column by a pattern', $npi, \@all_hdr, \@all_rows, [ keep_cols => qr/./ ]);
	check_all('every column by name', $npi, \@all_hdr, \@all_rows, [ keep_cols => [ @all_hdr ] ]);
	check_all('keep_cols => undef', $npi, \@all_hdr, \@all_rows, [ keep_cols => undef ]);
	# a name is what the anchored, quoted pattern says
	for my $name ('score', 'Entity Type Code', 'NPI') {
		for my $otype (qw(aoa aoh hoa)) {
			is_deeply(read_table($npi, output_type => $otype, keep_cols => $name),
				read_table($npi, output_type => $otype, keep_cols => qr/\A\Q$name\E\z/),
				"'$name' is qr/\\A\\Q$name\\E\\z/: $otype");
		}
	}
	check_all('na_strings beside keep_cols', $npi, [ 'NPI', 'provider license number_2' ],
		[ [1003000126, 'x9'], [1003000134, undef], [1003000142, undef] ],
		[ keep_cols => [ 'NPI', 'provider license number_2' ], na_strings => 'NA' ]);
}

# A name is a whole name, in its own case, and never a pattern or a position.
# One that is no column is warned about and the read goes on; a pattern that
# matches nothing is silent.
{
	check_all('a name is not a prefix', $npi, npi_cols(0),
		[ keep_cols => [ 'NPI', 'Provider License Number' ] ],
		absent('keep_cols', $npi, 'Provider License Number'));
	check_all('a name is case-sensitive', $npi, npi_cols(6),
		[ keep_cols => [ 'npi', 'score' ] ], absent('keep_cols', $npi, 'npi'));
	check_all('a name is not a pattern', $npi, npi_cols(6),
		[ keep_cols => [ '^NPI$', 'score' ] ], absent('keep_cols', $npi, '^NPI$'));
	check_all('a number is a name, not a position', $npi, npi_cols(6),
		[ keep_cols => [ 2, 'score' ] ], absent('keep_cols', $npi, '2'));
	check_all('absent names listed once each, in order', $npi, npi_cols(6),
		[ keep_cols => [ 'zip', 'score', 'nope', 'zip' ] ], absent('keep_cols', $npi, 'zip', 'nope'));
	check_all('a silent pattern beside a name', $npi, npi_cols(6),
		[ keep_cols => [ qr/^no such column$/, 'score' ] ]);
	dies_all('only absent names', $npi, qr/\Aread_table: 'keep_cols' keeps no column of /,
		[ keep_cols => [qw(nope zip)] ], [qw(aoa aoh hoa)]);
	# both warn, and keep_cols' warning comes first
	check_both('absent names in both options', shapes(npi_cols(0, 6))->{aoh},
		[ absent('keep_cols', $npi, 'nope'), absent('drop_cols', $npi, 'zip') ],
		$npi, keep_cols => [ 'NPI', 'score', 'nope' ], drop_cols => 'zip');
}

# regex metacharacters, numbers, and the empty name
{
	my $f = spew('csv', "id,a.b,axb,cost (\$),x|y,a+\n1,2,3,4,5,6\n7,8,9,10,11,12\n");
	check_all('metacharacters in names', $f, [ 'id', 'a.b', 'cost ($)', 'x|y' ],
		[ [1, 2, 4, 5], [7, 8, 10, 11] ], [ keep_cols => [ 'id', 'a.b', 'cost ($)', 'x|y' ] ]);
	my $g = spew('csv', "id,0,2,10,2.0\na,b,c,d,e\nf,g,h,i,j\n");
	check_all('a column named 0', $g, [qw(id 0)], [ [qw(a b)], [qw(f g)] ], [ keep_cols => [ 'id', 0 ] ]);
	check_all("'2.0' the string, 2.0 the number", $g, [qw(id 2 2.0)],
		[ [qw(a c e)], [qw(f h j)] ], [ keep_cols => [ 'id', 2.0, '2.0' ] ]);
	my $h = spew('csv', "id,,x,,\n1,a,b,c,d\n2,e,f,g,h\n");
	# the empty name, repeated: every field carrying it is kept, and the
	# repeat is warned about as ever, except by an aoa
	my $dup = qr/duplicate column name\(s\) in .* \(later values win\): '' x 3 \(fields 2, 4, 5\)/;
	for my $closure (0, 1) {
		my ($got, $w) = read_w($h, output_type => 'aoa', keep_cols => [ 'id', '' ], _closure => $closure);
		is_deeply($got, [ [ 'id', '', '', '' ], [1, qw(a c d)], [2, qw(e g h)] ],
			"the empty name, repeated: aoa, closure $closure");
		is(scalar @$w, 0, "the empty name, repeated: aoa is silent, closure $closure");
		($got, $w) = read_w($h, output_type => 'aoh', keep_cols => [ 'id', '' ], _closure => $closure);
		is_deeply($got, [ { id => 1, '' => 'd' }, { id => 2, '' => 'h' } ],
			"the empty name, repeated: aoh, closure $closure");
		ok(@$w == 1 && $w->[0] =~ $dup, "the empty name, repeated: aoh warns, closure $closure")
			or diag("warnings: @$w");
	}
}

# the names keep_cols sees are those drop_cols sees
{
	check_all('col_names', $npi, [qw(id last score)],
		[ [1003000126, 'ENKESHAFI', '1.50'], [1003000134, 'CIBULL', '2.0'], [1003000142, 'KHALIL', '3e1'] ],
		[ col_names => [qw(id lic1 last st1 type lic2 score)], keep_cols => [qw(id last score)] ]);
	check_all('col_names, the old name absent', $npi, ['id'],
		[ [1003000126], [1003000134], [1003000142] ],
		[ col_names => [qw(id lic1 last st1 type lic2 score)], keep_cols => [qw(id NPI)] ],
		absent('keep_cols', $npi, 'NPI'));
	my $f = spew('csv', "a,b,c,d\ne,f,g,h\n");
	check_all('header => 0', $f, [qw(V1 V3)], [ [qw(a c)], [qw(e g)] ],
		[ header => 0, keep_cols => qr/^V[13]$/ ]);
	my $t = spew('tsv', "a\tb\tc\nr1\t1\t2\t3\nr2\t4\t5\t6\n");
	check_all('auto_row_names', $t, [qw(row_name c)], [ ['r1', 3], ['r2', 6] ],
		[ auto_row_names => 1, keep_cols => [qw(row_name c)] ]);
	my $c = spew('csv', "# id,val,note\n1,2,three\n4,5,six\n");
	check_all('commented-out header', $c, [qw(id note)], [ [1, 'three'], [4, 'six'] ],
		[ keep_cols => [qw(id note)] ]);
	my $e = spew('csv', ",x,y\nr1,1,2\nr2,3,4\n");
	check_all('an empty first name, as row_name', $e, [qw(row_name y)], [ ['r1', 2], ['r2', 4] ],
		[ keep_cols => [qw(row_name y)] ]);
}

# UTF-8 names, held as bytes, as characters, upgraded, and wide
{
	my $f = spew('csv', "id,Gr\xc3\xb6\xc3\x9fe,na\xe2\x80\x94me\n1,180,x\n2,175,y\n");
	my $groes = "Gr\xc3\xb6\xc3\x9fe";
	my $dash  = "na\xe2\x80\x94me";
	check_all('UTF-8 name, as bytes', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ keep_cols => [ 'id', $groes ] ]);
	check_all('UTF-8 name, as characters', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ keep_cols => [ 'id', "Gr\x{f6}\x{df}e" ] ]);
	my $up = "Gr\x{f6}\x{df}e";
	utf8::upgrade($up);
	check_all('UTF-8 name, upgraded', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ keep_cols => [ 'id', $up ] ]);
	check_all('UTF-8 name with a wide character', $f, [ 'id', $dash ], [ [1, 'x'], [2, 'y'] ],
		[ keep_cols => [ 'id', "na\x{2014}me" ] ]);
	check_all('UTF-8 pattern of characters', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ keep_cols => [ 'id', qr/^Gr\x{f6}/ ] ]);
	check_all('UTF-8 name given both ways', $f, [ 'id', $groes ], [ [1, 180], [2, 175] ],
		[ keep_cols => [ 'id', $groes, "Gr\x{f6}\x{df}e" ] ]);
	my ($got, $w) = read_w($f, keep_cols => [ 'id', "nope\x{2014}" ], output_type => 'aoa');
	is_deeply($got, [ ['id'], [1], [2] ], 'an absent wide name');
	ok(@$w == 1 && $w->[0] =~ /exist in .*: 'nope\xe2\x80\x94'\n\z/ && !utf8::is_utf8($w->[0]),
		'is reported as bytes') or diag("warnings: @$w");
	my $g = spew('csv', "id,Gr\xf6\xdfe,x\n1,180,2\n");
	check_all('Latin-1 name', $g, [ 'id', "Gr\xf6\xdfe" ], [ [1, 180] ],
		[ keep_cols => [ 'id', "Gr\xf6\xdfe" ] ]);
}

#--------
# keep_cols beside drop_cols: kept when keep_cols chooses it and drop_cols
# does not
#--------
{
	check_all('a pattern kept, a name dropped', $npi, npi_cols(0, 1),
		[ keep_cols => [ 'NPI', $rx_lic ], drop_cols => 'Provider License Number State Code_1' ]);
	check_all('names kept, a pattern dropped', $npi, npi_cols(0, 6),
		[ keep_cols => [ 'NPI', 'score', 'Provider License Number_1' ], drop_cols => $rx_lic ]);
	check_all('both naming one column: it goes', $npi, npi_cols(0),
		[ keep_cols => [qw(NPI score)], drop_cols => 'score' ]);
	check_all('drop_cols naming a column keep_cols left out anyway', $npi, npi_cols(0),
		[ keep_cols => 'NPI', drop_cols => 'score' ]);
	# the same as dropping the columns keep_cols leaves out
	for my $otype (qw(aoa aoh hoa)) {
		is_deeply(read_table($npi, output_type => $otype, keep_cols => qr/^[A-Z]/, drop_cols => qr/_\d$/),
			read_table($npi, output_type => $otype, drop_cols => [ qr/^[^A-Z]/, qr/_\d$/ ]),
			"keep and drop together, against drop alone: $otype");
	}
	dies_all('together leaving no column', $npi,
		qr/\Aread_table: 'keep_cols' and 'drop_cols' leave no column of /,
		[ keep_cols => [qw(NPI score)], drop_cols => [qw(NPI score)] ], [qw(aoa aoh hoa)]);
	# a hoh still keeps its key column: here it is the only one
	check_both('together leaving only the key', { 1003000126 => {}, 1003000134 => {}, 1003000142 => {} }, [],
		$npi, output_type => 'hoh', keep_cols => 'score', drop_cols => 'score');
}

#--------
# row_names: a hoh's key column is kept whether keep_cols names it or not
#--------
{
	my $f = spew('csv', "id,name,x,y\n1,bob,p,q\n2,amy,r,s\n");
	check_both('the default key, not named', { 1 => { y => 'q' }, 2 => { y => 's' } }, [],
		$f, output_type => 'hoh', keep_cols => 'y');
	check_both('the default key, named', { 1 => { y => 'q' }, 2 => { y => 's' } }, [],
		$f, output_type => 'hoh', keep_cols => [qw(id y)]);
	check_both('an explicit key, not named', { bob => { id => 1, x => 'p' }, amy => { id => 2, x => 'r' } }, [],
		$f, output_type => 'hoh', row_names => 'name', keep_cols => [qw(id x)]);
	check_both('an explicit key, matched', { bob => { x => 'p' }, amy => { x => 'r' } }, [],
		$f, output_type => 'hoh', row_names => 'name', keep_cols => qr/^(?:name|x)$/);
	# a pattern matching nothing still leaves the key: rows with no cells
	check_both('only the key', { 1 => {}, 2 => {} }, [],
		$f, output_type => 'hoh', keep_cols => qr/^no such column$/);
	# the key is a key, not a cell, in the other shapes too: those have none
	dies_all('only the key name, outside a hoh', $f,
		qr/\Aread_table: 'keep_cols' keeps no column of /, [ keep_cols => 'nope' ], [qw(aoa aoh hoa)]);
	# drop_cols still may not take it
	dies_all('drop_cols naming the key keep_cols keeps', $f,
		qr/\Aread_table: 'drop_cols' leaves out "name", the row_names column of /,
		[ row_names => 'name', keep_cols => [qw(name x)], drop_cols => 'name' ], ['hoh']);
	dies_all('a key that is no column', $f, qr/"nope" isn't in the header of /,
		[ row_names => 'nope', keep_cols => 'x' ], ['hoh']);
	# a repeated row name is still warned about
	my $g = spew('csv', "id,x,y\n1,a,b\n1,c,d\n");
	check_both('a repeated row name', { 1 => { y => 'd' } }, [ qr/duplicate row name '1'/ ],
		$g, output_type => 'hoh', keep_cols => 'y');
}

#--------
# repeated names
#--------
{
	my $f = spew('csv', "id,x,y,x,z\n1,a,b,c,d\n2,e,f,g,h\n");
	check_all('a repeated name left out', $f, [qw(id y z)], [ [1, 'b', 'd'], [2, 'f', 'h'] ],
		[ keep_cols => [qw(id y z)] ]);
	my $warn = qr/duplicate column name\(s\) in .* \(later values win\): 'x' x 2 \(fields 2, 4\)/;
	for my $otype (qw(aoh hoa hoh)) {
		check_both("a repeated name kept: $otype", shapes([qw(id x)], [ [1, 'c'], [2, 'g'] ])->{$otype},
			[ $warn ], $f, output_type => $otype, keep_cols => [qw(id x)]);
	}
	check_both('a repeated name kept: aoa keeps both fields',
		[ [qw(id x x)], [1, 'a', 'c'], [2, 'e', 'g'] ], [], $f, output_type => 'aoa', keep_cols => [qw(id x)]);
}

#--------
# what the parser has to cut around
#--------
{
	my $f = spew('csv', join '',
		qq{id,drop1,keep,drop2\n},
		qq{1,"a,b","c ""d"" e","x\ny"\n},
		qq{2,"","f,g",plain\n},
		qq{3,p,"h\ni","q ""r"""\n});
	check_all('quoted fields', $f, [qw(id keep)],
		[ [1, 'c "d" e'], [2, 'f,g'], [3, "h\ni"] ], [ keep_cols => [qw(id keep)] ]);
	check_all('quoted fields, the last kept', $f, [qw(keep drop2)],
		[ ['c "d" e', "x\ny"], ['f,g', 'plain'], ["h\ni", 'q "r"'] ], [ keep_cols => [qw(keep drop2)] ]);
	my $g = spew('csv', qq{id,drop\n1,a\n2,"never closed\n});
	check_all('EOF inside a quoted field not kept', $g, ['id'], [ [1], [2] ],
		[ keep_cols => 'id' ], qr/end of file inside a quoted field/);
	my @hdr  = qw(id b d);
	my @rows = ( [1, 'x', 'z'], [2, undef, 'w'] );
	my $args = [ keep_cols => [qw(id b d)] ];
	check_all('tab-separated', spew('tsv', "id\ta\tb\tc\td\n1\tp\tx\tq\tz\n2\t\t\t\tw\n"),
		\@hdr, \@rows, $args);
	check_all('a literal multi-byte sep', spew('txt', "id::a::b::c::d\n1::p::x::q::z\n2::::::::w\n"),
		\@hdr, \@rows, [ @$args, sep => '::' ]);
	check_all('CRLF line ends', spew('csv', "id,a,b,c,d\r\n1,p,x,q,z\r\n2,,,,w\r\n"), \@hdr, \@rows, $args);
	check_all('a byte-order mark and no final newline',
		spew('csv', "\xEF\xBB\xBFid,a,b,c,d\n1,p,x,q,z\n2,,,,w"), \@hdr, \@rows, $args);
	my $gz = File::Spec->catfile($dir, 'packed.csv.gz');
	my $text = "id,a,b,c,d\n1,p,x,q,z\n2,,,,w\n";
	IO::Compress::Gzip::gzip(\$text => $gz) or die "gzip: $GzipError";
	check_all('gzip-compressed', $gz, \@hdr, \@rows, $args);
	check_all('header only', spew('csv', "id,a,b\n"), [qw(id b)], [], [ keep_cols => [qw(id b)] ]);
	my $r = spew('csv', "id,a,b,c\n1,2,3,4\n5,6\n");
	dies_all('a short row', $r, qr/\AAlignment error on .* data row 2 \(2 fields vs 4 headers\)\.$/,
		[ keep_cols => [qw(id c)] ]);
}

#--------
# colClasses and filter
#--------
{
	# a class on a column not kept is not applied: 'MD-0481' is no number
	check_all('colClasses naming a column not kept', $npi, npi_cols(0, 6),
		[ keep_cols => [qw(NPI score)],
		  colClasses => { 'Provider License Number_1' => 'numeric', score => 'character' } ]);
	# a list is by the file's own fields
	check_all('colClasses by position', $npi, [qw(NPI score)],
		[ [1003000126, 1.5], [1003000134, 2], [1003000142, 30] ],
		[ keep_cols => [qw(NPI score)], colClasses => [ ('integer') x 6, 'numeric' ] ]);
	dies_all('a colClasses failure in a kept column', $npi,
		qr/colClasses makes column 'provider license number_2' \(field 6\) integer, but data row 1 of .* has 'x9' there/,
		[ keep_cols => [ 'NPI', 'provider license number_2' ],
		  colClasses => { 'provider license number_2' => 'integer' } ]);
	# a filter may test a column that is not kept, by name and by position
	check_all('a filter on a column not kept, by name', $npi, [qw(NPI score)],
		[ [1003000134, '2.0'] ],
		[ keep_cols => [qw(NPI score)],
		  filter => { 'Provider License Number State Code_1' => sub { $_ eq 'IL' } } ]);
	check_all('a filter on a column not kept, by position', $npi, [qw(NPI score)],
		[ [1003000126, '1.50'], [1003000142, '3e1'] ],
		[ keep_cols => [qw(NPI score)], filter => { 2 => sub { defined $_ } } ]);
	# a whole-row filter sees every field, and %_ only the kept columns
	for my $closure (0, 1) {
		my (@widths, @keys);
		my ($got) = read_w($npi, output_type => 'aoh', keep_cols => [qw(NPI score)], _closure => $closure,
			filter => sub {
				push @widths, scalar @{ $_[0] };
				push @keys, join ',', sort keys %_;
				return $_[0][4] == 1;
			});
		is_deeply($got, [ { NPI => 1003000126, score => '1.50' }, { NPI => 1003000134, score => '2.0' } ],
			"a whole-row filter, closure $closure");
		is_deeply(\@widths, [7, 7, 7], "its row has every field, closure $closure");
		is_deeply(\@keys, [ ('NPI,score') x 3 ], "its %_ has the kept columns, closure $closure");
	}
	dies_all('a filter on no column', $npi, qr/Filter column 'nope' not found in the header/,
		[ keep_cols => 'NPI', filter => { nope => sub { 1 } } ]);
}

#--------
# a wider table: against a plain read and against drop_cols of the complement
#--------
{
	my @hdr = ('id', map { "x$_" } 1 .. 39);
	my @site = qw(north south east west);
	my $text = join(',', @hdr) . "\n";
	for my $r (1 .. 600) {
		$text .= join(',', "r$r", map {
			my $c = $_;
			  ($r + $c) % 11 == 0 ? ''
			: $c % 5 == 0         ? $site[ ($r * $c) % 4 ]
			: $c % 5 == 1         ? $r * $c
			: $c % 5 == 2         ? sprintf('%.2f', $r / $c)
			: $c % 5 == 3         ? ($r % 7 ? "v$r.$c" : 'NA')
			:                       qq{"q,$r"}
		} 1 .. 39) . "\n";
	}
	my $f = spew('csv', $text);
	my $plain = read_table($f, output_type => 'aoa', na_strings => 'NA');
	is(scalar @$plain, 601, 'wide table: 600 rows and a header');
	for my $keep ([qw(x2 x17 x39)], [ 'id', map { "x$_" } grep { $_ % 3 } 1 .. 39 ], ['x1'],
			[ qr/^x\d*[05]$/ ], [ 'id', qr/^x3\d$/ ]) {
		my @k = grep {
			my $n = $plain->[0][$_];
			grep { ref $_ ? $n =~ $_ : $n eq $_ } @$keep
		} 0 .. $#hdr;
		my @rows = map { [ @{$_}[@k] ] } @{$plain}[1 .. $#$plain];
		my $want = shapes([ @hdr[@k] ], \@rows);
		# a hoh is keyed by id whether or not it is kept
		my @kh = (0, grep { $_ } @k);
		$want->{hoh} = shapes([ @hdr[@kh] ], [ map { [ @{$_}[@kh] ] } @{$plain}[1 .. $#$plain] ])->{hoh};
		my %k = map { $_ => 1 } @k;
		my @complement = map { $hdr[$_] } grep { !$k{$_} } 0 .. $#hdr;
		my $what = join ' ', map { "$_" } @$keep;
		$what = substr($what, 0, 40) . '...' if length $what > 40;
		for my $otype (qw(aoa aoh hoa hoh)) {
			for my $closure (0, 1) {
				my $got = read_table($f, output_type => $otype, keep_cols => $keep,
					na_strings => 'NA', _closure => $closure);
				is_deeply($got, $want->{$otype},
					"wide table, [$what]: $otype, closure $closure, " . scalar(@k) . ' kept');
			}
			next if $otype eq 'hoh' && !$k{0};	# drop_cols may not take the key
			is_deeply(read_table($f, output_type => $otype, keep_cols => $keep, na_strings => 'NA'),
				read_table($f, output_type => $otype, drop_cols => \@complement, na_strings => 'NA'),
				"wide table, [$what]: $otype, the same as drop_cols of the rest");
		}
		my $aoa = read_table($f, output_type => 'aoa', keep_cols => $keep);
		is(scalar(grep { @$_ != @k } @$aoa), 0, "wide table, [$what]: every aoa row has " . scalar(@k) . ' cells');
	}
}

#--------
# .xlsx and VCF
#--------
{
	my $x = File::Spec->catfile($dir, 'book.xlsx');
	my $groes = "Gr\xc3\xb6\xc3\x9fe";
	write_table([
		[ 'NPI', 'Provider License Number_1', 'name', $groes, 'n' ],
		[ 101, 'A1', 'bob', 180, 5 ],
		[ 102, undef, 'amy', 175, undef ],
	], $x, quiet => 1);
	check_all('.xlsx', $x, [qw(NPI name n)], [ [101, 'bob', 5], [102, 'amy', undef] ],
		[ keep_cols => [qw(NPI name n)] ]);
	check_all('.xlsx, a pattern and a UTF-8 name', $x, [ 'NPI', 'Provider License Number_1', $groes ],
		[ [101, 'A1', 180], [102, undef, 175] ], [ keep_cols => [ 'NPI', $rx_lic, "Gr\x{f6}\x{df}e" ] ]);
	check_all('.xlsx, an absent name', $x, [qw(NPI n)], [ [101, 5], [102, undef] ],
		[ keep_cols => [qw(NPI n N)] ], qr/not all columns named in 'keep_cols' exist in .*: 'N'\n\z/);
	dies_all('.xlsx, no column kept', $x, qr/'keep_cols' keeps no column of /, [ keep_cols => qr/(?!)/ ],
		[qw(aoa aoh hoa)]);

	my $v = spew('vcf', join "\n",
		'##fileformat=VCFv4.2',
		"#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1",
		"chr1\t100\trs1\tA\tG\t50\tPASS\tDP=10\tGT:DP\t0/1:10",
		"chr2\t200\t.\tC\tT\t60\tPASS\tDP=20\tGT:DP\t1/1:20",
		'');
	# the "#" is off the first name
	check_all('VCF, explode => 0', $v, [qw(CHROM POS REF ALT)],
		[ [qw(chr1 100 A G)], [qw(chr2 200 C T)] ], [ explode => 0, keep_cols => [qw(CHROM POS REF ALT)] ]);
	for my $args ([], [ explode => 1 ]) {
		throws_ok { read_table($v, @$args, keep_cols => 'POS') }
			qr/read_table: error: 'keep_cols' cannot be used with an exploded VCF; pass explode => 0/,
			'an exploded VCF refuses keep_cols' . (@$args ? ', explode => 1' : ', by default');
	}
}

#--------
# the empty pattern is every column, on every perl
#--------
# Before perl 5.18 an empty qr// reuses the last successful pattern (see
# _rx_for_match() in lib/Stats/LikeR.pm and t/read_table.drop_cols.t). After a
# match of /b/, an old perl without the fix would keep "bob" alone.
my $rx_empty = qr//;
{
	my $f = spew('csv', "NPI,name,bob\n1,amy,2\n3,joe,4\n");
	for my $closure (0, 1) {
		'abc' =~ /b/ or die 'the match that arms the old perls failed';
		my $got = read_table($f, output_type => 'aoa', keep_cols => $rx_empty, _closure => $closure);
		is_deeply($got, [ [qw(NPI name bob)], [1, 'amy', 2], [3, 'joe', 4] ],
			"keep_cols => qr// keeps every column, closure $closure");
	}
}

#--------
# refused arguments
#--------
{
	my $re = qr/read_table: error: 'keep_cols' must be a column name, a qr\/\/ regex, or an ARRAY reference of them/;
	my $rx = qr/a/;
	my %bad = (
		'an empty list'           => [],
		'a list with an undef'    => [ $rx, undef ],
		'a name and an undef'     => [ 'NPI', undef ],
		'a list with a list'      => [ [ 'NPI' ] ],
		'a name and a hash reference' => [ 'NPI', { score => 1 } ],
		'a hash reference'        => { a => 1 },
		'a scalar reference'      => \'a',
		'a code reference'        => sub { 1 },
	);
	for my $what (sort keys %bad) {
		throws_ok { read_table($npi, keep_cols => $bad{$what}) } $re, "keep_cols refuses $what";
	}
	# a bad drop_cols is refused beside a good keep_cols
	throws_ok { read_table($npi, keep_cols => 'NPI', drop_cols => []) }
		qr/'drop_cols' must be a column name/, 'a bad drop_cols beside keep_cols';
	throws_ok { read_table($npi, keep_col => 'NPI') } qr/unknown argument\(s\): keep_col/,
		"'keep_col' is an unknown argument";
}

#--------
# the caller's arguments are left alone
#--------
{
	my @list = ('NPI', $rx_lic);
	my @copy = @list;
	read_table($npi, keep_cols => \@list);
	is_deeply(\@list, \@copy, 'the list is not changed');
	'abc' =~ /(b)/;
	read_table($npi, keep_cols => $rx_lic);
	is($1, 'b', "the caller's \$1 survives the read");
}

#--------
# leaks
#--------
# Every qr// and closure is made out here, not inside a block: perl 5.10.0's
# pp_qr() leaks an SV each time a qr// is evaluated, which Test::LeakTrace
# would report against the no_leaks_ok line.
my $rx_none  = qr/^no such column$/;
my @keep     = ('NPI', $rx_lic, 'score');
my @names    = ('NPI', 'score');
my $cls_ok   = { NPI => 'integer', 'Provider License Number_1' => 'numeric' };
my $cls_bad  = { 'provider license number_2' => 'integer' };
my $flt_out  = { 'Provider License Number State Code_1' => sub { $_ eq 'IL' } };
my $flt_row  = sub { $_[0][4] == 1 };
my $quiet    = sub { };
my $bad_arg  = { a => 1 };
my $ragged   = spew('csv', "id,a,b,c\n1,2,3,4\n5,6\n");
my $xlsx     = File::Spec->catfile($dir, 'book.xlsx');
unless ($INC{'Devel/Cover.pm'}) {
	for my $otype (qw(aoa aoh hoa hoh)) {
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => 'score') }
		} "read_table(keep_cols) by one name: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => \@keep) }
		} "read_table(keep_cols) by names and a pattern: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => \@keep, _closure => 1) }
		} "read_table(keep_cols) by the closure: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => $rx_lic, drop_cols => 'Provider License Number_1') }
		} "read_table(keep_cols, drop_cols): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => \@names, colClasses => $cls_ok) }
		} "read_table(keep_cols, colClasses): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => \@names, colClasses => $cls_bad,
				filter => $flt_out) }
		} "read_table(keep_cols, filter) croaking on colClasses: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => \@names, filter => $flt_row) }
		} "read_table(keep_cols, whole-row filter): no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($ragged, output_type => $otype, keep_cols => 'id') }
		} "read_table(keep_cols) croaking on a ragged row: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => $rx_none) }
		} "read_table(keep_cols) keeping nothing: no memory leaks, $otype";
		no_leaks_ok {
			eval { read_table($npi, output_type => $otype, keep_cols => $rx_empty) }
		} "read_table(keep_cols) with an empty pattern: no memory leaks, $otype";
		no_leaks_ok {
			local $SIG{__WARN__} = $quiet;	# the sheet has no 'score'
			eval { read_table($xlsx, output_type => $otype, keep_cols => \@keep) }
		} "read_table(keep_cols) on an .xlsx: no memory leaks, $otype";
	}
	no_leaks_ok {
		local $SIG{__WARN__} = $quiet;
		eval { read_table($npi, keep_cols => [ 'NPI', 'no such column' ]) }
	} 'read_table(keep_cols) warning of an absent name: no memory leaks';
	no_leaks_ok {
		eval { read_table($npi, keep_cols => $bad_arg) }
	} 'read_table(keep_cols) refusing its argument: no memory leaks';
}

done_testing();
