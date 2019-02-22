#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Clone qw(clone);
use Test2::V0 -target => 'Term::Table2';

my $table = bless(
  {
    'collapse'     => [1, 1, 0, 0],
    'column_width' => [0, 1, 2, 9],
    'pad'          => [3, 3, 3, 3],
    'table_width'  => 20,
  },
  $CLASS
);
my $expected;

$table->{':line_format'}        = '|';
$table->{':number_of_columns'}  = 0;
$table->{':separating_line'}    = '+';
$table->{'broad_row'}           = 0;
$expected                       = clone($table);
$expected->{':line_format'}     = '|';
$expected->{':separating_line'} = '+';
$expected->{':total_width'}     = 1;
$expected->{'current_row'}      = 0;
is($table->_set_line_format(), $expected, 'No one column with content');

$table->{':line_format'}        = '|';
$table->{':number_of_columns'}  = 4;
$table->{':separating_line'}    = '+';
$table->{'broad_row'}           = 0;
$expected                       = clone($table);
$expected->{':line_format'}     = '|%s   %-1s   |   %-2s   |   %-9s   |';
$expected->{':separating_line'} = '+-------+--------+---------------+';
$expected->{':total_width'}     = 34;
is($table->_set_line_format(), $expected, 'Cut off output lines');

$table->{':line_format'}        = '|';
$table->{':number_of_columns'}  = 4;
$table->{':separating_line'}    = '+';
$table->{'broad_row'}           = 2;
$expected                       = clone($table);
$expected->{':line_format'}     = '|%s   %-1s   |   %-2s   |   %-9s   |';
$expected->{':separating_line'} = '+-------+--------+---------------+';
is($table->_set_line_format(), $expected, 'Wrap output lines');

done_testing();