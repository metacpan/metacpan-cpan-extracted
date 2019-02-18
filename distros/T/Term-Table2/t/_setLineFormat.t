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

$table->{':lineFormat'}        = '|';
$table->{':numberOfColumns'}   = 0;
$table->{':separatingLine'}    = '+';
$table->{'broad_row'}          = 0;
$expected                      = clone($table);
$expected->{':lineFormat'}     = '|';
$expected->{':separatingLine'} = '+';
$expected->{':totalWidth'}     = 1;
$expected->{'current_row'}     = 0;
is($table->_setLineFormat(), $expected, 'No one column with content');

$table->{':lineFormat'}        = '|';
$table->{':numberOfColumns'}   = 4;
$table->{':separatingLine'}    = '+';
$table->{'broad_row'}          = 0;
$expected                      = clone($table);
$expected->{':lineFormat'}     = '|%s   %-1s   |   %-2s   |   %-9s   |';
$expected->{':separatingLine'} = '+-------+--------+---------------+';
$expected->{':totalWidth'}     = 34;
is($table->_setLineFormat(), $expected, 'Cut off output lines');

$table->{':lineFormat'}        = '|';
$table->{':numberOfColumns'}   = 4;
$table->{':separatingLine'}    = '+';
$table->{'broad_row'}          = 2;
$expected                      = clone($table);
$expected->{':lineFormat'}     = '|%s   %-1s   |   %-2s   |   %-9s   |';
$expected->{':separatingLine'} = '+-------+--------+---------------+';
is($table->_setLineFormat(), $expected, 'Wrap output lines');

done_testing();