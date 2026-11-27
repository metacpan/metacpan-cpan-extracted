#!/usr/bin/env perl

# Writes the __DATA__ section of t/read_table.ods.pandas.t and
# t/read_table.skiprows.pandas.t: the XML of pandas' own spreadsheet fixtures,
# which pandas' wheel does not ship, so that the tests can rebuild each
# workbook and read it.  The tests never run this.
#
# The fixtures are pandas 3.0.4's, pandas/tests/io/data/excel/ at the git tag
# v3.0.4 (https://github.com/pandas-dev/pandas/tree/v3.0.4/pandas/tests/io/data/excel).
# Run, from the worktree root, with DIR holding those files:
#
#   perl t/read_table.pandas.fixtures.pl DIR test_spaces.ods gh-35802.ods ...
#
# naming the files the test's header comment lists, in its order, and replace
# everything after the test's __DATA__ line with the output.
#
# Of an .ods, it keeps content.xml, the only part read_table reads, less its
# <office:font-face-decls>, <office:automatic-styles> and <office:scripts>,
# which are styling and macros and hold no cell.  Of an .xlsx, it keeps the
# package's relationships, the workbook, the shared strings and every
# worksheet, and leaves out the theme, the styles and docProps.  Everything it
# keeps is byte for byte the file's.
#
# Each part is written as a line "=== FILE PART" followed by the part's bytes
# and one "\n", which the test strips.

require 5.010;
use strict;
use warnings FATAL => 'all';
use IO::Uncompress::Unzip qw(unzip $UnzipError);

my ($dir, @files) = @ARGV;
die "usage: $0 DIR FILE...\n" unless defined $dir && @files;
binmode STDOUT;
for my $f (@files) {
	my $path = "$dir/$f";
	my $z = IO::Uncompress::Unzip->new($path) or die "$path: $UnzipError\n";
	my @names;
	for (my $st = 1; $st > 0; $st = $z->nextStream) {
		push @names, $z->getHeaderInfo->{Name};
	}
	$z->close;
	my @keep = $f =~ /\.ods\z/
		? grep { $_ eq 'content.xml' } @names
		: grep { m{\A(?:\[Content_Types\]\.xml|_rels/\.rels|xl/workbook\.xml|xl/_rels/workbook\.xml\.rels|xl/sharedStrings\.xml|xl/worksheets/[^/]+\.xml)\z} } @names;
	die "$path: nothing to keep\n" unless @keep;
	for my $part (sort @keep) {
		my $x;
		unzip($path => \$x, Name => $part) or die "$path $part: $UnzipError\n";
		if ($part eq 'content.xml') {
			$x =~ s{<office:(font-face-decls|automatic-styles|scripts)\b(?:/>|.*?</office:\1>)}{}gs;
		}
		die "$path $part: a line starts with '=== '\n" if $x =~ /^=== /m;
		print "=== $f $part\n$x\n";
	}
}
