#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

subtest 'General width for whole table' => sub {
  is(_is_each_column_width_int(0),    0, 'Invalid integer');
  is(_is_each_column_width_int('a'), '', 'Not an integer');
  is(_is_each_column_width_int(3),    1, 'Valid integer');
};

is(_is_each_column_width_int([3, 0, 'a']), '', 'Single width for each column');

done_testing();