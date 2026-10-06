#!/usr/bin/env perl
# read_table: a quoted field is never a comment, nor a blank line.
#
# A line whose first field starts with the comment marker and hugs it ("#a,b")
# is read as a commented-out header (read_table's $finalize_header). Up to
# 0.3213 that rule looked at the field's text alone, so a header written
# '"#a",b' came back as a column named a, and where the line after it was text
# as well, the quoted header was dropped and that line was taken for the header
# in its place. The parser now tells the row closure when a row's first field
# was quoted (S_emit_row() in LikeR.xs), and such a field is text.
#
# This is also the read half of write_table's quoting: a first field that
# starts with '#', and a record whose only field is empty or blanks, are
# written in '"' so that they read back as the rows they were.
#
# Provenance, R. R's ?scan (src/library/base/man/scan.Rd, R 4.6.1): "If
# comment.char occurs (except inside a quoted character field), it signals
# that the rest of the line should be regarded as a comment". R's own suite
# has no case of a quoted field starting with the comment character, so the
# inputs are written here; every expected value is the output of R 4.6.1
# itself on that input, read.table(text = ..., colClasses = "character",
# check.names = FALSE), frozen from dput(). The generator is
# t/read_table.quoted_comment.R next to this file; run it with
# `Rscript t/read_table.quoted_comment.R` from the distribution root and copy
# what it prints into the table below. The test never runs it.
#
# Provenance, pandas 3.0.4: read_csv(dtype=str, keep_default_na=False), with
# and without comment="#", gives {'#a': ['1'], 'b': ['2']} for Q1 and
# {'a': ['', '  ', '1']} for Q9. pandas' suite pins neither (tests/io/parser/
# test_comment.py has no quoted comment character); they were run by hand.
#
# Divergences, each deliberate:
#
#   * Q9: R drops the record '""' as if it were a blank line; pandas keeps it,
#     and so does read_table, as undef (an empty field is undef here), since
#     write_table writes an empty one-field record exactly so.
#   * R's default sep = "" is read as qr/\s+/ (Q8), as in
#     t/read_table.header_quote.R.pandas.t.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fixture {
	my ($text) = @_;
	my $path = File::Spec->catfile($dir, 'q' . $n++ . '.csv');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}

my $ws = qr/\s+/;	# compiled once, outside any block a leak test could wrap
# [tag, file text, read_table options, expected aoa: the header row, then the data]
my @case = (
	['Q1 quoted #a header',         qq{"#a",b\n1,2\n},           [],             [['#a', 'b'], ['1', '2']]],
	["Q2 quoted '# a' header",      qq{"# a",b\n1,2\n},          [],             [['# a', 'b'], ['1', '2']]],
	['Q3 one quoted #a column',     qq{"#a"\nx\ny\n},            [],             [['#a'], ['x'], ['y']]],
	['Q4 comment, quoted header',   qq{#x,y\n"#a",b\nfoo,bar\n}, [],             [['#a', 'b'], ['foo', 'bar']]],
	['Q5 quoted # data',            qq{a,b\n"#x",2\n"# y",3\n},  [],             [['a', 'b'], ['#x', '2'], ['# y', '3']]],
	['Q6 quoted # data, no header', qq{"#x",2\n"# y",3\n},       [header => 0],  [['V1', 'V2'], ['#x', '2'], ['# y', '3']]],
	['Q7 tab',                      qq{"#a"\t"b"\nx\ty\n},       [sep => "\t"],  [['#a', 'b'], ['x', 'y']]],
	['Q8 whitespace',               qq{"#a" b\n1 2\n},           [sep => $ws],   [['#a', 'b'], ['1', '2']]],
	['Q9 quoted empty and blank',   qq{a\n""\n"  "\n1\n},        [],             [['a'], [undef], ['  '], ['1']]],
	['Q10 quoted blank header',     qq{"  "\n1\n},               [],             [['  '], ['1']]],
	["Q11 quoted '#' alone",        qq{a\n"#"\n"# z"\n},         [],             [['a'], ['#'], ['# z']]],
);

for my $c (@case) {
	my ($tag, $text, $opt, $want) = @$c;
	my $f = fixture($text);
	for my $way ('parser', 'closure') {
		my @w;
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		my @extra = $way eq 'closure' ? (_closure => 1) : ();
		is_deeply(read_table($f, @$opt, output_type => 'aoa', @extra), $want, "$tag: aoa ($way)");
		my @names = @{ $want->[0] };
		my @aoh = map { my $r = $_; +{ map { $names[$_] => $r->[$_] } 0 .. $#names } } @{$want}[1 .. $#$want];
		is_deeply(read_table($f, @$opt, output_type => 'aoh', @extra), \@aoh, "$tag: aoh ($way)");
		is_deeply(\@w, [], "$tag: no warning ($way)");
	}
}

# --- what has not changed ---------------------------------------------------------
# An unquoted "#a,b" is still a commented-out header, and an unquoted "# x" line
# still a comment.
is_deeply(read_table(fixture("#a,b\n1,2\n"), output_type => 'aoa'), [['a', 'b'], ['1', '2']],
          'an unquoted #a,b is still read as a commented-out header');
is_deeply(read_table(fixture("a,b\n# note\n1,2\n"), output_type => 'aoa'), [['a', 'b'], ['1', '2']],
          'an unquoted "# note" line is still a comment');
# A quote that opens after the marker is not a quoted field: #"a" is the text #a,
# and the line is a commented-out header as before.
is_deeply(read_table(fixture(qq{#"a",b\n1,2\n}), output_type => 'aoa'), [['a', 'b'], ['1', '2']],
          'a quote after the marker leaves the line a commented-out header');

done_testing();
