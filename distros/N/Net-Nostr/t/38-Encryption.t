#!/usr/bin/perl

# Unit tests for Net::Nostr::Encryption
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;

use JSON ();
use Net::Nostr::Encryption;
use Net::Nostr::Key;
use MIME::Base64 ();

my $E = 'Net::Nostr::Encryption';

# Generate two keypairs for use throughout tests
my $alice = Net::Nostr::Key->new;
my $bob   = Net::Nostr::Key->new;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: full round-trip' => sub {
    my $conv_key = $E->get_conversation_key(
        $alice->privkey_hex, $bob->pubkey_hex,
    );

    my $payload = $E->encrypt('Hello, Bob!', $conv_key);

    my $conv_key2 = $E->get_conversation_key(
        $bob->privkey_hex, $alice->pubkey_hex,
    );
    my $plaintext = $E->decrypt($payload, $conv_key2);
    is($plaintext, 'Hello, Bob!', 'round-trip matches');
};

###############################################################################
# calc_padded_len() POD examples
###############################################################################

subtest 'calc_padded_len: POD examples' => sub {
    is($E->calc_padded_len(1),   32,  'calc_padded_len(1) == 32');
    is($E->calc_padded_len(32),  32,  'calc_padded_len(32) == 32');
    is($E->calc_padded_len(33),  64,  'calc_padded_len(33) == 64');
    is($E->calc_padded_len(257), 320, 'calc_padded_len(257) == 320');
};

subtest 'calc_padded_len: boundary values' => sub {
    is($E->calc_padded_len(31),  32,  'calc_padded_len(31) == 32');
    is($E->calc_padded_len(64),  64,  'calc_padded_len(64) == 64');
    is($E->calc_padded_len(65),  96,  'calc_padded_len(65) == 96');
    is($E->calc_padded_len(128), 128, 'calc_padded_len(128) == 128');
    is($E->calc_padded_len(129), 160, 'calc_padded_len(129) == 160');
    is($E->calc_padded_len(256), 256, 'calc_padded_len(256) == 256');
};

subtest 'calc_padded_len: always >= input' => sub {
    for my $len (1, 2, 15, 16, 31, 32, 33, 63, 64, 65, 100, 255, 256, 257, 512, 1000) {
        my $padded = $E->calc_padded_len($len);
        ok($padded >= $len, "calc_padded_len($len) = $padded >= $len");
    }
};

###############################################################################
# get_conversation_key()
###############################################################################

subtest 'get_conversation_key: symmetry' => sub {
    my $key_ab = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $key_ba = $E->get_conversation_key($bob->privkey_hex, $alice->pubkey_hex);
    is($key_ab, $key_ba, 'key(a_priv, b_pub) == key(b_priv, a_pub)');
};

subtest 'get_conversation_key: returns 32 raw bytes' => sub {
    my $key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    is(length($key), 32, '32 bytes');
};

subtest 'get_conversation_key: deterministic' => sub {
    my $key1 = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $key2 = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    is($key1, $key2, 'same inputs produce same key');
};

subtest 'get_conversation_key: rejects invalid private key' => sub {
    like(
        dies { $E->get_conversation_key('ff' x 32, $bob->pubkey_hex) },
        qr/invalid private key/,
        'private key above curve order rejected'
    );
    like(
        dies { $E->get_conversation_key('00' x 32, $bob->pubkey_hex) },
        qr/invalid private key/,
        'zero private key rejected'
    );
};

subtest 'get_conversation_key: rejects invalid public key' => sub {
    like(
        dies { $E->get_conversation_key($alice->privkey_hex, '00' x 32) },
        qr/invalid public key/,
        'zero public key rejected'
    );
};

###############################################################################
# get_message_keys()
###############################################################################

subtest 'get_message_keys: returns correct sizes' => sub {
    my $conv_key = "\x01" x 32;
    my $nonce    = "\x02" x 32;
    my ($chacha_key, $chacha_nonce, $hmac_key) = $E->get_message_keys($conv_key, $nonce);
    is(length($chacha_key),   32, 'chacha_key is 32 bytes');
    is(length($chacha_nonce), 12, 'chacha_nonce is 12 bytes');
    is(length($hmac_key),     32, 'hmac_key is 32 bytes');
};

subtest 'get_message_keys: deterministic' => sub {
    my $conv_key = "\x01" x 32;
    my $nonce    = "\x02" x 32;
    my @keys1 = $E->get_message_keys($conv_key, $nonce);
    my @keys2 = $E->get_message_keys($conv_key, $nonce);
    is(\@keys1, \@keys2, 'same inputs produce same keys');
};

subtest 'get_message_keys: different nonces produce different keys' => sub {
    my $conv_key = "\x01" x 32;
    my ($ck1) = $E->get_message_keys($conv_key, "\x02" x 32);
    my ($ck2) = $E->get_message_keys($conv_key, "\x03" x 32);
    isnt($ck1, $ck2, 'different nonces yield different chacha keys');
};

subtest 'get_message_keys: rejects wrong-length conversation_key' => sub {
    like(
        dies { $E->get_message_keys("\x01" x 31, "\x02" x 32) },
        qr/invalid conversation_key length/,
        'short conversation_key rejected'
    );
    like(
        dies { $E->get_message_keys("\x01" x 33, "\x02" x 32) },
        qr/invalid conversation_key length/,
        'long conversation_key rejected'
    );
};

subtest 'get_message_keys: rejects wrong-length nonce' => sub {
    like(
        dies { $E->get_message_keys("\x01" x 32, "\x02" x 31) },
        qr/invalid nonce length/,
        'short nonce rejected'
    );
    like(
        dies { $E->get_message_keys("\x01" x 32, "\x02" x 33) },
        qr/invalid nonce length/,
        'long nonce rejected'
    );
};

###############################################################################
# encrypt() / decrypt() round-trip
###############################################################################

subtest 'encrypt/decrypt: basic round-trip with random nonce' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('test message', $conv_key);
    my $result  = $E->decrypt($payload, $conv_key);
    is($result, 'test message', 'round-trip');
};

subtest 'encrypt/decrypt: deterministic with explicit nonce' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $nonce    = "\xaa" x 32;
    my $payload1 = $E->encrypt('deterministic', $conv_key, $nonce);
    my $payload2 = $E->encrypt('deterministic', $conv_key, $nonce);
    is($payload1, $payload2, 'same nonce produces same ciphertext');
    my $result = $E->decrypt($payload1, $conv_key);
    is($result, 'deterministic', 'decrypts correctly');
};

subtest 'encrypt/decrypt: UTF-8 content' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);

    my $emoji = "\x{1F525}\x{1F680}";  # fire + rocket
    my $payload = $E->encrypt($emoji, $conv_key);
    my $result  = $E->decrypt($payload, $conv_key);
    is($result, $emoji, 'emoji round-trip');

    my $non_ascii = "caf\x{e9} na\x{ef}ve \x{2603}";
    $payload = $E->encrypt($non_ascii, $conv_key);
    $result  = $E->decrypt($payload, $conv_key);
    is($result, $non_ascii, 'non-ASCII round-trip');
};

subtest 'encrypt: rejects empty plaintext' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    like(
        dies { $E->encrypt('', $conv_key) },
        qr/invalid plaintext length/,
        'empty plaintext rejected'
    );
};

subtest 'encrypt: output is base64' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('hello', $conv_key);
    like($payload, qr{^[A-Za-z0-9+/]+=*$}, 'payload is base64');
};

subtest 'encrypt: different nonces produce different ciphertexts' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $nonce1   = "\x01" x 32;
    my $nonce2   = "\x02" x 32;
    my $p1 = $E->encrypt('same text', $conv_key, $nonce1);
    my $p2 = $E->encrypt('same text', $conv_key, $nonce2);
    isnt($p1, $p2, 'different nonces produce different ciphertexts');
};

###############################################################################
# encrypt() POD examples
###############################################################################

subtest 'encrypt: POD example' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('secret message', $conv_key);
    ok(length($payload) > 0, 'produces payload');
};

###############################################################################
# decrypt() POD examples
###############################################################################

subtest 'decrypt: POD example' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('secret message', $conv_key);
    my $msg = $E->decrypt($payload, $conv_key);
    is($msg, 'secret message', 'decrypt POD example');
};

###############################################################################
# decrypt() error cases
###############################################################################

subtest 'decrypt: rejects non-base64 payload' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    like(
        dies { $E->decrypt('!!!not-base64!!!', $conv_key) },
        qr/invalid (payload|data) size/,
        'non-base64 rejected'
    );
};

subtest 'decrypt: rejects truncated payload' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('hello', $conv_key);
    my $truncated = substr($payload, 0, 20);
    like(
        dies { $E->decrypt($truncated, $conv_key) },
        qr/invalid (payload|data) size/,
        'truncated payload rejected'
    );
};

subtest 'decrypt: rejects tampered ciphertext (invalid MAC)' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload = $E->encrypt('hello world', $conv_key);

    # Decode, flip a byte in the ciphertext, re-encode
    my $raw = MIME::Base64::decode_base64($payload);
    # Ciphertext starts at offset 33, flip a byte in the middle
    my $mid = 33 + int((length($raw) - 65) / 2);
    substr($raw, $mid, 1) = chr(ord(substr($raw, $mid, 1)) ^ 0xFF);
    my $tampered = MIME::Base64::encode_base64($raw, '');

    like(
        dies { $E->decrypt($tampered, $conv_key) },
        qr/invalid MAC/,
        'tampered ciphertext rejected'
    );
};

subtest 'decrypt: rejects wrong conversation key' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $payload  = $E->encrypt('secret', $conv_key);

    # Use a different conversation key
    my $carol     = Net::Nostr::Key->new;
    my $wrong_key = $E->get_conversation_key($carol->privkey_hex, $bob->pubkey_hex);

    like(
        dies { $E->decrypt($payload, $wrong_key) },
        qr/invalid MAC/,
        'wrong conversation key rejected'
    );
};

subtest 'decrypt: rejects empty payload' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    like(
        dies { $E->decrypt('', $conv_key) },
        qr/(unknown version|invalid (payload|data) size)/,
        'empty payload rejected'
    );
};

subtest 'decrypt: rejects v1-style payload starting with #' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    like(
        dies { $E->decrypt('#' . ('A' x 200), $conv_key) },
        qr/unknown version/,
        'v1-style payload rejected'
    );
};

###############################################################################
# get_conversation_key() POD examples
###############################################################################

subtest 'get_conversation_key: POD example' => sub {
    my $conv = $E->get_conversation_key(
        $alice->privkey_hex, $bob->pubkey_hex,
    );
    ok(defined $conv && length($conv) == 32, 'returns 32-byte key');
};

###############################################################################
# get_message_keys() POD example
###############################################################################

subtest 'get_message_keys: POD example' => sub {
    my $conv_key = $E->get_conversation_key($alice->privkey_hex, $bob->pubkey_hex);
    my $nonce    = "\x00" x 32;
    my ($chacha_key, $chacha_nonce, $hmac_key) =
        $E->get_message_keys($conv_key, $nonce);
    is(length($chacha_key),   32, 'chacha_key 32 bytes');
    is(length($chacha_nonce), 12, 'chacha_nonce 12 bytes');
    is(length($hmac_key),     32, 'hmac_key 32 bytes');
};

###############################################################################
# get_conversation_key rejects invalid hex
###############################################################################

subtest 'get_conversation_key rejects non-hex privkey' => sub {
    my $key = Net::Nostr::Key->new;
    like(
        dies { $E->get_conversation_key('not_hex_at_all!', $key->pubkey_hex) },
        qr/privkey_hex must be 64-char lowercase hex/,
        'non-hex privkey rejected'
    );
};

subtest 'get_conversation_key rejects non-hex pubkey' => sub {
    my $key = Net::Nostr::Key->new;
    like(
        dies { $E->get_conversation_key($key->privkey_hex, 'ZZZZ' x 16) },
        qr/pubkey_hex must be 64-char lowercase hex/,
        'non-hex pubkey rejected'
    );
};

done_testing;
