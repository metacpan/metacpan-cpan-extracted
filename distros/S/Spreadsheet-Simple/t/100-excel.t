#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1 + 7*2;
use Test::Exception;

BEGIN { use_ok "Spreadsheet::Simple::Reader::Excel" }

my $reader = Spreadsheet::Simple::Reader::Excel->new;
my @files  = (
	't/data/100-excel.xls',
	't/data/100-excel2.xls',
);

foreach my $file (@files) {
	my $doc    = $reader->read_file($file);

	ok($doc, "doc is defined");

	isa_ok($doc, 'Spreadsheet::Simple::Document');

	my $sheet = $doc->get_sheet_by_name('sheet1');

	ok($sheet, "sheet is defined");
	isa_ok($sheet, 'Spreadsheet::Simple::Sheet');

	is($sheet->get_cell(0, 0)->value, 'foo', 'A1');
	is($sheet->get_cell(0, 1)->value, 'bar', 'B1');
	is($sheet->get_cell(0, 2)->value, 'baz', 'C1');
}


