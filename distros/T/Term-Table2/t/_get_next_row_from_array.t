#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

my $table = bless(
  {
    ':row_buffer'      => ['line'],
    ':separating_line' => '+--+',
    ':total_width'     => 6,
    'rows'             => [[0], [1]],
  },
  $CLASS
);

$table->{'broad_row'}     = 0;
$table->{'current_row'}   = 2;
$table->{'table_width'}   = 5;
$table->{':split_offset'} = 0;
is($table->_get_next_row_from_array(), 0, 'End of table reached without splitting (return value)');
is(
  $table,
  {
    ':end_of_chunk'    => '',
    ':row_buffer'      => ['line'],
    ':separating_line' => '+--+',
    ':split_offset'    => 0,
    ':total_width'     => 6,
    'broad_row'        => 0,
    'current_row'      => 2,
    'end_of_table'     => 1,
    'rows'             => [[0], [1]],
    'table_width'      => 5,
  },
  'End of table reached without splitting (row content)'
);

$table->{'broad_row'}     = 1;
$table->{'current_row'}   = 2;
$table->{'table_width'}   = 5;
$table->{':split_offset'} = 1;
is($table->_get_next_row_from_array(), 0, 'End of table reached with splitting (return value)');
is(
  $table,
  {
    ':end_of_chunk'    => '',
    ':row_buffer'      => ['line'],
    ':separating_line' => '+--+',
    ':split_offset'    => 1,
    ':total_width'     => 6,
    'broad_row'        => 1,
    'current_row'      => 2,
    'end_of_table'     => 1,
    'rows'             => [[0], [1]],
    'table_width'      => 5,
  },
  'End of table reached with splitting (row content)'
);

$table->{'broad_row'}     = 1;
$table->{'current_row'}   = 2;
$table->{'table_width'}   = 5;
$table->{':split_offset'} = 0;
is($table->_get_next_row_from_array(), 1, 'Next chunk started (return value)');
is(
  $table,
  {
    ':end_of_chunk'    => '',
    ':row_buffer'      => [0],
    ':separating_line' => '+--+',
    ':split_offset'    => 5,
    ':total_width'     => 6,
    'broad_row'        => 1,
    'current_row'      => 0,
    'end_of_table'     => 0,
    'rows'             => [[0], [1]],
    'table_width'      => 5,
  },
  'Next chunk started (row content)'
);

$table->{'broad_row'}     = 0;
$table->{'current_row'}   = 1;
$table->{'table_width'}   = 5;
$table->{':split_offset'} = 0;
is($table->_get_next_row_from_array(), 1, 'Next line taken over (return value)');
is(
  $table,
  {
    ':end_of_chunk'    => 1,
    ':row_buffer'      => [1],
    ':separating_line' => '+--+',
    ':split_offset'    => 0,
    ':total_width'     => 6,
    'broad_row'        => 0,
    'current_row'      => 1,
    'end_of_table'     => 0,
    'rows'             => [[0], [1]],
    'table_width'      => 5,
  },
  'Next line taken over (row content)'
);

done_testing();