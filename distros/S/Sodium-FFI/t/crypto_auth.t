use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    crypto_auth_KEYBYTES crypto_auth_BYTES
    crypto_auth_keygen crypto_auth
    crypto_auth_verify

    randombytes_buf
);


ok(crypto_auth_KEYBYTES, 'crypto_auth_KEYBYTES: got the constant');
ok(crypto_auth_BYTES, 'crypto_auth_BYTES: got the constant');

my $key = crypto_auth_keygen();
ok($key, 'crypto_auth_keygen: got a key');
my $msg = randombytes_buf(12); # just 12 bytes of random data

my $encrypted = crypto_auth($msg, $key);
ok($encrypted, 'crypto_auth: Got back an encrypted message');
my $ok = crypto_auth_verify($encrypted, $msg, $key);
ok($ok, 'crypto_auth_verify: Verified our message');

my $bad_msg = $msg;
substr($bad_msg, 0, 1) = chr(ord(substr($bad_msg, 0, 1)) ^ 0x80);
ok(!crypto_auth_verify($encrypted, $bad_msg, $key), "crypto_auth_verify: bad msg: not verified");
done_testing();
