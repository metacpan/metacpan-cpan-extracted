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
    _copyOptions => sub       { return },
    validate     => sub (\@$) { return },
  ]
);
my $table = bless({':numberOfColumns' => 3}, $CLASS);

subtest 'Failure' => sub {
  like(dies{$table->_validateGeneral(['header', ['a', 'b'], 'rows', ['m', 'n', 'k']])}, qr/less elements than/,
       'Too few header cells');
};

subtest 'Success' => sub {
  $table->{'table_width'} = 3;
  is($table->_validateGeneral([]),                                                   undef, 'No header');
  is($table->_validateGeneral(['header', ['a', 'b']]),                               undef, 'No table content');
  is($table->_validateGeneral(['header', ['a', 'b', 'c'], 'rows', ['m', 'n', 'k']]), undef, 'Header has enough cells');
};

done_testing();