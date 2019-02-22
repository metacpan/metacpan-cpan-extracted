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
    _copy_options => sub       { return },
    validate      => sub (\@$) { return },
  ]
);
my $table = bless({':number_of_columns' => 3}, $CLASS);

subtest 'Failure' => sub {
  like(dies{$table->_validate_general(['header', ['a', 'b'], 'rows', ['m', 'n', 'k']])}, qr/less elements than/,
       'Too few header cells');
};

subtest 'Success' => sub {
  $table->{'table_width'} = 3;
  is($table->_validate_general([]),                                                   undef, 'No header');
  is($table->_validate_general(['header', ['a', 'b']]),                               undef, 'No table content');
  is($table->_validate_general(['header', ['a', 'b', 'c'], 'rows', ['m', 'n', 'k']]), undef, 'Header has enough cells');
};

done_testing();