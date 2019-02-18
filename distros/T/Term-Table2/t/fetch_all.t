#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';
use Test2::Mock;

my @lines    = qw(line1 line2);
my $mockThis = Test2::Mock->new(
  class    => $CLASS,
  override => [
    fetch    => sub { return $_ = shift(@lines) },
  ]
);

my $table = bless({}, $CLASS);
is($table->fetch_all(), [qw(line1 line2)], 'Executed');

done_testing();