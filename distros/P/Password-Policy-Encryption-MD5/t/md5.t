#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

BEGIN {
    use_ok('Password::Policy::Encryption::MD5');
}

my $enc = Password::Policy::Encryption::MD5->new;

isa_ok(exception { $enc->enc(''); }, 'Password::Policy::Exception::EmptyPassword');
is($enc->enc('abcdef'), 'e80b5017098950fc58aad83c8c14978e', 'Encrypted a simple string');
is($enc->encrypt('abcdef'), 'e80b5017098950fc58aad83c8c14978e', 'Encrypted a simple string using the alias');
is($enc->enc('abc def'), 'a69f0a6eabf17af1a918a546671c7f8f', 'Encrypted a simple string with spaces');

# "This is a simple sentence in Japanese", via google translate
# amended to be less stilted, thanks to sartak
is($enc->enc('この単純な文は日本語です'), '05763b4cadd6fd2338c2a6c75f5149ed', 'Encrypted a non-ASCII string');

done_testing;
