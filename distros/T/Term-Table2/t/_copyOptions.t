#!/usr/bin/env perl

use v5.14;
use warnings FATAL => qw(all);

package Term::Table2;

use Test2::V0 -target => 'Term::Table2';

my $options = {A => 0, B => 1};
my $params  = [qw(A 2 C 3)];

is(_copyOptions(undef, $options, $params), {A => 2},         'Executed as function');

my $self = {X => 4};
is(_copyOptions($self, $options, $params), {A => 2, X => 4}, 'Executed as method');

done_testing();