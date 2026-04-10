use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::KeyEncrypt qw(
    encrypt_private_key
    decrypt_private_key
);

###############################################################################
# POD example: encrypt then decrypt
###############################################################################

subtest 'POD: encrypt and decrypt round-trip' => sub {
    my $ncryptsec = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'my-strong-password',
        log_n       => 16,
    );
    like($ncryptsec, qr/\Ancryptsec1/, 'encrypt returns ncryptsec1...');

    my $privkey_hex = decrypt_private_key($ncryptsec, 'my-strong-password');
    is($privkey_hex, 'aa' x 32, 'decrypt recovers original key');
};

###############################################################################
# POD example: key_security level
###############################################################################

subtest 'POD: key_security 0x01' => sub {
    my $privkey_hex = 'bb' x 32;
    my $password    = 'test-password';
    my $ncryptsec = encrypt_private_key(
        privkey_hex  => $privkey_hex,
        password     => $password,
        log_n        => 20,
        key_security => 0x01,
    );
    like($ncryptsec, qr/\Ancryptsec1/, 'encrypted with key_security 0x01');
    my $decrypted = decrypt_private_key($ncryptsec, $password);
    is($decrypted, $privkey_hex, 'round-trips with key_security 0x01');
};

###############################################################################
# POD example: spec test vector decryption
###############################################################################

subtest 'POD: spec decryption example' => sub {
    my $hex = decrypt_private_key(
        'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p',
        'nostr',
    );
    is($hex, '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683',
        'spec test vector decrypts correctly');
};

###############################################################################
# POD example: decrypt with explicit log_n
###############################################################################

subtest 'POD: decrypt with explicit log_n' => sub {
    my $hex = decrypt_private_key(
        'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p',
        'nostr',
        log_n => 16,
    );
    is($hex, '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683',
        'spec test vector with explicit log_n');
};

###############################################################################
# exports
###############################################################################

subtest 'exports: functions available' => sub {
    ok(defined &encrypt_private_key, 'encrypt_private_key exported');
    ok(defined &decrypt_private_key, 'decrypt_private_key exported');
};

###############################################################################
# return type
###############################################################################

subtest 'encrypt: returns string' => sub {
    my $result = encrypt_private_key(
        privkey_hex => 'cc' x 32,
        password    => 'test',
        log_n       => 16,
    );
    ok(!ref $result, 'encrypt returns a plain scalar');
    like($result, qr/\Ancryptsec1[a-z0-9]+\z/, 'valid bech32 format');
};

subtest 'decrypt: returns lowercase hex' => sub {
    my $encrypted = encrypt_private_key(
        privkey_hex => 'dd' x 32,
        password    => 'test',
        log_n       => 16,
    );
    my $result = decrypt_private_key($encrypted, 'test');
    like($result, qr/\A[0-9a-f]{64}\z/, 'decrypt returns 64-char lowercase hex');
    is($result, 'dd' x 32, 'correct key recovered');
};

done_testing;
