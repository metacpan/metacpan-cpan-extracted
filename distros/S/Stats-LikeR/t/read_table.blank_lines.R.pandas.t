#!/usr/bin/env perl
# read_table and lines that hold nothing but blanks.
#
# A blank line is skipped, as R's read.table (blank.lines.skip = TRUE) and
# pandas' read_csv (skip_blank_lines=True) both skip one. A line whose blanks
# are the separator is not blank, though: a tab-separated "\t" is a row of two
# empty fields, and both references read it as a row of NA. Up to 0.320
# read_table dropped it, so a TSV row with every cell empty went missing with
# no word said and the row count no longer matched R's or pandas'.
#
# Provenance, pandas 3.0.4
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas),
# tests/io/parser/common/test_common_basic.py:
#
#   test_empty_lines, the skip_blank_lines=True parameters for sep="," and
#     sep=r"\s+" (the second replaces each "," with two spaces, as the test
#     does). skip_blank_lines=False has no read_table equivalent.
#   test_whitespace_lines: blank lines of spaces and tabs ahead of the header,
#     with sep=",".
#
# The remaining inputs -- lines made of separators only, with LF, CRLF and no
# final newline, a one-column file, and blanks that are not the separator --
# are carried by neither suite, and are here because they are the ones 0.320
# got wrong or the ones next to them.
#
# Every expected value is pandas 3.0.4's, read with dtype=str (so nothing is
# converted, and an empty cell is nan, which is undef here), frozen from
# t/read_table.blank_lines.pandas.py; run it with
# `python3 t/read_table.blank_lines.pandas.py` from the distribution root.
#
# Provenance, R 4.6.1 (/home/con/Scripts/r-source): R's reading of the same
# inputs is frozen from t/read_table.blank_lines.R; run it with
# `Rscript t/read_table.blank_lines.R`. R agrees with pandas on every input but
# two, and the comment at each of those says what R does instead.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n   = 0;

sub fixture {
	my ($text) = @_;
	my $path = File::Spec->catfile($dir, 'in' . $n++ . '.txt');
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# Compiled once, here: 5.10.0's pp_qr() leaks an SV per qr// evaluated.
my $ws  = qr/\s+/;
my $tab = qr/\t/;

# (label, text, sep, qr// equivalent of sep or undef, expected rows)
my @cases = (
	[ 'test_empty_lines ,', "A,B,C\n1,2.,4.\n\n\n5.,NaN,10.0\n\n-70,.4,1\n", ',', undef,
		[ { A => '1', B => '2.', C => '4.' }, { A => '5.', B => 'NaN', C => '10.0' },
		  { A => '-70', B => '.4', C => '1' } ] ],
	# pandas reads the "NaN" as missing under dtype=str; na.strings is off by
	# default here, and R's default "NA" does not match it either, so it is
	# R's "NaN" string that is pinned (above and below)
	[ 'test_empty_lines \s+', "A  B  C\n1  2.  4.\n\n\n5.  NaN  10.0\n\n-70  .4  1\n", $ws, $ws,
		[ { A => '1', B => '2.', C => '4.' }, { A => '5.', B => 'NaN', C => '10.0' },
		  { A => '-70', B => '.4', C => '1' } ] ],
	# R 4.6.1 errors ("more columns than column names"): it does not count a
	# line of blanks as blank when the separator is not a blank
	[ 'test_whitespace_lines', "\n\n\t  \t\t\n\t\nA,B,C\n\t    1,2.,4.\n5.,NaN,10.0\n", ',', undef,
		[ { A => "\t    1", B => '2.', C => '4.' }, { A => '5.', B => 'NaN', C => '10.0' } ] ],
	[ 'tab row', "a\tb\n1\t2\n\t\n3\t4\n", "\t", $tab,
		[ { a => '1', b => '2' }, { a => undef, b => undef }, { a => '3', b => '4' } ] ],
	[ 'tab row x3', "a\tb\tc\n1\t2\t3\n\t\t\n4\t5\t6\n", "\t", $tab,
		[ { a => '1', b => '2', c => '3' }, { a => undef, b => undef, c => undef },
		  { a => '4', b => '5', c => '6' } ] ],
	[ 'tab row crlf', "a\tb\r\n1\t2\r\n\t\r\n3\t4\r\n", "\t", $tab,
		[ { a => '1', b => '2' }, { a => undef, b => undef }, { a => '3', b => '4' } ] ],
	[ 'tab row last', "a\tb\n1\t2\n\t", "\t", $tab,
		[ { a => '1', b => '2' }, { a => undef, b => undef } ] ],
	[ 'comma row', "a,b\n1,2\n,\n3,4\n", ',', undef,
		[ { a => '1', b => '2' }, { a => undef, b => undef }, { a => '3', b => '4' } ] ],
	[ 'space row', "a b\n1 2\n \n3 4\n", ' ', undef,
		[ { a => '1', b => '2' }, { a => undef, b => undef }, { a => '3', b => '4' } ] ],
	# R 4.6.1 errors ("line 2 did not have 2 elements"); pandas skips the line
	[ 'spaces under tab', "a\tb\n1\t2\n  \n3\t4\n", "\t", $tab,
		[ { a => '1', b => '2' }, { a => '3', b => '4' } ] ],
	[ 'one column', "a\n1\n\n2\n", "\t", $tab,
		[ { a => '1' }, { a => '2' } ] ],
);

for my $c (@cases) {
	my ($label, $text, $sep, $re, $want) = @$c;
	my $f = fixture($text);
	for my $s (defined $re ? ($sep, $re) : ($sep)) {
		my $how = ref $s ? 'regex sep' : 'literal sep';
		is_deeply read_table($f, sep => $s), $want, "$label ($how)";
		is_deeply read_table($f, sep => $s, filter => { 0 => sub { 1 } }), $want,
			"$label ($how, through a filter)";
		# an aoa is the shape that shows a dropped row most plainly
		my $aoa = read_table($f, sep => $s, 'output.type' => 'aoa');
		is scalar(@$aoa) - 1, scalar(@$want), "$label ($how, aoa): the row count";
	}
}

# A qr// separator that could match an empty string but finds no separator on
# a line of blanks leaves the line blank, rather than taking the empty match as
# one; qr/\s+/ never makes a field out of blanks at all.
{
	my $f = fixture("a,b\n1,2\n  \n3,4\n");
	my $re = qr/\s*,\s*/;
	is_deeply read_table($f, sep => $re),
		[ { a => '1', b => '2' }, { a => '3', b => '4' } ],
		'a regex sep that does not match a line of blanks leaves it blank';
	$f = fixture("a b\n1 2\n \t \n3 4\n");
	is_deeply read_table($f, sep => $ws),
		[ { a => '1', b => '2' }, { a => '3', b => '4' } ],
		'qr/\s+/ skips a line of blanks, as pandas\' delim_whitespace does';
}

# header => 0: the row of separators is data like any other.
{
	my $f = fixture("1\t2\n\t\n3\t4\n");
	is_deeply read_table($f, header => 0, sep => "\t", 'output.type' => 'aoa'),
		[ [qw(V1 V2)], [1, 2], [undef, undef], [3, 4] ],
		'header => 0: a row of separators is a row';
}

done_testing;
