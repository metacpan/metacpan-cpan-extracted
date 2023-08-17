#!/usr/bin/perl
#
# Test formula parsing.  -- rgr, 12-Apr-23.
#

use strict;
use warnings;

use Test::More tests => 8;

use Spreadsheet::ReadGnumeric;

## Basic testing.
my $formula = 'I9+E10*(G10-F10-D10)';
my $formula_tokenized
    = [[9, 9], '+', [5, 10],
       '*(', [7, 10], '-', [6, 10], '-', [4, 10], ')'];
my $actual = Spreadsheet::ReadGnumeric::_tokenize_formula($formula);
is_deeply($actual, $formula_tokenized, "tokenize '$formula'");
my $new_formula = Spreadsheet::ReadGnumeric::_untokenize_formula
    ($formula_tokenized, 2, 3);
is($new_formula, 'K12+G13*(I13-H13-F13)', 'untokenized and offset');

# Get a spreadsheet and check some formulas.
my $parser = Spreadsheet::ReadGnumeric->new(process_formulas => 1);
my $formula_ss = 't/data/formula.gnumeric';
my $ss = $parser->parse($formula_ss);
my $sheet1 = $ss->[1];
# These rows have the original formulas.
is($sheet1->{H6}, '=H5+G6-F6-D6', "check $formula_ss H6 formula");
is($sheet1->{I6}, '=I5+E6*(G6-F6-D6)', "check $formula_ss I6 formula");
# These rows have the referenced formulas.
is($sheet1->{H7}, '=H6+G7-F7-D7', "check $formula_ss H7 formula");
is($sheet1->{I7}, '=I6+E7*(G7-F7-D7)', "check $formula_ss I7 formula");
my $sheet2 = $ss->[2];
is($sheet2->{G5}, '=G4+F5-E5-C5', "check $formula_ss sheet2 G5 formula");
is($sheet2->{H5}, '=H4+D5*(F5-E5-C5)', "check $formula_ss H5 formula");
