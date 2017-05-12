#!/usr/bin/perl -w

use Test::More;

eval { require Spreadsheet::WriteExcel };
plan skip_all => "Need Spreadsheet::WriteExcel for this test" if $@;

plan tests => 2;

use strict;
use Spreadsheet::ParseExcel::Simple;

my $workbook   = Spreadsheet::WriteExcel->new("test.xls");
my $worksheet1 = $workbook->add_worksheet();
my $worksheet2 = $workbook->add_worksheet();

$worksheet1->write('A1', 'Hello'); # 1 row

$worksheet2->write('A1', 'Hello'); # 2 rows
$worksheet2->write('A2', 'Hello');

$workbook->close();

my $xls = Spreadsheet::ParseExcel::Simple->read('test.xls');

for my $sheet ($xls->sheets) {
	ok $sheet->has_data, "Sheet $sheet->{sheet}->{Name} has data";
}
