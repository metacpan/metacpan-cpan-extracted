#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1 + 7*4;
use Test::Exception;
use Path::Class 'file';

BEGIN { use_ok "Spreadsheet::Simple" }

my $ss = Spreadsheet::Simple->new( format => 'Excel' );

my @files  = (
	't/data/100-excel.xls',
	't/data/100-excel2.xls',
	file('t/data/100-excel.xls'),
	file('t/data/100-excel2.xls'),
);

foreach my $file (@files) {
	my $doc    = $ss->read_file($file);

	ok($doc, "doc is defined");

	isa_ok($doc, 'Spreadsheet::Simple::Document');

	my $sheet = $doc->get_sheet_by_name('sheet1');

	ok($sheet, "sheet is defined");
	isa_ok($sheet, 'Spreadsheet::Simple::Sheet');

	is($sheet->get_cell(0, 0)->value, 'foo', 'A1');
	is($sheet->get_cell(0, 1)->value, 'bar', 'B1');
	is($sheet->get_cell(0, 2)->value, 'baz', 'C1');
}


