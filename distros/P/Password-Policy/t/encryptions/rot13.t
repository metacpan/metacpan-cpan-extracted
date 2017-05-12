#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>6;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Encryption::ROT13');
}

my $enc = Password::Policy::Encryption::ROT13->new;

isa_ok(exception { $enc->enc(''); }, 'Password::Policy::Exception::EmptyPassword');
is($enc->enc('abcdef'), 'fedcba', 'Encrypted a simple string');
is($enc->encrypt('abcdef'), 'fedcba', 'Encrypted a simple string using the alias');
is($enc->enc('abc def'), 'fed cba', 'Encrypted a simple string with spaces');

# "This is a simple sentence in Japanese", via google translate
# amended to be less stilted, thanks to sartak
is($enc->enc('この単純な文は日本語です'), 'すで語本日は文な純単のこ', 'Encrypted a non-ASCII string');
