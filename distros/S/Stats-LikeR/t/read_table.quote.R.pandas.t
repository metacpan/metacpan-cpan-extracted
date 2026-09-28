#!/usr/bin/env perl
# read_table and a '"' that may not have been meant as a quote.
#
# A '"' that opens a quoted field takes every newline into that field until
# the next '"'. Up to 0.320 nothing said when that had happened: a file with
# one unclosed '"' came back as a single row whose last cell held the rest of
# the file, and a stray one in the middle of a field (an inch mark, 5'10")
# either ran two rows together or ended in an "Alignment error" that said
# nothing about quotes. read_table now
#
#   * warns when the file ends inside a quoted field, naming the line the
#     quote opened on, and keeps what it read, as R's scan() does;
#   * warns, once per file, when a quote that opened in the middle of a field
#     ran on across a line, since that is almost never a CSV cell;
#   * adds the same account to an alignment error on a row that a quoted
#     field ran across lines in, on both the fast path and the perl one;
#   * warns when quote => '' is given for a file whose first line has every
#     field in '"', which R's write.csv() writes and which then keeps the
#     quote marks in every name.
#
# A quote that opens after text still opens a quoted field, as it does in R:
# R 4.6.1's tests/reg-tests-1d.R pins '="Total\t"\t1' (sep = "\t") opening
# one, and t/read_table.header_quote.R.pandas.t carries that case. pandas
# instead keeps such a '"' as text. That is the one place the two references
# disagree about the parse itself, and this file pins read_table on R's side
# of it (the mid-field cases below).
#
# Provenance, pandas 3.0.4
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas),
# tests/io/parser/:
#
#   test_quoting.py: test_unbalanced_quoting (gh-22789), both parameters. pandas'
#     C engine raises "EOF inside string starting at row 1" for the unbalanced
#     one; read_table warns and keeps the cell, as R does.
#   common/test_file_buffer_url.py: the IN_QUOTED_FIELD case of
#     test_eof_states, 'a,b,c\n4,5,6\n"', where pandas raises "EOF inside
#     string starting at row 2".
#   test_python_parser_only.py: test_read_csv_unclosed_double_quote_in_data_
#     still_errors (GH 62739), without its skiprows, which read_table lacks.
#   test_skiprows.py: test_skip_row_with_newline_and_quote (gh-12775,
#     gh-10911), all three inputs, read without skiprows=[1] so every row is
#     compared; test_skiprows_infield_quote (gh-14459), without skiprows=2.
#   test_textreader.py: TestTextReader.test_embedded_newline, header=None.
#   test_c_parser_only.py: test_data_after_quote (gh-15910).
#   test_quoting.py: test_quoting_various, the QUOTE_NONE parameter.
#
# pandas' values for the inputs read without skiprows come from pandas 3.0.4
# itself, frozen from t/read_table.quote.pandas.py; run it with
# `python3 t/read_table.quote.pandas.py` from the distribution root.
#
# Provenance, R 4.6.1 (/home/con/Scripts/r-source): the warning follows
# src/main/scan.c, which warns "EOF within quoted string" and keeps the
# field. R's own reading of each input above, and of R's write.csv() output
# '"a","b"\n1,"x"\n2,"y"\n' (the quote => '' case), is frozen from
# t/read_table.quote.R; run it with `Rscript t/read_table.quote.R`. Where
# read_table agrees with R and not pandas, the comment at the case says so.
#
# The warning and error wording, the once-per-file rule, and both-path
# agreement are this module's own surface.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table write_table);

my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $seq = 0;

sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'q' . ++$seq . ($ext // '.csv'));
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot close $path: $!";
	return $path;
}

# One read, as { r => result or undef, err => $@ or '', warn => [warnings] }.
sub attempt {
	my @args = @_;
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	my $r = eval { read_table(@args) };
	return { r => $r, err => $@, warn => \@warn };
}

# The whole of the account S_quote_note() gives, for a quote that opened on
# $line, after text when $mid, and ran on to line $to (undef = never closed).
sub note_re {
	my ($line, $mid, $to) = @_;
	my $where = $mid ? 'in the middle of a field' : 'at the start of a field';
	my $end   = defined $to ? "ran on to line $to" : 'the file never closes';
	return qr/a '"' \Q$where\E on line $line opened a quoted field that \Q$end\E \(pass quote => '' if '"' is literal text in this file\)/;
}

# A filter that accepts every row sends the data rows through the perl
# callback instead of the XS fast path; every case is read both ways.
my @paths = ( [ 'fast', [] ], [ 'perl', [ filter => { 0 => sub { 1 } } ] ] );

# --- end of file inside a quoted field --------------------------------------

# test_unbalanced_quoting, balanced: pandas and R both give 1, 2, 3.
{
	my $f = fixture(qq{a,b,c\n1,2,"3"});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		is_deeply $got->{r}, [ { a => 1, b => 2, c => 3 } ],
			"test_unbalanced_quoting balanced ($p->[0])";
		is_deeply $got->{warn}, [], "... with no warning ($p->[0])";
	}
}

# test_unbalanced_quoting, unbalanced: pandas raises, R 4.6.1's read.csv
# returns no rows. read_table keeps the row and warns. The file has no final
# newline, so none is added to the cell (0.320 added one).
{
	my $f = fixture(qq{a,b,c\n1,2,"3});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		is_deeply $got->{r}, [ { a => 1, b => 2, c => 3 } ],
			"test_unbalanced_quoting unbalanced: the row is kept ($p->[0])";
		is scalar @{ $got->{warn} }, 1, "... with one warning ($p->[0])";
		like $got->{warn}[0],
			qr/\Aread_table: end of file inside a quoted field in \Q$f\E: ${\ note_re(2, 0) }\n\z/,
			"... naming line 2 ($p->[0])";
	}
}

# The same with a final newline: the newline is part of the file, so it is
# part of the cell.
{
	my $got = attempt(fixture(qq{a,b,c\n1,2,"3\n}));
	is_deeply $got->{r}, [ { a => 1, b => 2, c => "3\n" } ],
		'an unclosed quote keeps the final newline the file has';
	is scalar @{ $got->{warn} }, 1, '... and warns once';
}

# The 0.320 failure itself: one stray '"' and every later line is one cell.
{
	my $f   = fixture(qq{name,note\nann,"open\nbob,x\ncy,y\n});
	my $got = attempt($f);
	is_deeply $got->{r}, [ { name => 'ann', note => "open\nbob,x\ncy,y\n" } ],
		'an unclosed quote at the start of a field reads to the end of the file';
	is scalar @{ $got->{warn} }, 1, '... and is no longer silent';
	like $got->{warn}[0], note_re(2, 0), '... naming the line the quote opened on';
}

# IN_QUOTED_FIELD from test_eof_states: pandas raises "EOF inside string
# starting at row 2"; the lone '"' is also one field short of three.
{
	my $f = fixture(qq{a,b,c\n4,5,6\n"});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		is $got->{r}, undef, "IN_QUOTED_FIELD dies ($p->[0])";
		like $got->{err},
			qr/\AAlignment error on \Q$f\E data row 2 \(1 fields vs 3 headers\); ${\ note_re(3, 0) }\.\n\z/,
			"... and the alignment error says why ($p->[0])";
		is scalar @{ $got->{warn} }, 1, "... after the end-of-file warning ($p->[0])";
	}
}

# GH 62739 with sep ' ': pandas raises "unexpected end of data".
{
	my $f = fixture(qq{a b\n"\n1 3\n});
	for my $p (@paths) {
		my $got = attempt($f, sep => ' ', @{ $p->[1] });
		like $got->{err},
			qr/\AAlignment error on \Q$f\E data row 1 \(1 fields vs 2 headers\); ${\ note_re(2, 0) }\.\n\z/,
			"GH 62739: an unclosed quote on a line of its own ($p->[0])";
	}
}

# The regex separator finds quotes in its own branch of the parser.
{
	my $got = attempt(fixture(qq{a b\n1 "x\n}), sep => qr/\s+/);
	is_deeply $got->{r}, [ { a => 1, b => "x\n" } ], 'regex sep: an unclosed quote';
	like $got->{warn}[0], note_re(2, 0), '... is warned about in that branch too';
}

# --- quoted fields that legitimately run across lines -----------------------

# test_skip_row_with_newline_and_quote, all three inputs, every row; pandas
# 3.0.4 without skiprows gives exactly these. None is warned about.
{
	my @cases = (
		[ qq{id,text,num_lines\n1,"line \n'11' line 12",2\n2,"line \n'21' line 22",2\n3,"line \n'31' line 32",1},
		  [ "line \n'11' line 12", "line \n'21' line 22", "line \n'31' line 32" ] ],
		[ qq{id,text,num_lines\n1,"line '11\n' line 12",2\n2,"line '21\n' line 22",2\n3,"line '31\n' line 32",1},
		  [ "line '11\n' line 12", "line '21\n' line 22", "line '31\n' line 32" ] ],
		[ qq{id,text,num_lines\n1,"line '11\n' \r\tline 12",2\n2,"line '21\n' \r\tline 22",2\n3,"line '31\n' \r\tline 32",1},
		  [ "line '11\n' \r\tline 12", "line '21\n' \r\tline 22", "line '31\n' \r\tline 32" ] ],
	);
	for my $i (0 .. $#cases) {
		my ($text, $want) = @{ $cases[$i] };
		my $f = fixture($text);
		for my $p (@paths) {
			my $got = attempt($f, @{ $p->[1] });
			is_deeply $got->{r}, [
				{ id => 1, text => $want->[0], num_lines => 2 },
				{ id => 2, text => $want->[1], num_lines => 2 },
				{ id => 3, text => $want->[2], num_lines => 1 },
			], "test_skip_row_with_newline_and_quote input " . ($i + 1) . " ($p->[0])";
			is_deeply $got->{warn}, [], "... with no warning ($p->[0])";
		}
	}
}

# test_embedded_newline, header=None.
{
	my $got = attempt(fixture(qq{a\n"hello\nthere"\nthis}), header => 0);
	is_deeply $got->{r}, [ { V1 => 'a' }, { V1 => "hello\nthere" }, { V1 => 'this' } ],
		'test_embedded_newline';
	is_deeply $got->{warn}, [], '... with no warning';
}

# Blanks before the quote do not make it a mid-field one.
{
	my $got = attempt(fixture(qq{a,b\n1, "x\ny"\n}));
	is_deeply $got->{r}, [ { a => 1, b => " x\ny" } ],
		'a quote after a blank opens a field, and the blank is kept';
	is_deeply $got->{warn}, [], '... that may run across lines without a warning';
}

# test_data_after_quote: pandas and R both give "ba".
{
	my $got = attempt(fixture(qq{a\n1\n"b"a}));
	is_deeply $got->{r}, [ { a => 1 }, { a => 'ba' } ], 'test_data_after_quote';
	is_deeply $got->{warn}, [], '... with no warning';
}

# --- a quote in the middle of a field ---------------------------------------

# Inch marks. R 4.6.1 reads this exactly so: height "5'10,150\nbob,6'1", wt
# "180". pandas reads two rows, 5'10" and 6'1", keeping the '"' as text.
{
	my $f = fixture(qq{name,height,wt\nann,5'10",150\nbob,6'1",180\n});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		is_deeply $got->{r}, [ { name => 'ann', height => "5'10,150\nbob,6'1", wt => 180 } ],
			"inch marks: R's parse, divergence from pandas pinned ($p->[0])";
		is scalar @{ $got->{warn} }, 1, "... with one warning ($p->[0])";
		like $got->{warn}[0], qr/\Aread_table: \Q$f\E: ${\ note_re(2, 1, 3) }\n\z/,
			"... that says where ($p->[0])";
	}
}

# One warning per file, however many rows it happens in.
{
	my $got = attempt(fixture(qq{a,b\nx"1\n2",3\ny"4\n5",6\n}));
	is scalar @{ $got->{r} }, 2, 'two mid-field quotes that each run across a line';
	is scalar @{ $got->{warn} }, 1, '... are warned about once';
	like $got->{warn}[0], note_re(2, 1, 3), '... at the first of them';
}

# Unclosed, and misaligned: the alignment error carries the account.
{
	my $f = fixture(qq{name,height,wt\nann,5'10",150\nbob,6'1",180\ncy,5'2",120\n});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		like $got->{err},
			qr/\AAlignment error on \Q$f\E data row 2 \(2 fields vs 3 headers\); ${\ note_re(4, 1) }\.\n\z/,
			"an unclosed mid-field quote on the last row ($p->[0])";
	}
}

# Closed on the next line, but the row it made is too wide.
{
	my $f = fixture(qq{a,b\nx"1\n2",3,4\n});
	for my $p (@paths) {
		my $got = attempt($f, @{ $p->[1] });
		like $got->{err},
			qr/\AAlignment error on \Q$f\E data row 1 \(3 fields vs 2 headers\); ${\ note_re(2, 1, 3) }\.\n\z/,
			"a mid-field quote that misaligns its row ($p->[0])";
		is_deeply $got->{warn}, [], "... dies with the account instead of warning ($p->[0])";
	}
}

# Every output shape reaches the same message through the fast path.
for my $otype (qw(aoa hoa hoh)) {
	my $f   = fixture(qq{k,v\nr1,1\n"r2,2\n});
	my $got = attempt($f, 'output.type' => $otype);
	like $got->{err},
		qr/\AAlignment error on \Q$f\E data row 2 \(1 fields vs 2 headers\); ${\ note_re(3, 0) }\.\n\z/,
		"output.type $otype: the alignment error carries the account";
}

# The regex branch sees a mid-field quote too.
{
	my $got = attempt(fixture(qq{a b\nx"1\n2" 3\n}), sep => qr/ /);
	is_deeply $got->{r}, [ { a => "x1\n2", b => 3 } ], 'regex sep: a mid-field quote';
	like $got->{warn}[0], note_re(2, 1, 3), '... is warned about in that branch';
}

# test_skiprows_infield_quote without skiprows: R 4.6.1 names the column
# "a.b" (make.names of "a\nb") and reads rows "a" and "1"; pandas reads a
# column 'a"' with rows 'b"', 'a', '1'. read_table follows R, and the header
# row is warned about like any other.
{
	my $got = attempt(fixture(qq{a"\nb"\na\n1}));
	is_deeply $got->{r}, [ { "a\nb" => 'a' }, { "a\nb" => 1 } ],
		"test_skiprows_infield_quote: R's parse, divergence from pandas pinned";
	like $got->{warn}[0], note_re(1, 1, 2), '... and a warning about the header';
}

# R's reg-tests-1d.R case: a quote after '=' that closes on its own line is
# read as R reads it (t/read_table.header_quote.R.pandas.t pins the value)
# and is not warned about.
{
	my $got = attempt(fixture(qq{="Total\t"\t1\n}), sep => "\t", header => 0);
	is_deeply $got->{r}, [ { V1 => "=Total\t", V2 => 1 } ], 'reg-tests-1d: ="Total\t"';
	is_deeply $got->{warn}, [], '... with no warning';
}

# --- quote => '' on a quoted file -------------------------------------------

# R's write.csv() output. R 4.6.1 reads it as a = 1, 2 and b = x, y; with
# quote = "" as columns X.a. and X.b. (make.names of '"a"' and '"b"').
{
	my $f = fixture(qq{"a","b"\n1,"x"\n2,"y"\n});
	my $got = attempt($f);
	is_deeply $got->{r}, [ { a => 1, b => 'x' }, { a => 2, b => 'y' } ], 'write.csv output';
	is_deeply $got->{warn}, [], '... read with the default quote, without a warning';

	$got = attempt($f, quote => '');
	is_deeply $got->{r}, [ { '"a"' => 1, '"b"' => '"x"' }, { '"a"' => 2, '"b"' => '"y"' } ],
		"... read with quote => '' keeps every quote mark";
	is scalar @{ $got->{warn} }, 1, '... and warns once';
	like $got->{warn}[0],
		qr/\Aread_table: every field on the first line of \Q$f\E is wrapped in '"', and quote => '' keeps the quote marks as part of the text; leave 'quote' out to read them as quoting\n\z/,
		'... saying what to do';

	$got = attempt($f, quote => '', header => 0);
	is scalar @{ $got->{warn} }, 1, '... with header => 0 too';

	$got = attempt($f, quote => '"');
	is_deeply $got->{warn}, [], "quote => '\"' given explicitly: no warning";
}

# test_quoting_various, QUOTE_NONE: only some fields are quoted, so no warning.
{
	my $got = attempt(fixture(qq{1,2,"foo"}), quote => '', header => 0);
	is_deeply $got->{r}, [ { V1 => 1, V2 => 2, V3 => '"foo"' } ], 'test_quoting_various QUOTE_NONE';
	is_deeply $got->{warn}, [], '... with no warning';
}

# An .xlsx has no quoting to switch off, so quote => '' is not checked there.
{
	my $x = File::Spec->catfile($dir, 'quoted.xlsx');
	write_table([ { '"a"' => '"1"' } ], $x, 'row.names' => 0);
	my $got = attempt($x, quote => '');
	is_deeply $got->{r}, [ { '"a"' => '"1"' } ], 'xlsx with quoted cells';
	is_deeply $got->{warn}, [], "... and quote => '': no warning";
}

# --- a warning handler that dies ---------------------------------------------

# The warnings are raised from XS while the parser holds a row, a file handle
# and a plan; a __WARN__ handler that dies must unwind all of it cleanly.
{
	my $f = fixture(qq{a,b\nx"1\n2",3\n4,5\n});
	my $r = eval {
		local $SIG{__WARN__} = sub { die "promoted: $_[0]" };
		read_table($f);
	};
	like $@, qr/\Apromoted: read_table: /, 'a dying __WARN__ handler propagates';
	my $again = attempt($f);
	is_deeply $again->{r}, [ { a => "x1\n2", b => 3 }, { a => 4, b => 5 } ],
		'... and the next read of the file is unaffected';
	is scalar @{ $again->{warn} }, 1, '... and warns again';
}

# --- leaks --------------------------------------------------------------------

# Each new message is made from mortal SVs while the parser holds a row, a file
# handle and a plan: once through each warning and each croak, on both paths.
SKIP: {
	skip 'Test::LeakTrace not installed', 7 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 7 if $INC{'Devel/Cover.pm'};
	my $eof   = fixture(qq{a,b,c\n1,2,"3\n});
	my $mid   = fixture(qq{a,b\nx"1\n2",3\n4,5\n});
	my $align = fixture(qq{a,b\nx"1\n2",3,4\n});
	my $quoted = fixture(qq{"a","b"\n1,"x"\n});
	no_leaks_ok { local $SIG{__WARN__} = sub { }; read_table($eof) }
		'no leaks: end-of-file warning';
	no_leaks_ok { local $SIG{__WARN__} = sub { }; read_table($mid) }
		'no leaks: mid-field warning';
	no_leaks_ok { local $SIG{__WARN__} = sub { }; read_table($mid, @{ $paths[1][1] }) }
		'no leaks: mid-field warning through the closure';
	no_leaks_ok { eval { read_table($align) } }
		'no leaks: alignment error with the account, fast path';
	no_leaks_ok { eval { read_table($align, @{ $paths[1][1] }) } }
		'no leaks: alignment error with the account, through the closure';
	no_leaks_ok { local $SIG{__WARN__} = sub { die $_[0] }; eval { read_table($mid) } }
		'no leaks: a __WARN__ handler that dies';
	no_leaks_ok { local $SIG{__WARN__} = sub { }; read_table($quoted, quote => '') }
		"no leaks: the quote => '' warning";
}

done_testing;
