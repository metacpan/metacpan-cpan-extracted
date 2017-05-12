#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>10;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Rule::Uppercase');
}

my $rule = Password::Policy::Rule::Uppercase->new;

is($rule->arg, 1, 'Defaults to needing one uppercase ASCII');

isa_ok(exception { $rule->check(''); }, 'Password::Policy::Exception::EmptyPassword', 'Empty password dies');
isa_ok(exception { $rule->check('abcdef'); }, 'Password::Policy::Exception::InsufficientUppercase', 'Insufficient number of uppercase ASCII dies');
is($rule->check('abcDef'), 1, 'One uppercase ASCII is enough to satisfy the condition');
isa_ok(exception { $rule->check('この単純な文は日本語です'); }, 'Password::Policy::Exception::InsufficientUppercase', 'Non-ASCII password dies');

my $rule4 = Password::Policy::Rule::Uppercase->new(4);

is($rule4->arg, 4, 'Requires four uppercase ASCII');
isa_ok(exception { $rule4->check('abC dEf Ghi'); }, 'Password::Policy::Exception::InsufficientUppercase', 'Has three uppercase ASCII, but requires four');
is($rule4->check('ABcdEfGhi'), 1, 'Password with four uppercase ASCII succeeds');
is($rule4->check('ABCDEFGHIJK'), 1, 'Password with greater than four uppercase ASCII succeeds');
