#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

my $broad_flags = [0, 1, 0];
my $row         = ['abcd', 'efgh', 'ij'];
my $table       = bless(
  {
    ':number_of_columns' => 3,
    'column_width'     => [3, 3, 4],
  },
  $CLASS,
);

is($table->_extract_line($row, $broad_flags), ['abc', 'efg', 'ij'], 'Line content');
is($row, ['', 'h', ''], 'Remaining row content');

done_testing();