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
    _copyOptions         => sub       { return $_[0] },
    _stripTrailingBlanks => sub       { return @_ },
    _validateGeneral     => sub       { return $_[0] },
    validate             => sub (\@$) { return },
  ]
);
my $table = bless({}, $CLASS);
my $expected;

$table->{'rows'}                = [];
$expected                       = clone($table);
$expected->{':numberOfColumns'} = 0;
is($table->_validateForArray([]), $expected, 'No content');

$table->{'rows'}                = [[1, 2], [3, 4]];
$expected                       = clone($table);
$expected->{':numberOfColumns'} = 2;
is($table->_validateForArray([]), $expected, 'Table with content');

done_testing();