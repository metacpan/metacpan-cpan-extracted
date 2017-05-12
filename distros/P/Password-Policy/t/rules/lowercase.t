#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>10;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Rule::Lowercase');
}

my $rule = Password::Policy::Rule::Lowercase->new;

is($rule->arg, 1, 'Defaults to needing one lowercase ASCII');

isa_ok(exception { $rule->check(''); }, 'Password::Policy::Exception::EmptyPassword', 'Empty password dies');
isa_ok(exception { $rule->check('ABCDEF1234'); }, 'Password::Policy::Exception::InsufficientLowercase', 'Insufficient number of lowercase ASCII dies');
is($rule->check('aBCD'), 1, 'One lowercase ASCII is enough to satisfy the condition');
isa_ok(exception { $rule->check('この単純な文は日本語です'); }, 'Password::Policy::Exception::InsufficientLowercase', 'Non-ASCII password dies');

my $rule4 = Password::Policy::Rule::Lowercase->new(4);

is($rule4->arg, 4, 'Requires four lowercase ASCII');
isa_ok(exception { $rule4->check('ABCDeFG hiJKLMOP'); }, 'Password::Policy::Exception::InsufficientLowercase', 'Has three lowercase ASCII, but requires four');
is($rule4->check('abcdEFGHI'), 1, 'Password with four lowercase ASCII succeeds');
is($rule4->check('abcdef'), 1, 'Password with greater than four lowercase ASCII succeeds');
