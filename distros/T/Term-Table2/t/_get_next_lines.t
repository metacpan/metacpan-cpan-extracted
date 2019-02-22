#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $rowBuffer;
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _cut_or_wrap_line => sub { return $_[1] },
    _get_next_row     => sub { return $rowBuffer },
    _prepare_row      => sub { return [qw(i1i2 i3i4)] },
  ]
);

my $table = bless(
  {
    ':header_lines' => [qw(h1h2 h3h4)],
    ':line_on_page' => 10,
    ':split_offset' => 2,
    'table_width'   => 2,
  },
  $CLASS
);

$rowBuffer                    = [1];
$table->{':end_of_chunk'}     = TRUE;
$table->{':line_on_page'}     = 1;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [];
$table->{':separating_added'} = TRUE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 1;
$table->{'end_of_table'}      = FALSE;
$table->{'page_height'}       = 9;
$table->{'rows'}              = [];
$table->{'separate_rows'}     = FALSE;
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[qw(h1h2 h3h4 i1i2 i3i4 ----)], TRUE],
   'Next filled row, source is array, 1st row in chunk, table end not reached, chunk end reached');

$rowBuffer                    = [];
$table->{':end_of_chunk'}     = TRUE;
$table->{':line_on_page'}     = 1;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [];
$table->{':separating_added'} = TRUE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 2;
$table->{'end_of_table'}      = FALSE;
$table->{'page_height'}       = 9;
$table->{'rows'}              = [];
$table->{'separate_rows'}     = FALSE;
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[], TRUE],
   'Next row is empty, source is array, not 1st row in chunk, table end not reached, chunk end reached');

$rowBuffer                    = [1];
$table->{':end_of_chunk'}     = FALSE;
$table->{':line_on_page'}     = 1;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [qw(i1i2 i3i4)];
$table->{':separating_added'} = FALSE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 1;
$table->{'end_of_table'}      = FALSE;
$table->{'page_height'}       = 9;
$table->{'rows'}              = sub { return };
$table->{'separate_rows'}     = TRUE;
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[qw(i1i2 i3i4 ----)], TRUE],
   'Same row, source is function, not 1st row on page, table end not reached, chunk end not reached, separate rows');

$rowBuffer                    = [1];
$table->{':end_of_chunk'}     = FALSE;
$table->{':line_on_page'}     = 1;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [qw(i1i2 i3i4)];
$table->{':separating_added'} = FALSE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 1;
$table->{'end_of_table'}      = FALSE;
$table->{'page_height'}       = 1;
$table->{'rows'}              = sub { return };
$table->{'separate_rows'}     = TRUE;
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[qw(i1i2 i3i4)], FALSE],
   'Same row, source is function, not 1st row on page, table end not reached, '
 . 'chunk end not reached, end of page reached');

$rowBuffer                    = [1];
$table->{':end_of_chunk'}     = FALSE;
$table->{':line_on_page'}     = 0;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [qw(i1i2 i3i4)];
$table->{':separating_added'} = FALSE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 1;
$table->{'end_of_table'}      = FALSE;
$table->{'page_height'}       = 9;
$table->{'rows'}              = sub { return };
$table->{'separate_rows'}     = FALSE;
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[qw(h1h2 h3h4 i1i2 i3i4)], FALSE],
   'Same row, source is function, 1st row on page, table end not reached, chunk end not reached, no rows separation');

$rowBuffer                    = [1];
$table->{':end_of_chunk'}     = TRUE;
$table->{':line_on_page'}     = 1;
$table->{':row_buffer'}       = $rowBuffer;
$table->{':row_lines'}        = [qw(i1i2 i3i4)];
$table->{':separating_added'} = TRUE;
$table->{':separating_line'}  = '----';
$table->{'current_row'}       = 1;
$table->{'end_of_table'}      = TRUE;
$table->{'page_height'}       = 9;
$table->{'rows'}              = [];
$table->_get_next_lines();
is([@$table{':row_lines', ':separating_added'}], [[qw(i1i2 i3i4)], TRUE],
   'Next filled row, source is array, 1st row in chunk, separating line already added, table end reached');

done_testing();