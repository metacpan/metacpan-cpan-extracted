#!/usr/bin/env perl
# read_table and a UTF-8 byte-order mark at the start of a CSV.
#
# Excel's "CSV UTF-8" export starts the file with EF BB BF, and until 0.319
# those three bytes were read as part of the first header name: a column
# written as "id" came back as "\xEF\xBB\xBFid", so $row->{id} was undef on
# every row and nothing said why. The mark is now dropped from the first
# physical line, and from nowhere else.
#
# Provenance. The cases are pandas' own, from pandas 2.2.3
# (/home/con/.local/lib/python3.12/site-packages/pandas):
#
#   tests/io/parser/test_encoding.py, test_utf8_bom (gh-4793), whose parameters
#     ("a\n1", {})                      -> DataFrame({"a": [1]})
#     ('"a"\n1', {"quotechar": '"'})    -> DataFrame({"a": [1]})
#     ("\n1", {"names": ["a"], "skip_blank_lines": True})
#                                       -> DataFrame({"a": [1]})
#   are each prefixed with "﻿" and encoded as UTF-8.
#   tests/io/parser/common/test_common_basic.py, test_first_row_bom
#   (gh-26545) and test_first_row_bom_unquoted (gh-36343):
#     '﻿"Head1"\t"Head2"\t"Head3"' and "﻿Head1\tHead2\tHead3", with
#     delimiter="\t", give columns ["Head1", "Head2", "Head3"] and no rows.
#
# Two adaptations, both forced by read_table having no 'names' option and
# always taking the first non-blank line as the header:
#   * the skip_blank_lines case supplies its header on the line after the
#     BOM-only one, instead of through names=, so what is checked is the part
#     that case is about -- that a line holding nothing but the mark is blank;
#   * the header-only cases are read through _parse_csv_file() with no
#     callback, which returns the rows it cut as arrays, because read_table
#     returns [] for a header-only file and so cannot show the column names.
#
# pandas reads 1 as an integer; read_table returns every cell as the string
# the file holds, which is_deeply compares equal to it.
#
# The rest -- the mark in front of a comment line and of a commented-out
# header, a mark that is not at the start of the file, and every output shape
# on both of read_table's paths -- is this module's own surface, not
# pandas', and its expected values are the fixtures themselves.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $seq = 0;
my $BOM = "\xEF\xBB\xBF";

sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'f' . $seq++ . ($ext // '.csv'));
	open my $fh, '>:raw', $path or die "cannot write \"$path\": $!\n";
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# test_utf8_bom
is_deeply read_table(fixture("${BOM}a\n1")), [ { a => 1 } ],
	'test_utf8_bom: basic';
is_deeply read_table(fixture(qq{${BOM}"a"\n1})), [ { a => 1 } ],
	'test_utf8_bom: quoted header';
is_deeply read_table(fixture("${BOM}\na\n1")), [ { a => 1 } ],
	'test_utf8_bom: a line holding only the mark is blank, and skipped';

# test_first_row_bom, test_first_row_bom_unquoted
is_deeply Stats::LikeR::_parse_csv_file(
		fixture(qq{${BOM}"Head1"\t"Head2"\t"Head3"}), "\t", ''),
	[ [ 'Head1', 'Head2', 'Head3' ] ],
	'test_first_row_bom: quoted header';
is_deeply Stats::LikeR::_parse_csv_file(
		fixture("${BOM}Head1\tHead2\tHead3"), "\t", ''),
	[ [ 'Head1', 'Head2', 'Head3' ] ],
	'test_first_row_bom_unquoted';

# A comment line is recognised behind the mark, so it is skipped rather than
# becoming a header whose first name starts with it.
is_deeply read_table(fixture("$BOM# written by Excel\na,b\n1,2\n")),
	[ { a => 1, b => 2 } ], 'a comment line behind the mark is still a comment';

# The commented-out header ("# a<TAB>b") is recovered by a separate read of the
# first line in perl, which has to drop the mark too.
is_deeply read_table(fixture("$BOM# a\tb\n1\t2\n", '.tsv')),
	[ { a => 1, b => 2 } ], 'a commented-out header behind the mark';

# Only the start of the file: the same bytes anywhere else are data.
is_deeply read_table(fixture("a,b\n${BOM}1,2\n")),
	[ { a => "${BOM}1", b => 2 } ], 'the mark on a later line is data';

# Every shape, on the fast path and through the per-row closure.
{
	my $f = fixture("${BOM}id,v\r\nx,1\r\ny,2\r\n");
	my %want = (
		aoh => [ { id => 'x', v => 1 }, { id => 'y', v => 2 } ],
		hoa => { id => [ 'x', 'y' ], v => [ 1, 2 ] },
		hoh => { x => { v => 1 }, y => { v => 2 } },
	);
	for my $otype (qw(aoh hoa hoh)) {
		is_deeply read_table($f, 'output.type' => $otype), $want{$otype},
			"$otype, fast path";
		is_deeply read_table($f, 'output.type' => $otype,
				filter => { 0 => sub { 1 } }),
			$want{$otype}, "$otype, per-row closure";
	}
}

done_testing;
