#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests=>6;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Encryption::Plaintext');
}

my $enc = Password::Policy::Encryption::Plaintext->new;

isa_ok(exception { $enc->enc(''); }, 'Password::Policy::Exception::EmptyPassword');
is($enc->enc('abcdef'), 'abcdef', 'Encrypted a simple string');
is($enc->encrypt('abcdef'), 'abcdef', 'Encrypted a simple string using the alias');
is($enc->enc('abc def'), 'abc def', 'Encrypted a simple string with spaces');

# "This is a simple sentence in Japanese", via google translate
# amended to be less stilted, thanks to sartak
is($enc->enc('この単純な文は日本語です'), 'この単純な文は日本語です', 'Encrypted a non-ASCII string');
