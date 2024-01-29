#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Spreadsheet::ParseXLSX;

my $wb;

eval {
  $wb = Spreadsheet::ParseXLSX->new->parse('t/data/bug-md-7.xlsx');
};

# activate this when #7 is fixed
if (0) {
  isa_ok($wb, 'Spreadsheet::ParseExcel::Workbook');
} else {
  ok(!defined($wb));
  ok($@);
  ok($@ =~ /^invalid workbook/);
}

done_testing;


