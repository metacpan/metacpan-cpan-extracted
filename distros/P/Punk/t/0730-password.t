#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Auth::Password;

# Password hashing (punk_password.h). The two promises worth pinning hard:
# the stored format is MaatSite::Password's byte for byte - a literal hash
# minted by the production pure-Perl implementation must verify here, and one
# minted here must parse there - and the cost knob is localizable, because
# every adopting test suite needs `local $ITERATIONS` to stay fast.

local $Punk::Auth::Password::ITERATIONS = 1_000;

# ---- the format, and cross-implementation compatibility -----------------------

# Minted by MaatSite::Password (Digest::SHA PBKDF2) at 1_000 iterations for
# the password "correct horse battery staple". A change that breaks this
# breaks every production row.
my $MAAT = 'pbkdf2-sha256$1000$8lGMmDoR/+cOAkTocdYWJg=='
         . '$erXRUQMYQAWCwm1opxjY/VAGZ8bncEOsAAyofOxnbKM=';

ok(Punk::Auth::Password::verify('correct horse battery staple', $MAAT),
    'a hash minted by MaatSite::Password verifies');
ok(!Punk::Auth::Password::verify('wrong password', $MAAT),
    'and still rejects the wrong password');

my $h = Punk::Auth::Password::hash('correct horse battery staple');
like($h, qr/^pbkdf2-sha256\$1000\$[A-Za-z0-9+\/=]+\$[A-Za-z0-9+\/=]+$/,
    'the stored format: scheme, iterations, standard base64 salt and key');
my ($salt_b64, $key_b64) = ($h =~ /^[^\$]+\$\d+\$([^\$]+)\$([^\$]+)$/);
is(length $salt_b64, 24, 'a 16-byte salt is 24 base64 characters');
is(length $key_b64,  44, 'a 32-byte key is 44 base64 characters');

# ---- round trips ---------------------------------------------------------------

ok(Punk::Auth::Password::verify('correct horse battery staple', $h),
    'a fresh hash verifies');
ok(!Punk::Auth::Password::verify('Correct horse battery staple', $h),
    'case matters');
isnt(Punk::Auth::Password::hash('same password'),
     Punk::Auth::Password::hash('same password'),
    'two hashes of one password differ (fresh salt each time)');

ok(Punk::Auth::Password->verify('correct horse battery staple', $h),
    'the class-method spelling works too');

# ---- undef and garbage are false, never fatal ---------------------------------

ok(!Punk::Auth::Password::verify('anything', undef),
    'an undef stored hash is false (the invited/federated-only user row)');
ok(!Punk::Auth::Password::verify('anything', ''), 'so is empty');
ok(!Punk::Auth::Password::verify('anything', 'not$a$hash'), 'and garbage');
ok(!Punk::Auth::Password::verify('anything',
    'pbkdf2-sha256$0$AAAA$AAAA'), 'zero iterations never verifies');
ok(!Punk::Auth::Password::verify('anything',
    'pbkdf2-sha256$1000$!!bad!!$AAAA'), 'bad base64 never verifies');

# ---- the cost travels in the string -------------------------------------------

{
    local $Punk::Auth::Password::ITERATIONS = 2_000;
    ok(Punk::Auth::Password::verify('correct horse battery staple', $h),
        'verify uses the stored cost, not the current one');
    ok(Punk::Auth::Password::needs_rehash($h),
        'and needs_rehash reports the old row');
    ok(!Punk::Auth::Password::needs_rehash(
        Punk::Auth::Password::hash('x')),
        'a current-cost hash does not need a rehash');
}
ok(!Punk::Auth::Password::needs_rehash($h),
    'back at 1_000, the old hash is current again');
ok(Punk::Auth::Password::needs_rehash($h, 5_000),
    'an explicit current-cost argument wins');
ok(Punk::Auth::Password::needs_rehash(undef), 'no hash at all: rehash');
ok(Punk::Auth::Password::needs_rehash('garbage'), 'unparseable: rehash');

# ---- explicit iterations argument ---------------------------------------------

my $cheap = Punk::Auth::Password::hash('pw', 500);
like($cheap, qr/^pbkdf2-sha256\$500\$/, 'an explicit cost beats the package var');
ok(Punk::Auth::Password::verify('pw', $cheap), 'and verifies');
{
    my $err = '';
    eval { Punk::Auth::Password::hash('pw', -1) } or $err = $@;
    like($err, qr/iterations must be positive/, 'a nonsense cost croaks');
}
{
    my $err = '';
    eval { Punk::Auth::Password::hash(undef) } or $err = $@;
    like($err, qr/needs a password/, 'hash without a password croaks');
}

# ---- tokens --------------------------------------------------------------------

my $t = Punk::Auth::Password::token();
is(length $t, 43, 'a token is 43 characters (32 bytes, unpadded base64url)');
like($t, qr/^[A-Za-z0-9_-]+$/, 'url-safe alphabet, no padding');
isnt($t, Punk::Auth::Password::token(), 'tokens are unique');

my $d = Punk::Auth::Password::token_digest($t);
like($d, qr/^[0-9a-f]{64}$/, 'the digest is lowercase sha256 hex');
is($d, Punk::Auth::Password::token_digest($t), 'and deterministic');
isnt($d, Punk::Auth::Password::token_digest('other'),
    'different tokens, different digests');

# the digest function matches what MaatSite::Password stored, so existing
# token rows keep working: sha256_hex("token") is a known constant
is(Punk::Auth::Password::token_digest('token'),
   '3c469e9d6c5875d37a43f353d4f88e61fcf812c66eee3457465a40b0da4153e0',
   'token_digest is plain sha256 hex (the stored production form)');

done_testing;
