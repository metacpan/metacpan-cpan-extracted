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
    _cutOrWrapLine => sub { return $_[1] },
    _getNextRow    => sub { return $rowBuffer },
    _prepareRow    => sub { return [qw(i1i2 i3i4)] },
  ]
);

my $table = bless(
  {
    ':headerLines' => [qw(h1h2 h3h4)],
    ':lineOnPage'  => 10,
    ':splitOffset' => 2,
    'table_width'  => 2,
  },
  $CLASS
);

$rowBuffer                   = [1];
$table->{':endOfChunk'}      = TRUE;
$table->{':lineOnPage'}      = 1;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [];
$table->{':separatingAdded'} = TRUE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 1;
$table->{'end_of_table'}     = FALSE;
$table->{'page_height'}      = 9;
$table->{'rows'}             = [];
$table->{'separate_rows'}    = FALSE;
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[qw(h1h2 h3h4 i1i2 i3i4 ----)], TRUE],
   'Next filled row, source is array, 1st row in chunk, table end not reached, chunk end reached');

$rowBuffer                   = [];
$table->{':endOfChunk'}      = TRUE;
$table->{':lineOnPage'}      = 1;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [];
$table->{':separatingAdded'} = TRUE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 2;
$table->{'end_of_table'}     = FALSE;
$table->{'page_height'}      = 9;
$table->{'rows'}             = [];
$table->{'separate_rows'}    = FALSE;
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[], TRUE],
   'Next row is empty, source is array, not 1st row in chunk, table end not reached, chunk end reached');

$rowBuffer                   = [1];
$table->{':endOfChunk'}      = FALSE;
$table->{':lineOnPage'}      = 1;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [qw(i1i2 i3i4)];
$table->{':separatingAdded'} = FALSE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 1;
$table->{'end_of_table'}     = FALSE;
$table->{'page_height'}      = 9;
$table->{'rows'}             = sub { return };
$table->{'separate_rows'}    = TRUE;
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[qw(i1i2 i3i4 ----)], TRUE],
   'Same row, source is function, not 1st row on page, table end not reached, chunk end not reached, separate rows');

$rowBuffer                   = [1];
$table->{':endOfChunk'}      = FALSE;
$table->{':lineOnPage'}      = 1;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [qw(i1i2 i3i4)];
$table->{':separatingAdded'} = FALSE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 1;
$table->{'end_of_table'}     = FALSE;
$table->{'page_height'}      = 1;
$table->{'rows'}             = sub { return };
$table->{'separate_rows'}    = TRUE;
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[qw(i1i2 i3i4)], FALSE],
   'Same row, source is function, not 1st row on page, table end not reached, '
 . 'chunk end not reached, end of page reached');

$rowBuffer                   = [1];
$table->{':endOfChunk'}      = FALSE;
$table->{':lineOnPage'}      = 0;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [qw(i1i2 i3i4)];
$table->{':separatingAdded'} = FALSE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 1;
$table->{'end_of_table'}     = FALSE;
$table->{'page_height'}      = 9;
$table->{'rows'}             = sub { return };
$table->{'separate_rows'}    = FALSE;
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[qw(h1h2 h3h4 i1i2 i3i4)], FALSE],
   'Same row, source is function, 1st row on page, table end not reached, chunk end not reached, no rows separation');

$rowBuffer                   = [1];
$table->{':endOfChunk'}      = TRUE;
$table->{':lineOnPage'}      = 1;
$table->{':rowBuffer'}       = $rowBuffer;
$table->{':rowLines'}        = [qw(i1i2 i3i4)];
$table->{':separatingAdded'} = TRUE;
$table->{':separatingLine'}  = '----';
$table->{'current_row'}      = 1;
$table->{'end_of_table'}     = TRUE;
$table->{'page_height'}      = 9;
$table->{'rows'}             = [];
$table->_getNextLines();
is([@$table{':rowLines', ':separatingAdded'}], [[qw(i1i2 i3i4)], TRUE],
   'Next filled row, source is array, 1st row in chunk, separating line already added, table end reached');

done_testing();