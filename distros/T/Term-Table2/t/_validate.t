#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    _copyOptions         => sub       { return {} },
    _validateForArray    => sub       { return },
    validate             => sub (\@$) { return },
  ]
);
my $table = bless({}, $CLASS);

is($table->_validate([]),           $table, 'No data source');
is($table->_validate(['rows', []]), undef,  'Data source is array');
is($table->_validate(['rows', {}]), $table, 'Data source is not an array');

done_testing();