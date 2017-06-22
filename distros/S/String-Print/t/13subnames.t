#!/usr/bin/env perl
# Use of sub-naming schemes.

use warnings;
use strict;

use Test::More tests => 8;

use String::Print;

my $f = String::Print->new;
isa_ok($f, 'String::Print');

is $f->sprinti('{a}', a => 'simple'), 'simple';
is $f->sprinti('{a.b}', a => {b => 'nested'}), 'nested';
is $f->sprinti('{a.b%-10s}', a => {b => 'format'}), 'format    ';
is $f->sprinti('{a.b.c}', a => {b => {c => 'deeper'}}), 'deeper';

sub b() { +{ c => 'via code' } }
is $f->sprinti('{a.b.c}', a => {b => \&b}), 'via code', 'code ref';

{ package USER;
  sub new()   { bless { name => $_[1] }, $_[0] }
  sub name()  { $_[0]->{name} }
  sub count() { 42 }
}

my $user = USER->new('Mark');
is $f->sprinti('{user.name}', user => $user), 'Mark', 'object method';

is $f->sprinti('{user.count}', user => 'USER'), 42, 'class method';

