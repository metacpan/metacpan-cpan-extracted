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
    _copy_options     => sub       { return $_[0] },
    _validate_general => sub       { return },
    validate          => sub (\@$) { return },
  ]
);
my $table = bless({}, $CLASS);

is($table->_validate_for_callback([]), undef, 'Executed');

done_testing();