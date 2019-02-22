#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my ($nextRowFromArrayFlag, $nextRowFromCallbackFlag);
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _get_next_row_from_array    => sub { return $nextRowFromArrayFlag },
    _get_next_row_from_callback => sub { return $nextRowFromCallbackFlag },
  ]
);

my $table = bless({'current_row' => 1}, $CLASS);

subtest 'No rows remain' => sub {
  $nextRowFromArrayFlag    = FALSE;
  $nextRowFromCallbackFlag = FALSE;
  $table->{'end_of_table'} = TRUE;
  $table->{'rows'}         = {};
  is($table->_get_next_row(), [], 'Empty table (return value)');
  is($table->{'current_row'},  1, 'Empty table (row counter)');

  $nextRowFromArrayFlag    = FALSE;
  $nextRowFromCallbackFlag = TRUE;
  $table->{'end_of_table'} = FALSE;
  $table->{'rows'}         = [];
  is($table->_get_next_row(), [], 'Nothing in array (return value)');
  is($table->{'current_row'},  1, 'Nothing in array (row counter)');

  $nextRowFromArrayFlag    = TRUE;
  $nextRowFromCallbackFlag = FALSE;
  $table->{'end_of_table'} = FALSE;
  $table->{'rows'}         = sub { return };
  is($table->_get_next_row(), [], 'Nothing from callback (return value)');
  is($table->{'current_row'},  1, 'Nothing from callback (row counter)');
};

subtest 'Some rows remain' => sub {
  $nextRowFromArrayFlag    = TRUE;
  $nextRowFromCallbackFlag = TRUE;
  $table->{'end_of_table'} = FALSE;
  $table->{'rows'}         = [];
  is($table->_get_next_row(), [], 'Next from array (return value)');
  is($table->{'current_row'},  2, 'Next from array (row counter)');

  $nextRowFromArrayFlag    = TRUE;
  $nextRowFromCallbackFlag = TRUE;
  $table->{'end_of_table'} = FALSE;
  $table->{'rows'}         = sub { return };
  is($table->_get_next_row(), [], 'Next from callback (return value)');
  is($table->{'current_row'},  3, 'Next from callback (row counter)');
};

done_testing();