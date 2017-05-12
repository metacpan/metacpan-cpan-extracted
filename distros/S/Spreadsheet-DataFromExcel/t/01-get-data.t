#!perl 

use strict;
use warnings;

use Test::More tests => 3;

use Spreadsheet::DataFromExcel;

my $p = Spreadsheet::DataFromExcel->new;

isa_ok($p, 'Spreadsheet::DataFromExcel');
can_ok($p, qw/load  error/);

my $data = $p->load('t/sheet.xls')
    or BAIL_OUT "Got error parsing Excel file: " . $p->error;

is_deeply(
    $data,
    [
        [
          'Test1',
          'Test2',
          'Test3',
          'Test4'
        ],
        [
          'Test5',
          'Test6',
          'Test7',
          undef
        ],
        [
          undef,
          undef,
          undef,
          'Test8'
        ]
    ],
);