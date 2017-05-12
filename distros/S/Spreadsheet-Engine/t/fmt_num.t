#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use Spreadsheet::Engine::Sheet;
*fmt = \&Spreadsheet::Engine::Sheet::format_number_for_display;

my @tests = (

  # zero padding
  [ 10, '0000', '0010' ],

  # decimal places
  [ 1 / 7, '0.00',   '0.14' ],
  [ 1 / 7, '0.0000', '0.1429' ],

  # percentage
  [ 1 / 7, '0%',    '14%' ],
  [ 1 / 7, '0.00%', '14.29%' ],

  # fractions (not implemented)
  # [ 8/7, '# ?/?', '1 1/7' ],

  # commas / brackets
  [ 1000,  '#,##0;(#,##0)', '1,000' ],
  [ -1000, '#,##0;(#,##0)', '(1,000)' ],

  # zero values (TODO - gets undef. bug?
  # [ 0, '#,##0_;(#,##0);-;', '-' ],

  # rounding to thousands / millions
  [ 51883,     '#,##0,',  '52' ],
  [ 5_188_313, '#,##0,',  '5,188' ],
  [ 5_188_313, '#,##0,,', '5' ],

  # scientific (not implemented)
  # [ 5_188_313, '##0.0E+0', '5.2E+6' ]

);

plan tests => scalar @tests;

for my $test (@tests) {
  my ($num, $format, $result) = @{$test};
  is fmt($num, 'n', $format), $result, "$num ($format) => $result";
}

