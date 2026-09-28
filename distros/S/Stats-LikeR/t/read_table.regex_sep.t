#!/usr/bin/env perl
# read_table with a qr// separator.
#
# Up to 0.319 'sep' was only ever a literal string: a qr// was stringified to
# "(?^:\s+)", matched byte for byte, never found, and every line came back as
# one field keyed by the whole header line. A qr// is now found by the regex
# engine, called from the same C parser (_parse_csv_file) that reads a literal
# sep, and any other sep is the literal it always was.
#
# Provenance. The whitespace and multi-character cases are pandas' own, from
# pandas 3.0.4
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas),
# tests/io/parser/, each read there with sep=r"\s+" unless noted:
#
#   common/test_common_basic.py
#     test_whitespace_regex_separator (gh-6607), both parameters
#     test_ignore_leading_whitespace (gh-3374, gh-6607)
#     test_single_char_leading_whitespace (gh-9710)
#   test_header.py
#     test_header_multiple_whitespaces (GH#54931)
#     test_header_delim_whitespace (GH#54918)
#   usecols/test_usecols_basic.py, test_usecols_regex_sep (gh-2733)
#   test_skiprows.py, test_skiprows_lineterminator (gh-9079), "\n" and "\r\n"
#   test_c_parser_only.py, test_delim_whitespace_custom_terminator (gh-12912)
#   test_python_parser_only.py
#     test_decompression_regex_sep (gh-6607), sep="::"
#     test_multi_char_sep_quotes (gh-13374), sep=",,"
#
# pandas reads sep=r"\s+" as delim_whitespace, so leading and trailing
# whitespace make no field; read_table does the same for qr/\s+/ and for no
# other pattern (see _sep_re_is_ws). Adaptations, all forced by read_table
# having no names=, index_col=, skiprows=, lineterminator= or compression=:
#
#   * where pandas infers an index because the header is one field short
#     (test_whitespace_regex_separator's first case, test_usecols_regex_sep),
#     the index is read with 'auto.row.names', which exists for exactly that
#     shape, and usecols=("a", "b") becomes a look at columns a and b;
#   * test_skiprows_lineterminator skips its first line and supplies the
#     column names with names=; here that line is replaced by a header holding
#     those names, which keeps what the case is about -- trailing whitespace
#     before a "\n" or "\r\n". Its "\r" case is not taken: no read_table path
#     ends a line at a bare "\r";
#   * test_delim_whitespace_custom_terminator's "~" line ends become "\n";
#   * test_decompression_regex_sep's csv1 with "," replaced by "::" is, here,
#     t/HepatitisCdata.csv with "," replaced by "::", compared with the
#     literal read of the original, as pandas compares with read_csv(csv1).
#
# One deliberate divergence, pinned so that changing it is a decision:
# test_multi_char_sep_quotes expects pandas' python engine to refuse
# 'a,,b\n1,,a\n2,,"2,,b"' ("ignored when a multi-char delimiter is used"),
# because that engine drops quote handling for a regex separator. read_table
# keeps it, as it does for every literal separator, so the quoted ",," is text.
#
# pandas reads 1 as an integer; read_table returns every cell as the string
# the file holds, which is_deeply compares equal to it.
#
# The rest -- quoting, comments, byte-order marks, CRLF, filters, every
# output shape, capture groups, flags, and every refusal -- is this module's
# own surface, and its expected values are the fixtures themselves. The
# equivalence block reads every CSV under t/, and a tab-separated copy of
# each, both ways -- with the literal separator and with qr/\Q$sep\E/ -- and
# requires the same answer, the same warnings and the same error.
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

my $ws = qr/\s+/;

# --- pandas: whitespace-delimited (sep=r"\s+") -----------------------------

is_deeply read_table(fixture(<<'END'), sep => $ws, 'auto.row.names' => 1),
   A   B   C   D
a   1   2   3   4
b   1   2   3   4
c   1   2   3   4
END
	[
		{ row_name => 'a', A => 1, B => 2, C => 3, D => 4 },
		{ row_name => 'b', A => 1, B => 2, C => 3, D => 4 },
		{ row_name => 'c', A => 1, B => 2, C => 3, D => 4 },
	],
	'test_whitespace_regex_separator: indented header one field short';

is_deeply read_table(fixture("    a b c\n1 2 3 \n4 5  6\n 7 8 9"), sep => $ws),
	[ { a => 1, b => 2, c => 3 }, { a => 4, b => 5, c => 6 },
	  { a => 7, b => 8, c => 9 } ],
	'test_whitespace_regex_separator: leading, trailing and doubled blanks';

is_deeply read_table(fixture(" a b c\n 1 2 3\n 4 5 6\n 7 8 9"), sep => $ws),
	[ { a => 1, b => 2, c => 3 }, { a => 4, b => 5, c => 6 },
	  { a => 7, b => 8, c => 9 } ],
	'test_ignore_leading_whitespace';

is_deeply read_table(fixture("MyColumn\na\nb\na\nb\n"), sep => $ws),
	[ map { { MyColumn => $_ } } qw(a b a b) ],
	'test_single_char_leading_whitespace';

is_deeply read_table(fixture("aa    bb(1,1)   cc(1,1)\n                0  2  3.5"),
		sep => $ws),
	[ { aa => 0, 'bb(1,1)' => 2, 'cc(1,1)' => 3.5 } ],
	'test_header_multiple_whitespaces';

is_deeply read_table(fixture("a,b\n1,2\n3,4\n    "), sep => $ws),
	[ { 'a,b' => '1,2' }, { 'a,b' => '3,4' } ],
	'test_header_delim_whitespace: a comma is text, a blank last line is skipped';

{
	my $got = read_table(
		fixture("a  b  c\n4  apple  bat  5.7\n8  orange  cow  10"),
		sep => $ws, 'auto.row.names' => 1);
	is_deeply [ map { [ @$_{qw(row_name a b)} ] } @$got ],
		[ [ 4, 'apple', 'bat' ], [ 8, 'orange', 'cow' ] ],
		'test_usecols_regex_sep';
}

for my $eol ("\n", "\r\n") {
	my $data = join $eol,
		'date time var flag oflag ',
		'2007/01/01 01:00   0.2140 U M ',
		'2007/01/01 02:00   0.2141 M O ',
		'2007/01/01 04:00   0.2142 D M ';
	my @want = map {
		my %r; @r{qw(date time var flag oflag)} = @$_; \%r
	} [ '2007/01/01', '01:00', '0.2140', 'U', 'M' ],
	  [ '2007/01/01', '02:00', '0.2141', 'M', 'O' ],
	  [ '2007/01/01', '04:00', '0.2142', 'D', 'M' ];
	(my $name = $eol) =~ s/\r/\\r/; $name =~ s/\n/\\n/;
	is_deeply read_table(fixture($data), sep => $ws), \@want,
		"test_skiprows_lineterminator: trailing blank before $name";
}

is_deeply read_table(fixture("a b c\n1 2 3\n4 5 6\n7 8 9"), sep => $ws),
	[ { a => 1, b => 2, c => 3 }, { a => 4, b => 5, c => 6 },
	  { a => 7, b => 8, c => 9 } ],
	'test_delim_whitespace_custom_terminator, with newlines';

# --- pandas: multi-character separators --------------------------------------

{
	my $src = File::Spec->catfile('t', 'HepatitisCdata.csv');
	open my $in, '<:raw', $src or die "cannot read \"$src\": $!\n";
	my $text = do { local $/; <$in> };
	close $in;
	$text =~ s/,/::/g;
	my $f = fixture($text);
	my $want = read_table($src);
	is_deeply read_table($f, sep => qr/::/), $want,
		'test_decompression_regex_sep: "::" as a regex';
	is_deeply read_table($f, sep => '::'), $want,
		'test_decompression_regex_sep: "::" as a literal, the same answer';
}

is_deeply read_table(fixture(qq{a,,b\n1,,a\n2,,"2,,b"}), sep => qr/,,/),
	[ { a => 1, b => 'a' }, { a => 2, b => '2,,b' } ],
	'test_multi_char_sep_quotes: divergence -- quotes are kept, not refused';

# --- the leading-separator rule ---------------------------------------------

# Only qr/\s+/ is pandas' delim_whitespace. Any other pattern cuts as split()
# does, so a leading separator leaves an empty first field -- here the header's,
# which read_table names row_name as it does an empty first header name.
is_deeply read_table(fixture(" a b\n 1 2\n"), sep => qr/[ \t]+/),
	[ { row_name => undef, a => 1, b => 2 } ],
	'a leading separator is an empty first field for qr/[ \t]+/';
{
	# a trailing separator leaves an empty last field, as a literal one does,
	# and the header's empty last name is an ordinary column name
	my $got = read_table(fixture("a b \n1 2 \n"), sep => qr/ /);
	is_deeply $got, [ { a => 1, b => 2, '' => undef } ],
		'a trailing separator is an empty last field for qr/ /';
}
is_deeply read_table(fixture("a b\n1 2\n"), sep => qr/\s+/x),
	[ { a => 1, b => 2 } ], 'qr/\s+/x is still the whitespace rule';

# --- patterns ----------------------------------------------------------------

is_deeply read_table(fixture("id , name ,score\n1,  ann , 3\n"), sep => qr/\s*,\s*/),
	[ { id => 1, name => 'ann', score => 3 } ],
	'qr/\s*,\s*/ trims around each comma';
is_deeply read_table(fixture("a,b;c\n1;2,3\n"), sep => qr/(,)|(;)/),
	[ { a => 1, b => 2, c => 3 } ],
	'capture groups in the pattern are not fields, unlike split()';
is_deeply read_table(fixture("aXbxc\n1x2X3\n"), sep => qr/x/i),
	[ { a => 1, b => 2, c => 3 } ], 'the pattern keeps its own flags';
is_deeply read_table(fixture("a|b||c\n1||2|3\n"), sep => qr/\|+/),
	[ { a => 1, b => 2, c => 3 } ], 'a run of separators is one separator';
is_deeply read_table(fixture("a\\s+b\n1\\s+2\n"), sep => '\s+'),
	[ { a => 1, b => 2 } ], 'a string sep is still a literal, not a pattern';
is_deeply read_table(fixture("xb,c\nb,2\n"), sep => qr/(?<=b),/),
	[ { xb => 'b', c => 2 } ], 'a lookbehind sees the text before the field';
is_deeply read_table(fixture("a b\n1 2\n"), delim => $ws),
	[ { a => 1, b => 2 } ], "'delim' takes a regex as 'sep' does";

# --- quotes, which a regex separator honours as a literal one does -----------

is_deeply read_table(fixture(qq{name score\n"ann lee" 3\n"say ""hi""" 4\n}),
		sep => $ws),
	[ { name => 'ann lee', score => 3 }, { name => 'say "hi"', score => 4 } ],
	'a quoted field keeps its blanks, and "" is one quote';
is_deeply read_table(fixture(qq{name score\n  "ann lee"   3  \n\t"bo"\t4\t\n}),
		sep => $ws),
	[ { name => 'ann lee', score => 3 }, { name => 'bo', score => 4 } ],
	'leading and trailing blanks on a line with quotes make no field';
is_deeply read_table(fixture(qq{a b\n"x\n  y" 2\n 3 4\n}), sep => $ws),
	[ { a => "x\n  y", b => 2 }, { a => 3, b => 4 } ],
	'a quoted field runs over lines, which keep their leading blanks';
is_deeply read_table(fixture(qq{a;b\n1;"2;3"\n}), sep => qr/;/),
	[ { a => 1, b => '2;3' } ], 'a separator inside quotes is text';
{
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	is_deeply read_table(fixture(qq{a;b\n1;"unterminated\n}), sep => qr/;/),
		[ { a => 1, b => "unterminated\n" } ],
		'a quote still open at the end of the file ends the last field';
	is scalar @warn, 1, '... and says so, once';
	like $warn[0], qr/\Aread_table: end of file inside a quoted field in \S+: a '"' at the start of a field on line 2 opened/,
		'... naming the line the quote opened on';
}
is_deeply read_table(fixture("a;b\r\n1;2\r\n"), sep => qr/;/),
	[ { a => 1, b => 2 } ], 'CRLF line ends';
is_deeply read_table(fixture("a;b\n1\r;2\n"), sep => qr/;/),
	[ { a => 1, b => 2 } ], 'a stray CR outside quotes is dropped';

# --- the rest of read_table's surface ----------------------------------------

is_deeply read_table(fixture("\xEF\xBB\xBFid  v\n1  2\n"), sep => $ws),
	[ { id => 1, v => 2 } ], 'a UTF-8 byte-order mark is dropped';
# The leading comment has three words to the data's two fields: one with two
# would be taken for a commented-out header, as the next case shows.
is_deeply read_table(fixture("# three word note\nid v\n\n# more\n1 2\n"), sep => $ws),
	[ { id => 1, v => 2 } ], 'comment and blank lines are skipped';
is_deeply read_table(fixture("# PDB   score\n1a2b   10\n3c4d   20\n"), sep => $ws),
	[ { PDB => '1a2b', score => 10 }, { PDB => '3c4d', score => 20 } ],
	'a commented-out header is found with a regex separator';
is_deeply read_table(fixture("% id v\n1 2\n"), sep => $ws, comment => '%'),
	[ { id => 1, v => 2 } ], "'comment' is honoured";
{
	my $f = fixture("id v\n1 NA\n2 3\n3 -\n");
	is_deeply read_table($f, sep => $ws, 'na.strings' => [ 'NA', '-' ]),
		[ { id => 1, v => undef }, { id => 2, v => 3 }, { id => 3, v => undef } ],
		"'na.strings'";
	is_deeply read_table($f, sep => $ws, 'output.type' => 'hoa'),
		{ id => [ 1, 2, 3 ], v => [ 'NA', 3, '-' ] }, "'output.type' => 'hoa'";
	is_deeply read_table($f, sep => $ws, 'output.type' => 'hoh'),
		{ 1 => { v => 'NA' }, 2 => { v => 3 }, 3 => { v => '-' } },
		"'output.type' => 'hoh'";
	is_deeply read_table($f, sep => $ws, 'output.type' => 'hoh', 'row.names' => 'v'),
		{ NA => { id => 1 }, 3 => { id => 2 }, '-' => { id => 3 } },
		"'row.names'";
	is_deeply read_table($f, sep => $ws, filter => { id => sub { $_ > 1 } }),
		[ { id => 2, v => 3 }, { id => 3, v => '-' } ], "'filter'";
	local $/;
	is_deeply read_table($f, sep => $ws), [ { id => 1, v => 'NA' },
		{ id => 2, v => 3 }, { id => 3, v => '-' } ],
		'a local $/ changes nothing';
}
{
	my $f = File::Spec->catfile($dir, 'book.xlsx');
	write_table([ { a => 'x,y', b => 2 } ], $f, 'row.names' => 0);
	is_deeply read_table($f, sep => qr/,/), read_table($f),
		'an .xlsx ignores a regex sep, as it ignores a literal one';
}

# --- refusals ----------------------------------------------------------------

{
	my $f = fixture("a b\n1 2\n");
	like error_of(sub { read_table($f, sep => qr/\s*/) }),
		qr/^read_table: the sep regex \(\?\S*:\\s\*\) matches an empty string; it must match at least one character$/,
		'a pattern that matches an empty string is refused before reading';
	like error_of(sub { read_table(fixture("a,b\n1,2\n"), sep => qr/(?=,)/) }),
		qr/^read_table: the sep regex \S+ matched an empty string at \S+ line 1; it must match at least one character$/,
		'a lookahead is refused where it first matches an empty string';
	like error_of(sub { read_table(fixture(qq{a,"b"\n1,2\n}), sep => qr/(?=,)/) }),
		qr/matched an empty string at \S+ line 1;/,
		'the same, on a line with a quote in it';
	is_deeply read_table(fixture("xa\nx1\n"), sep => qr/(?=x)/),
		[ { xa => 'x1' } ],
		'an empty match at the start of a line is not a cut, as in split()';
	is_deeply read_table(fixture(qq{a,b\n"(q)",2\n}), sep => qr/,|(?=q)/),
		[ { a => '(q)', b => 2 } ],
		'an empty match inside a quoted field is text, as a separator there is';
	like error_of(sub { read_table($f, sep => [' ']) }),
		qr/^read_table: 'sep' must be a string or a qr\/\/ regex, not a ARRAY reference$/,
		'an ARRAY sep is refused';
	like error_of(sub { read_table($f, delim => {}) }),
		qr/^read_table: 'sep' must be a string or a qr\/\/ regex, not a HASH reference$/,
		'a HASH delim is refused under the same name';
	like error_of(sub { read_table($f, sep => $ws, delim => $ws) }),
		qr/^read_table: pass either 'sep' or 'delim', not both$/,
		"'sep' and 'delim' together are still refused";
	like error_of(sub { read_table(fixture("a b\n1 2 3\n"), sep => $ws) }),
		qr/^Alignment error on \S+ data row 1 \(3 fields vs 2 headers\)\.$/,
		'a ragged row is the same alignment error';
}

# --- backreferences ---------------------------------------------------------

# The pattern is matched as it was written. 0.320's first regex parser wrapped
# it in a capture of its own to cut lines with split(), which renumbered its
# groups: \1 then meant the whole separator, so a line with no quote in it was
# one field while a line with one was cut correctly.
is_deeply read_table(fixture(qq{a::b\n1::2\n"q"::3\n}), sep => qr/(:)\1/),
	[ { a => 1, b => 2 }, { a => 'q', b => 3 } ],
	'a backreference in the pattern refers to its own group';
is_deeply read_table(fixture(qq{# a::b\n1::2\n}), sep => qr/(:)\1/),
	[ { a => 1, b => 2 } ],
	'and so it does in a commented-out header';

# --- equivalence with the literal parser ------------------------------------

{
	# forward slashes, which glob() takes on Windows too, where a backslash
	# from File::Spec would be read as an escape
	my @csv = sort grep { -s $_ } glob('t/*.csv');
	cmp_ok scalar @csv, '>', 0, 'there are CSV files to compare';
	# t/ holds no TSV, so each CSV is also compared with every comma made a
	# tab -- inside quotes too, which both parsers see alike
	my @files = @csv;
	for my $f (@csv) {
		open my $in, '<:raw', $f or die "cannot read \"$f\": $!\n";
		(my $text = do { local $/; <$in> }) =~ tr/,/\t/;
		close $in;
		push @files, fixture($text, '.tsv');
	}
	for my $f (@files) {
		my $sep = $f =~ /\.tsv\z/ ? "\t" : ',';
		my $re  = qr/\Q$sep\E/;
		for my $otype (qw(aoh hoa hoh)) {
			for my $arn (0, 1) {
				my @opt = ('output.type' => $otype, $arn ? ('auto.row.names' => 1) : ());
				my (@warn_lit, @warn_re);
				my $lit = do {
					local $SIG{__WARN__} = sub { push @warn_lit, @_ };
					my $r = eval { read_table($f, sep => $sep, @opt) };
					defined $r ? $r : "died: $@";
				};
				my $rx = do {
					local $SIG{__WARN__} = sub { push @warn_re, @_ };
					my $r = eval { read_table($f, sep => $re, @opt) };
					defined $r ? $r : "died: $@";
				};
				is_deeply [ $rx, \@warn_re ], [ $lit, \@warn_lit ],
					"$f, $otype, auto.row.names=$arn: the same as the literal";
			}
		}
	}
}

done_testing();
