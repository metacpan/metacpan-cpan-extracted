#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Clone qw(clone);
use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _init                  => sub { return },
    _set_defaults          => sub { return $_[0] },
    _strip_trailing_blanks => sub { return $_[0] },
    _validate_for_callback => sub { return $_[0] },
  ]
);
my $table;

subtest 'Failure' => sub {
  $table = bless({'current_row' => 0}, $CLASS);

  delete($table->{':number_of_columns'});
  $table->{'rows'} = \&undefRow;
  like(dies{$table->_get_next_row_from_callback()}, qr/not an array reference/,
       'Callback returns wrong data type for the very first time');

  $table->{':number_of_columns'} = 1;
  $table->{'rows'}               = \&noArrayRow;
  like(dies{$table->_get_next_row_from_callback()}, qr/not an array reference/,
       'Callback returns wrong data type for some next line');

  $table->{':number_of_columns'} = 2;
  $table->{'rows'}               = \&defRow;
  like(dies{$table->_get_next_row_from_callback()}, qr/wrong number of elements/,
       'Callback returns wrong number of elements');

  $table->{':number_of_columns'} = 1;
  $table->{'rows'}               = \&noScalarInRow;
  like(dies{$table->_get_next_row_from_callback()}, qr/not a scalar/, 'Callback returns list containing not a scalar');
};

subtest 'Success' => sub {
  my $expected;

  $table = bless({'current_row' => 0}, $CLASS);
  delete($table->{':number_of_columns'});
  $table->{'rows'}                  = \&defRow;
  $expected                         = clone($table);
  $expected->{':number_of_columns'} = 1;
  $expected->{':row_buffer'}        = ['line'];
  is($table->_get_next_row_from_callback(), TRUE,      'Next row (return value)');
  is($table,                                $expected, 'Next row (row content)');

  $table = bless({'current_row' => 0}, $CLASS);
  $table->{':number_of_columns'} = 1;
  $table->{'rows'}               = \&undefRow;
  $expected                      = clone($table);
  $expected->{':end_of_chunk'}   = TRUE;
  $expected->{'end_of_table'}    = TRUE;
  is($table->_get_next_row_from_callback(), FALSE,     'No further rows (return value)');
  is($table,                                $expected, 'No further rows (row content)');
};

done_testing();

sub defRow        { return ['line'] }
sub noArrayRow    { return {}       }
sub noScalarInRow { return [{}]     }
sub undefRow      { return          }