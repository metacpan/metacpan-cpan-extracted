#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>9;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Rule::Length');
}

my $rule = Password::Policy::Rule::Length->new;

is($rule->arg, 8, 'Defaults to a length of eight');

isa_ok(exception { $rule->check(''); }, 'Password::Policy::Exception::EmptyPassword', 'Empty password dies');
isa_ok(exception { $rule->check('abcdef'); }, 'Password::Policy::Exception::InsufficientLength', 'Insufficient length dies');

my $rule12 = Password::Policy::Rule::Length->new(12);

is($rule12->arg, 12, 'Has a length of twelve');
isa_ok(exception { $rule12->check('abc def ghi'); }, 'Password::Policy::Exception::InsufficientLength', 'Eleven character password dies');
is($rule12->check('abc def ghi jk'), 1, 'Thirteen character password (counting spaces) succeeds');

# "This is a simple sentence in Japanese", via google translate
is($rule12->check('これは日本での単純な文です。'), 1, 'Fourteen character non-ASCII password succeeds');

my $rule15 = Password::Policy::Rule::Length->new(15);

# "This is a simple sentence in Japanese", via google translate
# amended to be less stilted, thanks to sartak
isa_ok(exception { $rule15->check('この単純な文は日本語です'); }, 'Password::Policy::Exception::InsufficientLength', 'Fourteen character non-ASCII password dies');
