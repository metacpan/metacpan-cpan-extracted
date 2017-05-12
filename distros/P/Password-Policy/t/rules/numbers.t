#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>9;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Rule::Numbers');
}

my $rule = Password::Policy::Rule::Numbers->new;

is($rule->arg, 1, 'Defaults to needing one number');

isa_ok(exception { $rule->check(''); }, 'Password::Policy::Exception::EmptyPassword', 'Empty password dies');
isa_ok(exception { $rule->check('abcdef'); }, 'Password::Policy::Exception::InsufficientNumbers', 'Insufficient number of numbers dies');
is($rule->check('abcdef1'), 1, 'One number is enough to satisfy the condition');

my $rule4 = Password::Policy::Rule::Numbers->new(4);

is($rule4->arg, 4, 'Requires four numbers');
isa_ok(exception { $rule4->check('abcdef ghi123'); }, 'Password::Policy::Exception::InsufficientNumbers', 'Has three numbers, but requires four');
is($rule4->check('abc12 def34'), 1, 'Four number password succeeds');
is($rule4->check('abc12 def34 ghi56'), 1, 'Greater than four number password succeeds');
