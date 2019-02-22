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
    _copy_options          => sub       { return $_[0] },
    _strip_trailing_blanks => sub       { return @_ },
    _validate_general      => sub       { return $_[0] },
    validate               => sub (\@$) { return },
  ]
);
my $table = bless({}, $CLASS);
my $expected;

$table->{'rows'}                  = [];
$expected                         = clone($table);
$expected->{':number_of_columns'} = 0;
is($table->_validate_for_array([]), $expected, 'No content');

$table->{'rows'}                  = [[1, 2], [3, 4]];
$expected                         = clone($table);
$expected->{':number_of_columns'} = 2;
is($table->_validate_for_array([]), $expected, 'Table with content');

done_testing();