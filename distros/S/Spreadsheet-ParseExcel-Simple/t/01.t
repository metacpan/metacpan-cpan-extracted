#!/usr/bin/perl -w

use strict;
use Spreadsheet::ParseExcel::Simple;
use Test::More;

BEGIN {
	eval "use File::Temp; use Spreadsheet::WriteExcel::Simple 1.03";
	plan $@
		? (skip_all =>
			'tests need Spreadsheet::WriteExcel::Simple 1.03 + File::Temp')
		: (tests => 11);
}

File::Temp->import(qw/tempfile tempdir/);
my $dir1 = tempdir(CLEANUP => 1);
my ($fh1, $name1) = tempfile(DIR => $dir1);

my @row1 = qw/foo bar baz/;
my @row2 = qw/1 fred 2001-01-01/;
my @row3 = ();
my @row4 = (2, undef, "2001-03-01");

# Write our our test file.
my $ss = Spreadsheet::WriteExcel::Simple->new;
$ss->write_bold_row(\@row1);
$ss->write_row(\@row2);
$ss->write_row(\@row3);
$ss->write_row(\@row4);
$ss->save($name1);

# Now read it back in
my $xls    = Spreadsheet::ParseExcel::Simple->read($name1);
my @sheets = $xls->sheets;
is scalar @sheets, 1, "We have one sheet";
my $sheet = $sheets[0];

ok $sheet->has_data, "We have data to read";
my @fetch1 = $sheet->next_row;
is_deeply \@fetch1, \@row1, "Header OK";

ok $sheet->has_data, "We still have data to read";
my @fetch2 = $sheet->next_row;
is_deeply \@fetch2, \@row2, "Row 2";

ok $sheet->has_data, "We still have data to read";
my @fetch3 = $sheet->next_row;
is_deeply \@fetch3, \@row3, "Row 3 (blank)";

ok $sheet->has_data, "We still have data to read";
my @fetch4 = $sheet->next_row;
local $row4[1] = "";    # undefs come back as empty string
is_deeply \@fetch4, \@row4, "Row 4";

ok !$sheet->has_data, "No more data to read";
ok !$sheet->next_row, "So, can't read any";
