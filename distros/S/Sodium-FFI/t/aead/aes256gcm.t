use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    crypto_aead_aes256gcm_is_available crypto_aead_aes256gcm_keygen
    crypto_aead_aes256gcm_decrypt crypto_aead_aes256gcm_encrypt
    randombytes_buf

    crypto_aead_aes256gcm_KEYBYTES
    crypto_aead_aes256gcm_ABYTES crypto_aead_aes256gcm_NPUBBYTES
);

plan skip_all => 'AEAD_AES256 Not Available.' unless crypto_aead_aes256gcm_is_available();

ok(crypto_aead_aes256gcm_KEYBYTES, 'crypto_aead_aes256gcm_KEYBYTES: got the constant');
ok(crypto_aead_aes256gcm_ABYTES, 'crypto_aead_aes256gcm_ABYTES: got the constant');
ok(crypto_aead_aes256gcm_NPUBBYTES, 'crypto_aead_aes256gcm_NPUBBYTES: got the constant');

my $key = crypto_aead_aes256gcm_keygen();
ok($key, 'crypto_aead_aes256gcm_keygen: got a key');
my $nonce = randombytes_buf(crypto_aead_aes256gcm_NPUBBYTES);
ok($nonce, 'nonce: got it');
my $msg = randombytes_buf(12); # just 12 bytes of random data
my $additional_data = randombytes_buf(12);

my $encrypted = crypto_aead_aes256gcm_encrypt($msg, $additional_data, $nonce, $key);
ok($encrypted, 'crypto_aead_aes256gcm_encrypt: Got back an encrypted message');
my $decrypted = crypto_aead_aes256gcm_decrypt($encrypted, $additional_data, $nonce, $key);
ok($decrypted, 'crypto_aead_aes256gcm_decrypt: Got back an decrypted message');
is($decrypted, $msg, 'Round-trip got us back our original message');

done_testing();
