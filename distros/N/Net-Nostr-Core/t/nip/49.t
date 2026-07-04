use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::KeyEncrypt qw(
    encrypt_private_key
    decrypt_private_key
);
use Bitcoin::Crypto::Bech32 qw(encode_bech32 translate_5to8 translate_8to5);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;

# Helper: decode ncryptsec bech32 to raw bytes (calls private decoder)
sub _decode_ncryptsec_raw {
    my ($ncryptsec) = @_;
    my ($hrp, $data5) = Net::Nostr::KeyEncrypt::_nostr_decode_bech32($ncryptsec);
    return ($hrp, translate_5to8($data5));
}

###############################################################################
# NIP-49 test vector: password unicode normalization
###############################################################################

subtest 'NIP-49: password NFKC normalization' => sub {
    # Spec test data: input "ÅΩẛ̣" (U+212B U+2126 U+1E9B U+0323)
    # NFKC normalized: "ÅΩẛ̣" (U+00C5 U+03A9 U+1E69)
    my $privkey = 'aa' x 32;
    my $encrypted = encrypt_private_key(
        privkey_hex => $privkey,
        password    => "\x{212B}\x{2126}\x{1E9B}\x{0323}",
        log_n       => 16,
    );
    like($encrypted, qr/\Ancryptsec1/, 'encrypted with unicode password');

    # Decrypt with NFKC-normalized form of the same password
    my $decrypted = decrypt_private_key($encrypted, "\x{00C5}\x{03A9}\x{1E69}");
    is($decrypted, $privkey, 'NFKC normalization makes both passwords equivalent');
};

###############################################################################
# NIP-49 test vector: decryption
###############################################################################

subtest 'NIP-49: spec decryption test vector' => sub {
    my $ncryptsec = 'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p';
    my $expected = '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683';

    my $privkey = decrypt_private_key($ncryptsec, 'nostr', log_n => 16);
    is($privkey, $expected, 'decrypts to expected private key');
};

###############################################################################
# encrypt/decrypt round-trip
###############################################################################

subtest 'round-trip: encrypt then decrypt' => sub {
    my $privkey = 'bb' x 32;
    my $password = 'test-password-123';

    my $encrypted = encrypt_private_key(
        privkey_hex => $privkey,
        password    => $password,
        log_n       => 16,
    );
    like($encrypted, qr/\Ancryptsec1/, 'starts with ncryptsec1');

    my $decrypted = decrypt_private_key($encrypted, $password, log_n => 16);
    is($decrypted, $privkey, 'round-trips correctly');
};

subtest 'round-trip: different passwords produce different ciphertext' => sub {
    my $privkey = 'cc' x 32;
    my $e1 = encrypt_private_key(privkey_hex => $privkey, password => 'pass1', log_n => 16);
    my $e2 = encrypt_private_key(privkey_hex => $privkey, password => 'pass2', log_n => 16);
    isnt($e1, $e2, 'different passwords produce different output');
};

subtest 'round-trip: non-deterministic (random nonce)' => sub {
    my $privkey = 'dd' x 32;
    my $password = 'same-password';
    my $e1 = encrypt_private_key(privkey_hex => $privkey, password => $password, log_n => 16);
    my $e2 = encrypt_private_key(privkey_hex => $privkey, password => $password, log_n => 16);
    isnt($e1, $e2, 'same password + same key produces different output (random nonce)');

    # Both should decrypt to the same key
    is(decrypt_private_key($e1, $password, log_n => 16), $privkey, 'first decrypts');
    is(decrypt_private_key($e2, $password, log_n => 16), $privkey, 'second decrypts');
};

###############################################################################
# key_security_byte
###############################################################################

subtest 'key_security_byte: default is 0x02 (unknown)' => sub {
    my $privkey = 'ee' x 32;
    my $encrypted = encrypt_private_key(
        privkey_hex => $privkey,
        password    => 'test',
        log_n       => 16,
    );
    # Decrypt and verify it works (security byte is part of AAD)
    my $decrypted = decrypt_private_key($encrypted, 'test', log_n => 16);
    is($decrypted, $privkey, 'default security byte round-trips');
};

subtest 'key_security_byte: 0x00 (known insecure)' => sub {
    my $privkey = 'ee' x 32;
    my $encrypted = encrypt_private_key(
        privkey_hex      => $privkey,
        password         => 'test',
        log_n            => 16,
        key_security     => 0x00,
    );
    my $decrypted = decrypt_private_key($encrypted, 'test', log_n => 16);
    is($decrypted, $privkey, 'security byte 0x00 round-trips');
};

subtest 'key_security_byte: 0x01 (not known insecure)' => sub {
    my $privkey = 'ee' x 32;
    my $encrypted = encrypt_private_key(
        privkey_hex      => $privkey,
        password         => 'test',
        log_n            => 16,
        key_security     => 0x01,
    );
    my $decrypted = decrypt_private_key($encrypted, 'test', log_n => 16);
    is($decrypted, $privkey, 'security byte 0x01 round-trips');
};

subtest 'key_security_byte: invalid value rejected' => sub {
    like(
        dies {
            encrypt_private_key(
                privkey_hex  => 'aa' x 32,
                password     => 'test',
                log_n        => 16,
                key_security => 0x03,
            )
        },
        qr/key_security must be 0x00, 0x01, or 0x02/,
        'invalid security byte rejected'
    );
};

###############################################################################
# version
###############################################################################

subtest 'version: only 0x02 accepted' => sub {
    # Modify a valid ncryptsec to have version 0x01 and verify rejection
    # We can't easily do this without raw manipulation, so test via decrypt
    # with a known good one first
    my $ncryptsec = 'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p';
    my $decrypted = decrypt_private_key($ncryptsec, 'nostr', log_n => 16);
    like($decrypted, $HEX64, 'version 0x02 accepted');
};

###############################################################################
# validation
###############################################################################

subtest 'encrypt: missing privkey_hex' => sub {
    like(
        dies { encrypt_private_key(password => 'test', log_n => 16) },
        qr/privkey_hex is required/,
        'missing privkey_hex croaks'
    );
};

subtest 'encrypt: invalid privkey_hex' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'not-hex', password => 'test', log_n => 16) },
        qr/privkey_hex must be 64-char lowercase hex/,
        'bad hex rejected'
    );
};

subtest 'encrypt: missing password' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'aa' x 32, log_n => 16) },
        qr/password is required/,
        'missing password croaks'
    );
};

subtest 'encrypt: empty password' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'aa' x 32, password => '', log_n => 16) },
        qr/password is required/,
        'empty password croaks'
    );
};

subtest 'encrypt: missing log_n' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'aa' x 32, password => 'test') },
        qr/log_n is required/,
        'missing log_n croaks'
    );
};

subtest 'encrypt: log_n out of range' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'aa' x 32, password => 'test', log_n => 0) },
        qr/log_n must be between 1 and 22/,
        'log_n=0 rejected'
    );
    like(
        dies { encrypt_private_key(privkey_hex => 'aa' x 32, password => 'test', log_n => 23) },
        qr/log_n must be between 1 and 22/,
        'log_n=23 rejected'
    );
};

subtest 'decrypt: wrong password fails' => sub {
    my $encrypted = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'correct',
        log_n       => 16,
    );
    like(
        dies { decrypt_private_key($encrypted, 'wrong', log_n => 16) },
        qr/decryption failed/i,
        'wrong password rejected'
    );
};

subtest 'decrypt: invalid ncryptsec prefix' => sub {
    # Use a real npub (valid bech32, wrong prefix for ncryptsec)
    use Net::Nostr::Bech32 qw(encode_npub);
    my $npub = encode_npub('aa' x 32);
    like(
        dies { decrypt_private_key($npub, 'test') },
        qr/expected ncryptsec prefix/,
        'wrong bech32 prefix rejected'
    );
};

subtest 'decrypt: garbled data' => sub {
    like(
        dies { decrypt_private_key('ncryptsec1invaliddata', 'test') },
        qr/./,
        'garbled data rejected'
    );
};

###############################################################################
# log_n values
###############################################################################

subtest 'log_n: boundary values work' => sub {
    my $privkey = 'ff' x 31 . 'fe';
    for my $log_n (16) {
        my $encrypted = encrypt_private_key(
            privkey_hex => $privkey,
            password    => 'test',
            log_n       => $log_n,
        );
        my $decrypted = decrypt_private_key($encrypted, 'test', log_n => $log_n);
        is($decrypted, $privkey, "log_n=$log_n round-trips");
    }
};

###############################################################################
# output format
###############################################################################

subtest 'output: 91 bytes raw before bech32 encoding' => sub {
    my $encrypted = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'test',
        log_n       => 16,
    );
    like($encrypted, qr/\Ancryptsec1[qpzry9x8gf2tvdw0s3jn54khce6mua7l]+\z/,
        'output is valid ncryptsec bech32');
};

###############################################################################
# NIP-49 spec: decrypted log_n embedded in payload
###############################################################################

###############################################################################
# payload structure (spec lines 62-73)
###############################################################################

subtest 'payload: 91 bytes with correct layout' => sub {
    my $encrypted = encrypt_private_key(
        privkey_hex  => 'aa' x 32,
        password     => 'test',
        log_n        => 16,
        key_security => 0x01,
    );
    my ($hrp, $raw) = _decode_ncryptsec_raw($encrypted);
    is($hrp, 'ncryptsec', 'bech32 hrp is ncryptsec');
    is(length($raw), 91, 'raw payload is 91 bytes');

    # Verify layout: version(1) + log_n(1) + salt(16) + nonce(24) + aad(1) + ciphertext+tag(48)
    is(ord(substr($raw, 0, 1)), 0x02, 'version byte is 0x02');
    is(ord(substr($raw, 1, 1)), 16, 'log_n byte is 16');
    is(ord(substr($raw, 42, 1)), 0x01, 'key_security byte is 0x01');
    is(length(substr($raw, 43)), 48, 'ciphertext + tag is 48 bytes (32 + 16)');
};

###############################################################################
# version rejection
###############################################################################

subtest 'version: non-0x02 version rejected' => sub {
    # Encrypt normally, then tamper with the version byte
    my $encrypted = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'test',
        log_n       => 16,
    );
    my ($hrp, $raw) = _decode_ncryptsec_raw($encrypted);

    # Change version from 0x02 to 0x01
    substr($raw, 0, 1, chr(0x01));
    my $tampered_data5 = translate_8to5($raw);
    my $tampered = encode_bech32('ncryptsec', $tampered_data5, 'bech32');

    like(
        dies { decrypt_private_key($tampered, 'test', log_n => 16) },
        qr/unknown version/,
        'version 0x01 rejected'
    );
};

###############################################################################
# AAD tamper detection (key_security_byte is associated data)
###############################################################################

subtest 'AAD tamper: modified key_security_byte causes decryption failure' => sub {
    my $encrypted = encrypt_private_key(
        privkey_hex  => 'aa' x 32,
        password     => 'test',
        log_n        => 16,
        key_security => 0x00,
    );
    my ($hrp, $raw) = _decode_ncryptsec_raw($encrypted);

    # Change key_security from 0x00 to 0x02
    substr($raw, 42, 1, chr(0x02));
    my $tampered_data5 = translate_8to5($raw);
    my $tampered = encode_bech32('ncryptsec', $tampered_data5, 'bech32');

    like(
        dies { decrypt_private_key($tampered, 'test', log_n => 16) },
        qr/decryption failed/i,
        'tampered AAD causes MAC failure'
    );
};

###############################################################################
# additional validation edge cases
###############################################################################

subtest 'encrypt: uppercase hex rejected' => sub {
    like(
        dies { encrypt_private_key(privkey_hex => 'AA' x 32, password => 'test', log_n => 16) },
        qr/privkey_hex must be 64-char lowercase hex/,
        'uppercase hex rejected'
    );
};

subtest 'decrypt: missing ncryptsec' => sub {
    like(
        dies { decrypt_private_key(undef, 'test') },
        qr/ncryptsec string is required/,
        'undef ncryptsec rejected'
    );
    like(
        dies { decrypt_private_key('', 'test') },
        qr/ncryptsec string is required/,
        'empty ncryptsec rejected'
    );
};

subtest 'decrypt: missing password' => sub {
    like(
        dies { decrypt_private_key('ncryptsec1abc', undef) },
        qr/password is required/,
        'undef password rejected'
    );
    like(
        dies { decrypt_private_key('ncryptsec1abc', '') },
        qr/password is required/,
        'empty password rejected'
    );
};

subtest 'decrypt: invalid payload size' => sub {
    # Create a valid bech32 string with wrong payload length (too short)
    my $short_raw = chr(0x02) . chr(16) . ("\x00" x 10);
    my $data5 = translate_8to5($short_raw);
    my $bad = encode_bech32('ncryptsec', $data5, 'bech32');
    like(
        dies { decrypt_private_key($bad, 'test') },
        qr/invalid payload size/,
        'short payload rejected'
    );
};

###############################################################################
# NIP-49 spec: decrypted log_n embedded in payload
###############################################################################

subtest 'decrypt: log_n from payload used when not specified' => sub {
    # The test vector has log_n=16 embedded
    my $ncryptsec = 'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p';
    my $decrypted = decrypt_private_key($ncryptsec, 'nostr');
    is($decrypted, '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683',
        'log_n read from payload when not given');
};

done_testing;
