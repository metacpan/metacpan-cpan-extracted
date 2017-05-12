#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 29;

use Spreadsheet::Simple;

my $ss = Spreadsheet::Simple->new;
isa_ok($ss, 'Spreadsheet::Simple');

my $doc = $ss->new_document;
isa_ok($doc, 'Spreadsheet::Simple::Document');

is($doc->sheet_count, 0, 'sheet_count == 0');

my $sheet = $doc->new_sheet(
	name => 'test',
	rows => [
	    # 0  1  2  3  4
		[ 1, 2, 3, 4, 5], # 0
		[ 6, 7, 8, 9, 10] # 1
	],
);

is($doc->sheet_count, 1, 'sheet_count == 1');

isa_ok($sheet, 'Spreadsheet::Simple::Sheet');
is($doc->get_sheet(0), $sheet, 'get_sheet(0)');
is($doc->get_sheet_by_name('test'), $sheet, 'get_sheet_by_name("test")');
is($doc->get_sheet_by_name('TEST'), $sheet, 'get_sheet_by_name("TEST")');

is($sheet->row_count, 2, 'row_count == 2');

foreach my $row ($sheet->rows) {
    isa_ok($row, 'Spreadsheet::Simple::Row');
    is($row->cell_count, 5, 'cell_count == 5');
}

is($sheet->get_cell(0, 0)->value, '1', 'get_cell(0, 0)');
is($sheet->get_cell(1, 4)->value, '10', 'get_cell(1, 4)');
is($sheet->get_cell(5, 5)->value, undef, 'get_cell(5, 5)');

is($sheet->row_count, 6, 'row_count == 6');
is($sheet->get_row(5)->cell_count, 6, 'get_row(5) cell_count == 6');

is($sheet->get_cell_value(0, 0), '1', 'get_cell_value(0, 0)');
is($sheet->get_cell_value(1, 2), '8', 'get_cell_value(1, 2)');
is($sheet->get_cell_value(6, 6), undef, 'get_cell_value(6, 6)');

is($sheet->row_count, 7, 'row_count == 7');
is($sheet->get_row(6)->cell_count, 7, 'get_row(6) cell_count == 7');

$sheet->get_cell(10, 10)->value('pants');
is($sheet->get_cell(10, 10)->value, 'pants', 'get_cell(10, 10)');

is($sheet->row_count, 11, 'row_count == 11');
is($sheet->get_row(10)->cell_count, 11, 'get_row(10) cell_count == 11');

$sheet->set_cell_value(20, 20, 'pants');
is($sheet->get_cell(20, 20)->value, 'pants', 'get_cell(20, 20)');

is($sheet->row_count, 21, 'row_count == 21');
is($sheet->get_row(20)->cell_count, 21, 'get_row(20) cell_count == 21');


sub frob {
	local $_ = shift;
	return [ map { Spreadsheet::Simple::Row->new(cells => $_ ) } @$_ ];
}

sub gork {
	local $_ = shift;
	return [ map { Spreadsheet::Simple::Cell->new(value => $_) } @$_ ];
}

