#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

subtest 'General width for whole table' => sub {
  is(_isEachColumnWidthInt(0),    0, 'Invalid integer');
  is(_isEachColumnWidthInt('a'), '', 'Not an integer');
  is(_isEachColumnWidthInt(3),    1, 'Valid integer');
};

is(_isEachColumnWidthInt([3, 0, 'a']), '', 'Single width for each column');

done_testing();