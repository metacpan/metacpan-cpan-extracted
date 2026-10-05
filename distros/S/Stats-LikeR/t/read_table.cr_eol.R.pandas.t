#!/usr/bin/env perl
# read_table and files whose lines end in a bare CR, as classic Mac OS wrote
# them.
#
# R's scan() and pandas' C tokenizer both take a lone CR as a line end. Up to
# 0.3213 read_table split on LF only, so such a file was one line, every CR in it
# was dropped as a stray, and the table came back as [] with no word said. It
# now looks at the start of the file (_eol_is_cr() in LikeR.pm), and one with a
# CR and no LF at all is split on CR.
#
# Provenance, pandas 3.0.4
# (/home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas):
#
#   tests/io/parser/test_textreader.py, TestTextReader.test_cr_delimited: its
#     six texts, delim_whitespace=True being sep => qr/\s+/ here. pandas checks
#     that each reads as its CRLF twin does; so does this, and it also pins
#     what both read as.
#   tests/io/parser/test_c_parser_only.py, test_tokenize_CR_with_quoting, gh-3453,
#     with header=None (header => 0 here) and with the default header.
#
# The expected values are pandas', read with dtype=str and keep_default_na=False
# so nothing is converted (an empty cell, "" there, is undef here), frozen from
# t/read_table.cr_eol.pandas.py; run it with `python3 t/read_table.cr_eol.pandas.py`
# from the distribution root. Two of test_cr_delimited's texts have a row one
# field short, which pandas pads and read_table refuses by design (the
# "Alignment error"); for those, the CR text and its CRLF twin must fail the same
# way.
#
# Provenance, R 4.6.1 (/home/con/Scripts/r-source): tests/reg-tests-1a.R,
# PR#2469, "read.table on Mac OS CR-terminated files": c("aaa", "bbb", "ccc")
# written with sep = "\r" and no final line end reads back as those three lines.
# read.table("that file") in R 4.6.1 gives V1 = aaa, bbb, ccc.
#
# The rest -- a compressed CR file, a commented-out header, a quoted field that
# runs over a line end, a regex sep, and where the start-of-file test draws its
# lines -- are carried by neither suite and are here because they are what
# _eol_is_cr() and the parser's cr_eol mode have to get right.
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
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'in' . $n++ . ($ext // '.csv'));
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# The error with its file name taken out, so a CR file and its CRLF twin can be
# compared; '' when the read succeeds.
sub read_err {
	my ($path, @opt) = @_;
	my $r = eval { read_table($path, @opt); 1 } ? '' : $@;
	$r =~ s/\Q$path\E/FILE/g;
	return $r;
}

# Compiled once, here: 5.10.0's pp_qr() leaks an SV per qr// evaluated.
my $ws = qr/\s+/;

# --- pandas' cases ----------------------------------------------------------

my $zeros = [ ('0') x 13 ];
# (label, text, read_table options, expected aoa or undef = refused as ragged)
my @pandas = (
	[ 'test_cr_delimited, sep=","',
	  "a,b,c\r1,2,3\r4,5,6\r7,8,9\r10,11,12", [],
	  [ [qw(a b c)], [1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12] ] ],
	[ 'test_cr_delimited, whitespace',
	  "a  b  c\r1  2  3\r4  5  6\r7  8  9\r10  11  12", [ sep => $ws ],
	  [ [qw(a b c)], [1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12] ] ],
	[ 'test_cr_delimited, an empty first field',
	  "a,b,c\r1,2,3\r4,5,6\r,88,9\r10,11,12", [],
	  [ [qw(a b c)], [1, 2, 3], [4, 5, 6], [undef, 88, 9], [10, 11, 12] ] ],
	[ 'test_cr_delimited, 15 columns',
	  "A,B,C,D,E,F,G,H,I,J,K,L,M,N,O\r"
	  . "AAAAA,BBBBB,0,0,0,0,0,0,0,0,0,0,0,0,0\r"
	  . ",BBBBB,0,0,0,0,0,0,0,0,0,0,0,0,0", [],
	  [ [ 'A' .. 'O' ], [ 'AAAAA', 'BBBBB', @$zeros ], [ undef, 'BBBBB', @$zeros ] ] ],
	# pandas: [['2', '3', ''], ['4', '5', '6']], padding the short row
	[ 'test_cr_delimited, whitespace, an indented short row',
	  "A  B  C\r  2  3\r4  5  6", [ sep => $ws ], undef ],
	[ 'test_cr_delimited, whitespace, a short row',
	  "A B C\r2 3\r4 5 6", [ sep => $ws ], undef ],
	[ 'test_tokenize_CR_with_quoting, header=None',
	  qq{ a,b,c\r"a,b","e,d","f,f"}, [ header => 0 ],
	  [ [qw(V1 V2 V3)], [ ' a', 'b', 'c' ], [ 'a,b', 'e,d', 'f,f' ] ] ],
	[ 'test_tokenize_CR_with_quoting, header',
	  qq{ a,b,c\r"a,b","e,d","f,f"}, [],
	  [ [ ' a', 'b', 'c' ], [ 'a,b', 'e,d', 'f,f' ] ] ],
);

for my $c (@pandas) {
	my ($label, $text, $opt, $want) = @$c;
	my $cr   = fixture($text);
	(my $crlf_text = $text) =~ s/\r/\r\n/g;
	my $crlf = fixture($crlf_text);
	my @o = (@$opt, 'output_type' => 'aoa');
	if ($want) {
		is_deeply read_table($cr, @o), $want, "$label: as pandas reads it";
		is_deeply read_table($crlf, @o), $want, "$label: and its CRLF twin";
	} else {
		my $e = read_err($cr, @o);
		like $e, qr/^Alignment error on FILE data row 1 \(2 fields vs 3 headers\)/,
			"$label: refused as ragged";
		is $e, read_err($crlf, @o), "$label: as its CRLF twin is";
	}
}

# --- R's case ---------------------------------------------------------------

is_deeply read_table(fixture("aaa\rbbb\rccc"), header => 0, 'output_type' => 'hoa'),
	{ V1 => [qw(aaa bbb ccc)] }, 'R PR#2469: three CR-terminated lines';

# --- the rest of read_table's surface --------------------------------------

is_deeply read_table(fixture("id,v\r1,2\r3,4\r")),
	[ { id => 1, v => 2 }, { id => 3, v => 4 } ], 'a final CR ends the last line';
for my $o (qw(aoh hoa hoh)) {
	my $want = read_table(fixture("id,v\n1,2\n3,4\n"), 'output_type' => $o);
	is_deeply read_table(fixture("id,v\r1,2\r3,4\r"), 'output_type' => $o), $want,
		"output_type $o reads a CR file as its LF twin";
	is_deeply read_table(fixture("id,v\r1,2\r3,4\r"), 'output_type' => $o,
			filter => sub { 1 }), $want,
		"output_type $o, through the filter path";
}
is_deeply read_table(fixture("a\tb\r1\t2\r"), sep => "\t"), [ { a => 1, b => 2 } ],
	'a tab-separated CR file';
is_deeply read_table(fixture("a;b\r1;2\r"), sep => qr/;/), [ { a => 1, b => 2 } ],
	'a regex separator';
is_deeply read_table(fixture("# comment\r\rid,v\r# mid\r1,2\r")),
	[ { id => 1, v => 2 } ], 'comment and blank lines are skipped';
is_deeply read_table(fixture("# id\tv\r1\t2\r"), sep => "\t"), [ { id => 1, v => 2 } ],
	'a commented-out header is recovered';
is_deeply read_table(fixture("\xEF\xBB\xBFid,v\r1,2\r")), [ { id => 1, v => 2 } ],
	'a byte-order mark is dropped';
# The CR inside the quotes is a line end of the file, so it comes back as the
# "\n" a quoted LF or CRLF line break does.
is_deeply read_table(fixture(qq{id,v\r1,"x\ry"\r2,z\r})),
	[ { id => 1, v => "x\ny" }, { id => 2, v => 'z' } ],
	'a quoted field that runs over a line end';
is_deeply read_table(fixture("id,v\r1,NA\r"), 'na_strings' => 'NA'),
	[ { id => 1, v => undef } ], 'na_strings';

SKIP: {
	skip 'IO::Compress::Gzip is not installed', 1
		unless eval { require IO::Compress::Gzip; 1 };
	my $gz = File::Spec->catfile($dir, 'cr.csv.gz');
	my $text = "id,v\r1,2\r3,4\r";
	no warnings 'once';	# $GzipError is named only here
	IO::Compress::Gzip::gzip(\$text => $gz)
		or die "gzip failed: $IO::Compress::Gzip::GzipError\n";
	is_deeply read_table($gz), [ { id => 1, v => 2 }, { id => 3, v => 4 } ],
		'a gzip-compressed CR file';
}

# --- where the start-of-file test draws its lines --------------------------

# A file with LF line ends keeps reading a stray CR as noise, as it always has.
is_deeply read_table(fixture("a,b\n1\r,2\n")), [ { a => 1, b => 2 } ],
	'an LF file with a stray CR is still LF';
is_deeply read_table(fixture("a\r,b\n1,2\n")), [ { a => 1, b => 2 } ],
	'a CR before the first LF does not make it a CR file';
# 65,535 bytes then CRLF: the first 64 KB read ends on the CR, and the LF after
# it is in the next one. _eol_is_cr() reads on rather than call it a CR file.
{
	my $name = 'x' x 65533;	# + ",y" = 65,535 bytes before the CRLF
	my $r = read_table(fixture("$name,y\r\n1,2\r\n"));
	is_deeply $r, [ { $name => 1, y => 2 } ], 'a CRLF split across the first read';
}
# A first line longer than one read is still found to end in a CR.
{
	my $name = 'x' x 70000;
	is_deeply read_table(fixture("$name,y\r1,2\r")), [ { $name => 1, y => 2 } ],
		'a CR file whose first line is longer than 64 KB';
}

done_testing();
