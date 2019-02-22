#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my @lines    = ('line 1', 'line 2');
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _extract_lines => sub { return [\@lines, \@lines] },
  ]
);
my $table    = bless({':line_format' => '| %s | %s |'}, $CLASS);

$table->{':number_of_columns'} = 2;
is($table->_prepare_row(['value 0', 'value 1', 'value 2']), ['| line 1 | line 2 |', '| line 1 | line 2 |'],
   'Redundant columns supplied');

$table->{':number_of_columns'} = 3;
is($table->_prepare_row(['value 0', 'value 1', 'value 2']), ['| line 1 | line 2 |', '| line 1 | line 2 |'],
   'No redundant columns supplied');

done_testing();