#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>9;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Rule::Whitespace');
}

my $rule = Password::Policy::Rule::Whitespace->new;

is($rule->arg, 1, 'Defaults to needing one whitespace character');

isa_ok(exception { $rule->check(''); }, 'Password::Policy::Exception::EmptyPassword', 'Empty password dies');
isa_ok(exception { $rule->check('abcdef'); }, 'Password::Policy::Exception::InsufficientWhitespace', 'Insufficient number of whitespace characters dies');
is($rule->check('abc def'), 1, 'One whitespace character is enough to satisfy the condition');

my $rule4 = Password::Policy::Rule::Whitespace->new(4);

is($rule4->arg, 4, 'Requires four whitespace characters');
isa_ok(exception { $rule4->check("abc\t\tdef ghi"); }, 'Password::Policy::Exception::InsufficientWhitespace', 'Has three whitespace characters, but requires four');
is($rule4->check('abc12 def3  ghi jklmnop90'), 1, 'Four whitespace character password succeeds');
is($rule4->check("abc\t12 def34 ghi\t56 jklmnop"), 1, 'Greater than four whitespace character password succeeds');
