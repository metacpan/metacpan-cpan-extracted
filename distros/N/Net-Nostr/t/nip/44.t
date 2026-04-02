#!/usr/bin/perl

# NIP-44: Encrypted Payloads (Versioned)
# https://github.com/nostr-protocol/nips/blob/master/44.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;
use Encode;
use Crypt::PK::ECC;

use lib 't/lib';

use Net::Nostr::Encryption;
use Net::Nostr::Key;

# Load official test vectors
my $vectors_file = 't/data/nip44.vectors.json';
my $vectors;
{
    open my $fh, '<', $vectors_file or die "Cannot open $vectors_file: $!";
    local $/;
    $vectors = JSON::decode_json(<$fh>);
}
my $v2 = $vectors->{v2};

###############################################################################
# get_conversation_key - valid vectors
###############################################################################

subtest 'get_conversation_key - valid vectors' => sub {
    for my $vec (@{$v2->{valid}{get_conversation_key}}) {
        my $conv_key = Net::Nostr::Encryption->get_conversation_key(
            $vec->{sec1}, $vec->{pub2},
        );
        is unpack('H*', $conv_key), $vec->{conversation_key},
            "sec1=${\substr($vec->{sec1},0,8)}... pub2=${\substr($vec->{pub2},0,8)}...";
    }
};

###############################################################################
# get_conversation_key - invalid vectors
###############################################################################

subtest 'get_conversation_key - invalid vectors' => sub {
    for my $vec (@{$v2->{invalid}{get_conversation_key}}) {
        ok dies {
            Net::Nostr::Encryption->get_conversation_key($vec->{sec1}, $vec->{pub2});
        }, "dies: $vec->{note}";
    }
};

###############################################################################
# get_message_keys
###############################################################################

subtest 'get_message_keys' => sub {
    my $conv_key_hex = $v2->{valid}{get_message_keys}{conversation_key};
    my $conv_key = pack('H*', $conv_key_hex);
    for my $vec (@{$v2->{valid}{get_message_keys}{keys}}) {
        my ($ck, $cn, $hk) = Net::Nostr::Encryption->get_message_keys(
            $conv_key, pack('H*', $vec->{nonce}),
        );
        is unpack('H*', $ck), $vec->{chacha_key},   "chacha_key for nonce=${\substr($vec->{nonce},0,8)}...";
        is unpack('H*', $cn), $vec->{chacha_nonce},  "chacha_nonce";
        is unpack('H*', $hk), $vec->{hmac_key},      "hmac_key";
    }
};

###############################################################################
# calc_padded_len
###############################################################################

subtest 'calc_padded_len' => sub {
    for my $vec (@{$v2->{valid}{calc_padded_len}}) {
        my ($input, $expected) = @$vec;
        my $got = Net::Nostr::Encryption->calc_padded_len($input);
        is $got, $expected, "calc_padded_len($input) == $expected";
    }
};

###############################################################################
# encrypt_decrypt - valid vectors
###############################################################################

subtest 'encrypt_decrypt - valid vectors' => sub {
    for my $vec (@{$v2->{valid}{encrypt_decrypt}}) {
        my $conv_key = pack('H*', $vec->{conversation_key});
        my $nonce    = pack('H*', $vec->{nonce});

        # encrypt with known nonce
        my $payload = Net::Nostr::Encryption->encrypt(
            $vec->{plaintext}, $conv_key, $nonce,
        );
        is $payload, $vec->{payload}, "encrypt: '${\substr($vec->{plaintext},0,20)}...'";

        # decrypt
        my $plaintext = Net::Nostr::Encryption->decrypt($vec->{payload}, $conv_key);
        is $plaintext, $vec->{plaintext}, "decrypt roundtrip";

        # verify conversation_key from sec1/sec2
        my $pk2 = Crypt::PK::ECC->new;
        $pk2->import_key_raw(pack('H*', $vec->{sec2}), 'secp256k1');
        my $pub2 = substr($pk2->export_key_raw('public'), 1, 32);
        my $got_conv = Net::Nostr::Encryption->get_conversation_key(
            $vec->{sec1}, unpack('H*', $pub2),
        );
        is unpack('H*', $got_conv), $vec->{conversation_key},
            "conversation_key from sec1+pub2";

        # verify symmetry: conv(sec2, pub1) == conv(sec1, pub2)
        my $pk1 = Crypt::PK::ECC->new;
        $pk1->import_key_raw(pack('H*', $vec->{sec1}), 'secp256k1');
        my $pub1 = substr($pk1->export_key_raw('public'), 1, 32);
        my $rev_conv = Net::Nostr::Encryption->get_conversation_key(
            $vec->{sec2}, unpack('H*', $pub1),
        );
        is unpack('H*', $rev_conv), $vec->{conversation_key},
            "conversation_key symmetric";
    }
};

###############################################################################
# encrypt_decrypt_long_msg - valid vectors (checksum-based)
###############################################################################

subtest 'encrypt_decrypt_long_msg' => sub {
    require Digest::SHA;
    for my $vec (@{$v2->{valid}{encrypt_decrypt_long_msg}}) {
        my $conv_key = pack('H*', $vec->{conversation_key});
        my $nonce    = pack('H*', $vec->{nonce});

        # Build plaintext from pattern x repeat
        my $plaintext = $vec->{pattern} x $vec->{repeat};

        # Verify plaintext checksum
        my $pt_bytes = Encode::encode('UTF-8', $plaintext);
        is Digest::SHA::sha256_hex($pt_bytes), $vec->{plaintext_sha256},
            "plaintext sha256 for pattern='$vec->{pattern}' repeat=$vec->{repeat}";

        # Encrypt
        my $payload = Net::Nostr::Encryption->encrypt($plaintext, $conv_key, $nonce);

        # Verify payload checksum
        is Digest::SHA::sha256_hex($payload), $vec->{payload_sha256},
            "payload sha256";

        # Decrypt and verify roundtrip
        my $decrypted = Net::Nostr::Encryption->decrypt($payload, $conv_key);
        is $decrypted, $plaintext, "decrypt roundtrip for long msg";
    }
};

###############################################################################
# invalid decrypt
###############################################################################

subtest 'invalid decrypt' => sub {
    for my $vec (@{$v2->{invalid}{decrypt}}) {
        my $conv_key = pack('H*', $vec->{conversation_key});
        ok dies {
            Net::Nostr::Encryption->decrypt($vec->{payload}, $conv_key);
        }, "dies: $vec->{note}";
    }
};

###############################################################################
# invalid encrypt message lengths
###############################################################################

subtest 'invalid encrypt_msg_lengths' => sub {
    for my $vec (@{$v2->{invalid}{encrypt_msg_lengths}}) {
        my $conv_key = pack('H*', '0' x 64);  # dummy key
        my $nonce    = pack('H*', '0' x 64);
        ok dies {
            Net::Nostr::Encryption->encrypt(
                'x' x $vec, $conv_key, $nonce,
            );
        }, "dies for msg length $vec";
    }
};

###############################################################################
# conversation_key is symmetric
###############################################################################

subtest 'conversation_key symmetry' => sub {
    my $key_a = Net::Nostr::Key->new;
    my $key_b = Net::Nostr::Key->new;

    my $conv_ab = Net::Nostr::Encryption->get_conversation_key(
        $key_a->privkey_hex, $key_b->pubkey_hex,
    );
    my $conv_ba = Net::Nostr::Encryption->get_conversation_key(
        $key_b->privkey_hex, $key_a->pubkey_hex,
    );
    is unpack('H*', $conv_ab), unpack('H*', $conv_ba),
        'conv(a,B) == conv(b,A)';
};

###############################################################################
# encrypt/decrypt with Key objects
###############################################################################

subtest 'encrypt/decrypt with Key objects' => sub {
    my $alice = Net::Nostr::Key->new;
    my $bob   = Net::Nostr::Key->new;

    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $alice->privkey_hex, $bob->pubkey_hex,
    );

    my $plaintext = 'Hello, Bob!';
    my $payload = Net::Nostr::Encryption->encrypt($plaintext, $conv_key);

    # Bob decrypts
    my $conv_key2 = Net::Nostr::Encryption->get_conversation_key(
        $bob->privkey_hex, $alice->pubkey_hex,
    );
    my $decrypted = Net::Nostr::Encryption->decrypt($payload, $conv_key2);
    is $decrypted, $plaintext, 'Alice encrypts, Bob decrypts';
};

###############################################################################
# payload starts with version byte 0x02
###############################################################################

subtest 'payload format' => sub {
    my $conv_key = pack('H*', 'c41c775356fd92eadc63ff5a0dc1da211b268cbea22316767095b2871ea1412d');
    my $payload = Net::Nostr::Encryption->encrypt('test', $conv_key);

    # payload is base64 and starts with version 2 byte
    use MIME::Base64;
    my $raw = decode_base64($payload);
    is ord(substr($raw, 0, 1)), 2, 'version byte is 2';
    is length($raw), 99, 'raw payload length for short message (1+32+34+32)';
};

###############################################################################
# plaintext length limits
###############################################################################

subtest 'plaintext length validation' => sub {
    my $conv_key = pack('H*', '0' x 64);

    ok dies { Net::Nostr::Encryption->encrypt('', $conv_key) },
        'empty plaintext rejected';

    ok dies { Net::Nostr::Encryption->encrypt('x' x 65536, $conv_key) },
        'plaintext > 65535 bytes rejected';

    ok lives { Net::Nostr::Encryption->encrypt('x', $conv_key) },
        'single byte plaintext ok';

    ok lives { Net::Nostr::Encryption->encrypt('x' x 65535, $conv_key) },
        '65535 byte plaintext ok';
};

###############################################################################
# # prefix means unsupported version
###############################################################################

subtest 'hash prefix means unsupported version' => sub {
    my $conv_key = pack('H*', '0' x 64);
    like dies { Net::Nostr::Encryption->decrypt('#something', $conv_key) },
        qr/unknown version|unsupported/i, '# prefix triggers version error';
};

###############################################################################
# MAC validation (tampered ciphertext)
###############################################################################

subtest 'MAC validation rejects tampered payload' => sub {
    my $conv_key = pack('H*', 'c41c775356fd92eadc63ff5a0dc1da211b268cbea22316767095b2871ea1412d');
    my $payload = Net::Nostr::Encryption->encrypt('hello world', $conv_key);

    use MIME::Base64;
    my $raw = decode_base64($payload);
    # Flip a bit in the ciphertext
    substr($raw, 40, 1) = chr(ord(substr($raw, 40, 1)) ^ 0x01);
    my $tampered = encode_base64($raw, '');

    ok dies { Net::Nostr::Encryption->decrypt($tampered, $conv_key) },
        'tampered ciphertext rejected';
};

done_testing;
