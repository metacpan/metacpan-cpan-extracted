#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Encryption::SHA1');
}

my $enc = Password::Policy::Encryption::SHA1->new;

isa_ok(exception { $enc->enc(''); }, 'Password::Policy::Exception::EmptyPassword');
is($enc->enc('abcdef'), '1f8ac10f23c5b5bc1167bda84b833e5c057a77d2', 'Encrypted a simple string');
is($enc->encrypt('abcdef'), '1f8ac10f23c5b5bc1167bda84b833e5c057a77d2', 'Encrypted a simple string using the alias');
is($enc->enc('abc def'), '4d93fd047780e2977f8a1c9868599ebb2bbfc29f', 'Encrypted a simple string with spaces');

# "This is a simple sentence in Japanese", via google translate
# amended to be less stilted, thanks to sartak
is($enc->enc('この単純な文は日本語です'), 'd7c126788de910aad73874652438b411628b7b64', 'Encrypted a non-ASCII string');

done_testing;
