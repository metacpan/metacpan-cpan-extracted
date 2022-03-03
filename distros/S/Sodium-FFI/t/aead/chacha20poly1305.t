use strict;
use warnings;
use Test::More;
use Sodium::FFI qw(
    crypto_aead_chacha20poly1305_KEYBYTES crypto_aead_chacha20poly1305_ABYTES
    crypto_aead_chacha20poly1305_NPUBBYTES
    crypto_aead_chacha20poly1305_keygen crypto_aead_chacha20poly1305_encrypt
    crypto_aead_chacha20poly1305_decrypt

    randombytes_buf
);


ok(crypto_aead_chacha20poly1305_KEYBYTES, 'crypto_aead_chacha20poly1305_KEYBYTES: got the constant');
ok(crypto_aead_chacha20poly1305_ABYTES, 'crypto_aead_chacha20poly1305_ABYTES: got the constant');
ok(crypto_aead_chacha20poly1305_NPUBBYTES, 'crypto_aead_chacha20poly1305_NPUBBYTES: got the constant');

{
    my $key = crypto_aead_chacha20poly1305_keygen();
    ok($key, 'crypto_aead_chacha20poly1305_keygen: got a key');
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_NPUBBYTES);
    ok($nonce, 'nonce: got it');
    my $msg = randombytes_buf(12); # just 12 bytes of random data
    my $additional_data = randombytes_buf(12);

    my $encrypted = crypto_aead_chacha20poly1305_encrypt($msg, $additional_data, $nonce, $key);
    ok($encrypted, 'crypto_aead_chacha20poly1305_encrypt: Got back an encrypted message');
    my $decrypted = crypto_aead_chacha20poly1305_decrypt($encrypted, $additional_data, $nonce, $key);
    ok($decrypted, 'crypto_aead_chacha20poly1305_decrypt: Got back an decrypted message');
    is($decrypted, $msg, 'Round-trip got us back our original message');
}

# now with no additional data
{
    my $key = crypto_aead_chacha20poly1305_keygen();
    ok($key, 'crypto_aead_chacha20poly1305_keygen: got a key');
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_NPUBBYTES);
    ok($nonce, 'nonce: got it');
    my $msg = randombytes_buf(12); # just 12 bytes of random data
    my $additional_data = undef;

    my $encrypted = crypto_aead_chacha20poly1305_encrypt($msg, $additional_data, $nonce, $key);
    ok($encrypted, 'crypto_aead_chacha20poly1305_encrypt: Got back an encrypted message');
    my $decrypted = crypto_aead_chacha20poly1305_decrypt($encrypted, $additional_data, $nonce, $key);
    ok($decrypted, 'crypto_aead_chacha20poly1305_decrypt: Got back an decrypted message');
    is($decrypted, $msg, 'Round-trip got us back our original message');
}
done_testing();
