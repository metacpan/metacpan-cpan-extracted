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
    _init                => sub { return },
    _setDefaults         => sub { return $_[0] },
    _stripTrailingBlanks => sub { return $_[0] },
    _validateForCallback => sub { return $_[0] },
  ]
);
my $table;

subtest 'Failure' => sub {
  $table = bless({'current_row' => 0}, $CLASS);

  delete($table->{':numberOfColumns'});
  $table->{'rows'}             = \&undefRow;
  like(dies{$table->_getNextRowFromCallback()}, qr/not an array reference/,
       'Callback returns wrong data type for the very first time');

  $table->{':numberOfColumns'} = 1;
  $table->{'rows'}             = \&noArrayRow;
  like(dies{$table->_getNextRowFromCallback()}, qr/not an array reference/,
       'Callback returns wrong data type for some next line');

  $table->{':numberOfColumns'} = 2;
  $table->{'rows'}             = \&defRow;
  like(dies{$table->_getNextRowFromCallback()}, qr/wrong number of elements/,
       'Callback returns wrong number of elements');

  $table->{':numberOfColumns'} = 1;
  $table->{'rows'}               = \&noScalarInRow;
  like(dies{$table->_getNextRowFromCallback()}, qr/not a scalar/, 'Callback returns list containing not a scalar');
};

subtest 'Success' => sub {
  my $expected;

  $table = bless({'current_row' => 0}, $CLASS);
  delete($table->{':numberOfColumns'});
  $table->{'rows'}                = \&defRow;
  $expected                       = clone($table);
  $expected->{':numberOfColumns'} = 1;
  $expected->{':rowBuffer'}       = ['line'];
  is($table->_getNextRowFromCallback(), TRUE,      'Next row (return value)');
  is($table,                            $expected, 'Next row (row content)');

  $table = bless({'current_row' => 0}, $CLASS);
  $table->{':numberOfColumns'}    = 1;
  $table->{'rows'}                = \&undefRow;
  $expected                       = clone($table);
  $expected->{':endOfChunk'}      = TRUE;
  $expected->{'end_of_table'}     = TRUE;
  is($table->_getNextRowFromCallback(), FALSE,     'No further rows (return value)');
  is($table,                            $expected, 'No further rows (row content)');
};

done_testing();

sub defRow        { return ['line'] }
sub noArrayRow    { return {}       }
sub noScalarInRow { return [{}]     }
sub undefRow      { return          }