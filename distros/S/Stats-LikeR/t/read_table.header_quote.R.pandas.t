#!/usr/bin/env perl
# read_table's header => 0, col.names and quote => ''.
#
# Up to 0.320 read_table always took the first line as the header, and a '"'
# anywhere in an unquoted field always opened a quoted one. A file with no
# header (NCBI's taxonomy dumps, R's write.table(col.names = FALSE)) lost its
# first row to the column names, and one stray '"' -- NCBI's
# fullnamelineage.dmp has a name ending in 'Beach rock 4+5"' -- swallowed
# every line up to the next '"', about 950,000 of them, without an error.
#
# header => 0 is R's header = FALSE and pandas' header=None; col.names is
# R's col.names and pandas' names=; quote => '' is R's quote = "" and
# pandas' quoting=csv.QUOTE_NONE.
#
# Provenance, R. The inputs are R 4.6.1's own
# (/home/con/Scripts/r-source), and every expected value is the output of R
# 4.6.1 itself on that input, frozen from dput() with colClasses =
# "character" so that no cell is type-converted:
#
#   tests/reg-IO2.R, "tests of boundary cases in read.table()":
#     foo1 (empty file, col.names = LETTERS[1:4]), foo2 ("head\n"), foo3
#     ("head\n 1 2 \n 3 4 \n", header = TRUE with col.names = "V1" and with
#     col.names = letters[1:4]), the allowEscapes = FALSE line "1 2 3
#     \ab\c", and both test.dat files of quoted, tab-separated fields behind
#     "#comment" and "%comment" lines;
#   tests/reg-tests-2.R, "extensions to read.table": the file
#     write.table(Mat, col.names = FALSE, row.names = FALSE) writes;
#   tests/reg-tests-1d.R, "when sep is given, an opening quote may be
#     preceded by non-space": '="Total\t"\t1' and '="CJ01 "\t550' with
#     sep = "\t", and "HO5''\tH" with no sep;
#   tests/reg-tests-1a.R, the na.strings = "foo" case after type.convert();
#   tests/reg-tests-1b.R, PR#13433, "field1\tfield2\n 1\ta\n 2\tb".
#
# Each is read with header = FALSE, R's default, except foo3. The quote = ""
# expected values are the same inputs read by R with quote = "" added, which
# R's suite does not do. The generator is t/read_table.header_quote.R next to
# this file; run it with `Rscript t/read_table.header_quote.R` from the
# distribution root and copy what it prints into the tables below.
#
# Provenance, pandas 3.0.4
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas),
# tests/io/parser/:
#
#   test_header.py: test_no_header (both parameters),
#     test_header_none_and_implicit_index_in_second_row (GH#22144)
#   test_quoting.py: test_quoting_various (the default and QUOTE_NONE),
#     test_null_quote_char (QUOTE_NONE), test_double_quote (doublequote=True)
#   test_dialect.py: test_dialect (QUOTE_NONE)
#   test_python_parser_only.py: test_multi_char_sep_quotes (QUOTE_NONE)
#   test_na_values.py: test_default_na_values, whose na list is
#     pandas._libs.parsers.STR_NA_VALUES, frozen below with repr(sorted(...))
#
# Adaptations and divergences, each deliberate:
#
#   * R's default sep = "" is whitespace, and is read here as qr/\s+/, which
#     follows the same rule (t/read_table.regex_sep.t); the tab files are
#     also read with sep => "\t".
#   * R names header-less columns V1, V2, ...; pandas names them 0, 1, ...
#     read_table follows R, so test_no_header's default names are V1..V5.
#   * An empty file gives [] here, as every empty read_table does; R gives a
#     0-row data frame with columns A to D.
#   * A header one field short of the data is R's automatic row names and
#     pandas' implicit index; here it is 'auto.row.names', which exists for
#     that shape (foo3, test_dialect). R's warning for foo3 with
#     letters[1:4], "header and 'col.names' are of different lengths", is
#     given here too; R then fails in scan(), and read_table on the ragged row.
#   * R ends a line at a comment character anywhere, read_table only skips a
#     line that starts with one. With quote = "", R reads the cell
#     '"# Blemishes"' as '"' followed by a comment; read_table keeps the cell.
#     That is the one cell where the two differ, pinned below.
#   * pandas has no comment character by default and read_table has '#', so
#     test_default_na_values, whose first row is "#N/A,,...", is read with
#     comment => ''.
#   * With header => 0 there is no "#"-prefixed header to rescue, so a line
#     starting with the comment marker is a comment even when text hugs the
#     marker ("#comment"), as in R; with a header, "#id,val" is still a header.
#
# The rest -- every output shape on both of read_table's paths, filters,
# .xlsx, the regex parser, and every refusal -- is this module's own surface,
# and its expected values are the fixtures themselves.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table write_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $seq = 0;

sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'f' . $seq++ . ($ext // '.txt'));
	open my $fh, '>:raw', $path or die "cannot write \"$path\": $!\n";
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

sub error_of {
	my ($code) = @_;
	return eval { $code->(); 1 } ? '' : $@;
}

# A data frame as R prints it with dput(), column by column, made into the
# array of hashes read_table returns. undef is R's NA.
sub frame {
	my (@cols) = @_;	# name => [cells], ...
	my @rows;
	for (my $k = 0; $k < @cols; $k += 2) {
		my ($name, $cells) = @cols[ $k, $k + 1 ];
		$rows[$_]{$name} = $cells->[$_] for 0 .. $#$cells;
	}
	return \@rows;
}

my $ws = qr/\s+/;

# --- R: tests/reg-IO2.R -------------------------------------------------------

is_deeply read_table(fixture(''), header => 0, 'col.names' => [ 'A' .. 'D' ]),
	[], 'reg-IO2 foo1: an empty file with col.names';

is_deeply read_table(fixture("head\n"), header => 0, sep => $ws),
	frame(V1 => ['head']), 'reg-IO2 foo2: one line, no header';
is_deeply read_table(fixture("head\n"), header => 0, sep => $ws,
		'output.type' => 'hoa'),
	{ V1 => ['head'] }, 'reg-IO2 foo2, as a hoa';

{
	my $foo3 = fixture("head\n 1 2 \n 3 4 \n");
	is_deeply read_table($foo3, sep => $ws, 'col.names' => ['V1'],
			'auto.row.names' => 1),
		[ { row_name => 1, V1 => 2 }, { row_name => 3, V1 => 4 } ],
		'reg-IO2 foo3: col.names renames a header, row names 1 and 3';
	my @warn;
	my $err = do {
		local $SIG{__WARN__} = sub { push @warn, @_ };
		error_of(sub { read_table($foo3, sep => $ws, 'col.names' => [ 'a' .. 'd' ]) });
	};
	is_deeply \@warn,
		[ "read_table: header and 'col.names' are of different lengths (1 and 4) in $foo3\n" ],
		'reg-IO2 foo3, letters[1:4]: R\'s warning';
	like $err, qr/^Alignment error on \Q$foo3\E data row 1 \(2 fields vs 4 headers\)\.$/,
		'reg-IO2 foo3, letters[1:4]: and then an error, as R\'s scan() gives one';
}

is_deeply read_table(fixture("1 2 3 \\ab\\c\n"), header => 0, sep => $ws),
	frame(V1 => ['1'], V2 => ['2'], V3 => ['3'], V4 => ['\\ab\\c']),
	'reg-IO2 allowEscapes = FALSE: a backslash is text';

{
	my $body = qq{C1\tC2\tC3\n"Panel"\t"Area Examined"\t"# Blemishes"\n}
		. qq{"1"\t"0.8"\t"3"\n"2"\t"0.6"\t"2"\n"3"\t"0.8"\t"3"\n};
	my $hash = fixture("#comment\n\n#another\n#\n#\n$body");
	my $want = frame(
		V1 => [ 'C1', 'Panel', '1', '2', '3' ],
		V2 => [ 'C2', 'Area Examined', '0.8', '0.6', '0.8' ],
		V3 => [ 'C3', '# Blemishes', '3', '2', '3' ]);
	is_deeply read_table($hash, header => 0, sep => $ws), $want,
		'reg-IO2 test.dat: "#comment" lines are comments, quotes are honoured';
	is_deeply read_table($hash, header => 0, sep => "\t"), $want,
		'reg-IO2 test.dat, sep = "\t"';
	my $none = frame(
		V1 => [ 'C1', '"Panel"', '"1"', '"2"', '"3"' ],
		V2 => [ 'C2', '"Area Examined"', '"0.8"', '"0.6"', '"0.8"' ],
		V3 => [ 'C3', '"', '"3"', '"2"', '"3"' ]);
	# the one divergence: R ends the line at the '#' inside the cell
	$none->[1]{V3} = '"# Blemishes"';
	is_deeply read_table($hash, header => 0, sep => "\t", quote => ''), $none,
		'reg-IO2 test.dat, sep = "\t", quote = "": the quotes are text';

	(my $pct_body = $body) =~ s/# Blemishes/% Blemishes/;
	my $pct = fixture("%comment\n\n%another\n%\n%\n$pct_body");
	$want->[1]{V3} = '% Blemishes';
	is_deeply read_table($pct, header => 0, sep => $ws, comment => '%'), $want,
		'reg-IO2 test.dat, comment.char = "%"';
	$none->[1]{V3} = '"% Blemishes"';
	is_deeply read_table($pct, header => 0, sep => "\t", quote => '', comment => '%'),
		$none, 'reg-IO2 test.dat, comment.char = "%", quote = ""';
}

# --- R: tests/reg-tests-2.R, write.table(col.names = FALSE) -------------------

{
	my $f = fixture(join '', map { "$_\n" }
		'"1" "a" "1" "A" "2004-01-01" "2004-01-01 12:00"',
		'"2" "b" "2" "B" "2004-02-01" "2004-02-01 12:00"',
		'"3" "c" "3" "C" "2004-03-01" "2004-03-01 12:00"');
	is_deeply read_table($f, header => 0, sep => $ws),
		frame(V1 => [ 1, 2, 3 ], V2 => [qw(a b c)], V3 => [ 1, 2, 3 ],
			V4 => [qw(A B C)], V5 => [ '2004-01-01', '2004-02-01', '2004-03-01' ],
			V6 => [ '2004-01-01 12:00', '2004-02-01 12:00', '2004-03-01 12:00' ]),
		'reg-tests-2: write.table(col.names = FALSE) reads back';
	is_deeply read_table($f, header => 0, sep => ' ', quote => ''),
		frame(V1 => [ '"1"', '"2"', '"3"' ], V2 => [ '"a"', '"b"', '"c"' ],
			V3 => [ '"1"', '"2"', '"3"' ], V4 => [ '"A"', '"B"', '"C"' ],
			V5 => [ '"2004-01-01"', '"2004-02-01"', '"2004-03-01"' ],
			V6 => [ '"2004-01-01', '"2004-02-01', '"2004-03-01' ],
			V7 => [ '12:00"', '12:00"', '12:00"' ]),
		'reg-tests-2, quote = "", sep = " ": the quoted blank separates';
}

# --- R: tests/reg-tests-1d.R, 1a.R, 1b.R ------------------------------------

is_deeply read_table(fixture(qq{="Total\t"\t1\n}), header => 0, sep => "\t"),
	frame(V1 => ["=Total\t"], V2 => ['1']),
	'reg-tests-1d: an opening quote after "=" still quotes';
is_deeply read_table(fixture(qq{="Total\t"\t1\n}), header => 0, sep => "\t",
		quote => ''),
	frame(V1 => ['="Total'], V2 => ['"'], V3 => ['1']),
	'reg-tests-1d, quote = "": the tab inside the quotes separates';
is_deeply read_table(fixture(qq{="CJ01 "\t550\n}), header => 0, sep => "\t"),
	frame(V1 => ['=CJ01 '], V2 => ['550']), 'reg-tests-1d: "=CJ01 "';
is_deeply read_table(fixture(qq{="CJ01 "\t550\n}), header => 0, sep => "\t",
		quote => ''),
	frame(V1 => ['="CJ01 "'], V2 => ['550']), 'reg-tests-1d: "=CJ01 ", quote = ""';
is_deeply read_table(fixture("HO5''\tH\n"), header => 0, sep => $ws),
	frame(V1 => ["HO5''"], V2 => ['H']), "reg-tests-1d: HO5'' keeps its quotes";

is_deeply read_table(fixture("1 foo \n 2 NA \n"), header => 0, sep => $ws,
		'na.strings' => 'foo'),
	frame(V1 => [ '1', '2' ], V2 => [ undef, 'NA' ]),
	'reg-tests-1a: na.strings = "foo" on a header-less file';

is_deeply read_table(fixture("field1\tfield2\n 1\ta\n 2\tb"), header => 0, sep => $ws),
	frame(V1 => [ 'field1', '1', '2' ], V2 => [ 'field2', 'a', 'b' ]),
	'reg-tests-1b PR#13433: three rows, the last with no newline';

# --- pandas -------------------------------------------------------------------

{
	my $f = fixture("1,2,3,4,5\n6,7,8,9,10\n11,12,13,14,15\n");
	my @rows = ([ 1 .. 5 ], [ 6 .. 10 ], [ 11 .. 15 ]);
	my $named = sub {
		my @n = @_;
		[ map { my %r; @r{@n} = @$_; \%r } @rows ];
	};
	is_deeply read_table($f, header => 0), $named->(map { "V$_" } 1 .. 5),
		'test_no_header: default names (R\'s V1.., where pandas has 0..)';
	is_deeply read_table($f, header => 0,
			'col.names' => [qw(foo bar baz quux panda)]),
		$named->(qw(foo bar baz quux panda)), 'test_no_header: names=';
}

is_deeply read_table(fixture('1,2,"foo"'), header => 0, 'col.names' => [qw(a b c)]),
	[ { a => 1, b => 2, c => 'foo' } ], 'test_quoting_various: default';
is_deeply read_table(fixture('1,2,"foo"'), header => 0, 'col.names' => [qw(a b c)],
		quote => ''),
	[ { a => 1, b => 2, c => '"foo"' } ], 'test_quoting_various: QUOTE_NONE';
is_deeply read_table(fixture("a,b,c\n1,2,3"), quote => ''),
	[ { a => 1, b => 2, c => 3 } ], 'test_null_quote_char: QUOTE_NONE';
is_deeply read_table(fixture(qq{a,b\n3,"4 "" 5"})),
	[ { a => 3, b => '4 " 5' } ], 'test_double_quote: doublequote=True';
is_deeply read_table(fixture(qq{label1,label2,label3\nindex1,"a,c,e\nindex2,b,d,f\n}),
		quote => '', 'auto.row.names' => 1),
	[ { row_name => 'index1', label1 => '"a', label2 => 'c', label3 => 'e' },
	  { row_name => 'index2', label1 => 'b',  label2 => 'd', label3 => 'f' } ],
	'test_dialect: QUOTE_NONE leaves a lone quote as text';
like error_of(sub { read_table(fixture(qq{a,,b\n1,,a\n2,,"2,,b"}), sep => qr/,,/,
		quote => '') }),
	qr/^Alignment error on \S+ data row 2 \(3 fields vs 2 headers\)\.$/,
	'test_multi_char_sep_quotes: QUOTE_NONE, the quoted ",," separates';
like error_of(sub { read_table(fixture("x,1\ny,2,5\nz,3\n"), header => 0,
		'col.names' => [qw(a b)]) }),
	qr/^Alignment error on \S+ data row 2 \(3 fields vs 2 headers\)\.$/,
	'test_header_none_and_implicit_index_in_second_row';
{
	my @na = ('', '#N/A', '#N/A N/A', '#NA', '-1.#IND', '-1.#QNAN', '-NaN',
		'-nan', '1.#IND', '1.#QNAN', '<NA>', 'N/A', 'NA', 'NULL', 'NaN',
		'None', 'n/a', 'nan', 'null');
	my $nv = @na;
	my $data = join "\n", map {
		my $i = $_;
		join ',', map { $_ == $i ? $na[$i] : '' } 0 .. $nv - 1;
	} 0 .. $nv - 1;
	my $got = read_table(fixture($data), header => 0, comment => '',
		'na.strings' => \@na);
	is scalar @$got, $nv, 'test_default_na_values: one row per token';
	is scalar(grep { defined } map { values %$_ } @$got), 0,
		'test_default_na_values: every cell is missing';
}

# --- header => 0 across read_table's surface ---------------------------------

{
	my $f = fixture("1,a\n2,b\n3,c\n4,d\n");
	my $aoh = [ map { { V1 => $_->[0], V2 => $_->[1] } }
		[ 1, 'a' ], [ 2, 'b' ], [ 3, 'c' ], [ 4, 'd' ] ];
	# the first row is read by the closure and the rest by the C fast path,
	# while a filter keeps every row in the closure; both must agree
	is_deeply read_table($f, header => 0), $aoh, 'aoh, fast path';
	is_deeply read_table($f, header => 0, filter => sub { 1 }), $aoh, 'aoh, closure';
	my $hoa = { V1 => [ 1 .. 4 ], V2 => [qw(a b c d)] };
	is_deeply read_table($f, header => 0, 'output.type' => 'hoa'), $hoa, 'hoa';
	is_deeply read_table($f, header => 0, 'output.type' => 'hoa', filter => sub { 1 }),
		$hoa, 'hoa, closure';
	my $hoh = { 1 => { V2 => 'a' }, 2 => { V2 => 'b' }, 3 => { V2 => 'c' },
		4 => { V2 => 'd' } };
	is_deeply read_table($f, header => 0, 'output.type' => 'hoh'), $hoh,
		'hoh: the row names default to V1';
	is_deeply read_table($f, header => 0, 'output.type' => 'hoh', filter => sub { 1 }),
		$hoh, 'hoh, closure';
	is_deeply read_table($f, header => 0, 'output.type' => 'hoh', 'row.names' => 'V2'),
		{ a => { V1 => 1 }, b => { V1 => 2 }, c => { V1 => 3 }, d => { V1 => 4 } },
		"'row.names' names a V column";
	is_deeply read_table($f, header => 0, filter => { V1 => sub { $_ > 2 } }),
		[ { V1 => 3, V2 => 'c' }, { V1 => 4, V2 => 'd' } ], 'a filter on V1';
	is_deeply read_table($f, header => 0, filter => { 2 => sub { $_ eq 'a' } }),
		[ { V1 => 1, V2 => 'a' } ], 'a numeric filter key';
	is_deeply read_table($f, header => 0, 'col.names' => [qw(n s)],
			filter => { s => sub { $_ eq 'b' } }),
		[ { n => 2, s => 'b' } ], 'a filter on a col.names name';
	is_deeply read_table($f, header => 0, sep => qr/,/), $aoh, 'the regex parser';
	is_deeply read_table($f, header => 1), [ map { { 1 => $_->{V1}, a => $_->{V2} } }
		@$aoh[ 1 .. 3 ] ], 'header => 1 is the default';
}
is_deeply read_table(fixture("#id,val\n1,2\n"), header => 0),
	[ { V1 => 1, V2 => 2 } ], 'a "#"-hugging line is a comment with header => 0';
is_deeply read_table(fixture("#id,val\n1,2\n"), header => 0, sep => qr/,/),
	[ { V1 => 1, V2 => 2 } ], 'the same through the regex parser';
is_deeply read_table(fixture("#id,val\n1,2\n")),
	[ { id => 1, val => 2 } ], 'but still a header with header => 1';
is_deeply read_table(fixture("#id,val\n1,2\n"), header => 0, comment => ''),
	[ { V1 => '#id', V2 => 'val' }, { V1 => 1, V2 => 2 } ],
	"comment => '' makes it data";
is_deeply read_table(fixture("# PDB score\n1a2b 10\n"), header => 0, sep => $ws),
	[ { V1 => '1a2b', V2 => 10 } ],
	'no commented-out header is looked for with header => 0';
is_deeply read_table(fixture("\xEF\xBB\xBF1,2\n"), header => 0),
	[ { V1 => 1, V2 => 2 } ], 'a byte-order mark is dropped';
is_deeply read_table(fixture("r1,1,2\nr2,3,4\n"), header => 0,
		'col.names' => [qw(a b)], 'auto.row.names' => 1),
	[ { row_name => 'r1', a => 1, b => 2 }, { row_name => 'r2', a => 3, b => 4 } ],
	'auto.row.names with col.names one short';
{
	my $f = File::Spec->catfile($dir, 'book.xlsx');
	write_table([ { a => 1, b => 'x' } ], $f, 'row.names' => 0);
	is_deeply read_table($f, header => 0),
		[ { V1 => 'a', V2 => 'b' }, { V1 => 1, V2 => 'x' } ],
		'an .xlsx with header => 0 reads its header row as data';
	is_deeply read_table($f, 'col.names' => [qw(p q)]), [ { p => 1, q => 'x' } ],
		'and col.names renames an .xlsx header';
}

# --- quote => '' --------------------------------------------------------------

{
	# the shape of NCBI's fullnamelineage.dmp, with its unbalanced quote
	my $f = fixture(join '', map { "$_\t|\n" }
		"2727884\t|\tPleurocapsales cyanobacterium 'Beach rock 4'\t|\tcellular organisms; ",
		"2727889\t|\tPleurocapsales cyanobacterium 'Beach rock 4+5\"'\t|\tcellular organisms; ",
		"2730760\t|\tExapion sp. ZFMK TIS 3529\t|\tcellular organisms; ",
		"298141\t|\tExapion sp. \"malvae\"\t|\tcellular organisms; ");
	my @opt = (sep => qr/\t\|\t?/, header => 0, quote => '',
		'col.names' => [qw(tax_id tax_name lineage end)]);
	my $got = read_table($f, @opt);
	is_deeply [ map { [ $_->{tax_id}, $_->{tax_name} ] } @$got ],
		[ [ 2727884, "Pleurocapsales cyanobacterium 'Beach rock 4'" ],
		  [ 2727889, "Pleurocapsales cyanobacterium 'Beach rock 4+5\"'" ],
		  [ 2730760, 'Exapion sp. ZFMK TIS 3529' ],
		  [ 298141,  'Exapion sp. "malvae"' ] ],
		'an unbalanced quote swallows nothing with quote => \'\'';
	# a literal "\t|\t" leaves each line's closing "\t|" on the last field,
	# so there are three columns, not four
	is_deeply [ map { $_->{tax_name} } @{ read_table($f, sep => "\t|\t",
			header => 0, quote => '', 'col.names' => [qw(tax_id tax_name lineage)]) } ],
		[ map { $_->{tax_name} } @$got ],
		'the same names with a literal separator';
}
is_deeply read_table(fixture(qq{a,b\n"x""y",2\n}), quote => ''),
	[ { a => '"x""y"', b => 2 } ], 'a doubled quote stays doubled';
like error_of(sub { read_table(fixture(qq{a,b\n"x\n2,3\n}), quote => '') }),
	qr/^Alignment error on \S+ data row 1 \(1 fields vs 2 headers\)\.$/,
	'a quote does not join lines';
is_deeply read_table(fixture(qq{a"b"c\n1"2"3\n}), sep => '"', quote => ''),
	[ { a => 1, b => 2, c => 3 } ], 'a \'"\' separator, with quote => \'\'';
is_deeply read_table(fixture(qq{a,b\n"1",2\n}), quote => '"'),
	[ { a => 1, b => 2 } ], "quote => '\"' is the default";
is_deeply read_table(fixture(qq{a b\n"1 2" 3\n}), sep => $ws, quote => '',
		'auto.row.names' => 1),
	[ { row_name => '"1', a => '2"', b => 3 } ],
	'quote => \'\' through the regex parser';

# --- refusals -------------------------------------------------------------

{
	my $f = fixture("a,b\n1,2\n");
	# perl's own false is '', which is taken as 0
	is_deeply read_table($f, header => !!0), [ { V1 => 'a', V2 => 'b' },
		{ V1 => 1, V2 => 2 } ], "header => !!0 is header => 0";
	for my $bad ([ 2, '2' ], [ undef, 'undef' ], [ 'no', "'no'" ], [ [], 'an ARRAY' ]) {
		like error_of(sub { read_table($f, header => $bad->[0]) }),
			qr/^read_table: 'header' must be 0 or 1$/, "header => $bad->[1] is refused";
	}
	for my $bad ([ 'a', 'a string' ], [ [], 'an empty ARRAY' ], [ {}, 'a HASH' ]) {
		like error_of(sub { read_table($f, 'col.names' => $bad->[0]) }),
			qr/^read_table: 'col.names' must be an ARRAY reference of names$/,
			"col.names => $bad->[1] is refused";
	}
	for my $bad ([ [ 'a', undef ], 'an undef name' ], [ [ 'a', [] ], 'a reference' ]) {
		like error_of(sub { read_table($f, 'col.names' => $bad->[0]) }),
			qr/^read_table: 'col.names' may only hold defined, plain strings$/,
			"col.names with $bad->[1] is refused";
	}
	for my $bad ([ "'", q{"'"} ], [ undef, 'undef' ], [ ['"'], 'an ARRAY' ], [ '""', q{'""'} ]) {
		like error_of(sub { read_table($f, quote => $bad->[0]) }),
			qr/^read_table: 'quote' must be '"' \(the default\) or '' \(no quoting\)$/,
			"quote => $bad->[1] is refused";
	}
}

# --- equivalence of the two parsers under the new options ------------------

{
	my @csv = sort grep { -s $_ } glob('t/*.csv');
	cmp_ok scalar @csv, '>', 0, 'there are CSV files to compare';
	for my $f (@csv) {
		for my $opt ([ quote => '' ], [ header => 0 ], [ header => 0, quote => '' ]) {
			my (@warn_lit, @warn_re);
			my $lit = do {
				local $SIG{__WARN__} = sub { push @warn_lit, @_ };
				my $r = eval { read_table($f, @$opt) };
				defined $r ? $r : "died: $@";
			};
			my $rx = do {
				local $SIG{__WARN__} = sub { push @warn_re, @_ };
				my $r = eval { read_table($f, @$opt, sep => qr/,/) };
				defined $r ? $r : "died: $@";
			};
			is_deeply [ $rx, \@warn_re ], [ $lit, \@warn_lit ],
				"$f, @$opt: the regex parser agrees with the literal one";
		}
	}
}

done_testing();
