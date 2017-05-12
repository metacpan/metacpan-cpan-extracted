#!/usr/bin/perl
use strict;
use warnings;
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel_XLHTML '-install';
use Test::More tests => 3 * 3 * 2;

my $TEST_FILE = 't/test.xls';

# make a test .xls
my $workbook  = Spreadsheet::WriteExcel->new($TEST_FILE);
my $worksheet;
for (1..2) {
    $worksheet = $workbook->add_worksheet;
    $worksheet->write(0, 0, 'test');
    $worksheet->write(0, 1, 123.56);
    $worksheet->write(1, 0, 6);
}
$workbook->close;

# test classic interface
my $excel  = Spreadsheet::ParseExcel->new;
$workbook  = $excel->Parse($TEST_FILE);
for $worksheet (@{ $workbook->{Worksheet} }) {
    test_sheet($worksheet);
}

# test some of the newer interface
$workbook  = Spreadsheet::ParseExcel::Workbook->Parse($TEST_FILE);
for $worksheet ($workbook->worksheets) {
    test_sheet($worksheet);
}

# test explicit interface
$excel = Spreadsheet::ParseExcel_XLHTML->new;
$workbook  = $excel->Parse($TEST_FILE);
for $worksheet (@{ $workbook->{Worksheet} }) {
    test_sheet($worksheet);
}

sub test_sheet {
    my $worksheet = shift;

    eval {
        is     $worksheet->{Cells}[0][0]->Value,       'test', 'string datum';
        cmp_ok $worksheet->{Cells}[0][1]->Value, '==', 123.56, 'float datum';
        is     $worksheet->{Cells}[1][0]->Value,       6,      'int datum';
    };
    if ($@) {
        fail $@ for 1..3;
    }
}

END {
    unlink $TEST_FILE;
}
