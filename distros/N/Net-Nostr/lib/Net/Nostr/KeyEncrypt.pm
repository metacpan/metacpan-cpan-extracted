package Net::Nostr::KeyEncrypt;

use strictures 2;

use Carp qw(croak);
use Crypt::AuthEnc::ChaCha20Poly1305;
use Crypt::PRNG qw(random_bytes);
use Crypt::ScryptKDF qw(scrypt_raw);
use Encode qw(encode);
use Unicode::Normalize qw(NFKC);
use Bitcoin::Crypto::Bech32 qw(encode_bech32 translate_5to8 translate_8to5);
use Exporter 'import';

our @EXPORT_OK = qw(
    encrypt_private_key
    decrypt_private_key
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $VERSION_BYTE = 0x02;
my $MAX_BECH32_LENGTH = 5000;

# Bech32 decode without BIP-173's 90-char limit, same as in Bech32.pm
{
    my @ALPHABET = qw(
        q p z r y 9 x 8  g f 2 t v d w 0
        s 3 j n 5 4 k h  c e 6 m u a 7 l
    );
    my %ALPHABET_MAP = map { $ALPHABET[$_] => $_ } 0 .. $#ALPHABET;
    my $CHARS = join '', @ALPHABET;

    sub _polymod {
        my ($values) = @_;
        my @C = (0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3);
        my $chk = 1;
        for my $val (@$values) {
            my $b = ($chk >> 25);
            $chk = ($chk & 0x1ffffff) << 5 ^ $val;
            for (0 .. 4) { $chk ^= (($b >> $_) & 1) ? $C[$_] : 0 }
        }
        return $chk;
    }

    sub _hrp_expand {
        my @hrp = split //, shift;
        return [map({ ord($_) >> 5 } @hrp), 0, map({ ord($_) & 31 } @hrp)];
    }

    sub _nostr_decode_bech32 {
        my ($str) = @_;
        $str = lc $str if uc $str eq $str;
        croak "bech32 string exceeds 5000 character limit" if length($str) > $MAX_BECH32_LENGTH;
        croak "bech32 string contains mixed case" if lc($str) ne $str;

        my @parts = split /1/, $str;
        croak "bech32 separator missing" if @parts < 2;
        my $data_part = pop @parts;
        my $hrp = join '1', @parts;

        croak "invalid bech32 data characters" if $data_part !~ /\A[$CHARS]+\z/;
        croak "bech32 data part too short" if length($data_part) < 6;

        my @data_values = map { $ALPHABET_MAP{$_} } split //, $data_part;
        my $check_values = [@{_hrp_expand($hrp)}, @data_values];
        croak "invalid bech32 checksum" unless _polymod($check_values) == 1;

        my @payload = @data_values[0 .. $#data_values - 6];
        return ($hrp, \@payload);
    }
}

sub encrypt_private_key {
    my (%args) = @_;
    my $privkey_hex  = $args{privkey_hex}  // croak "privkey_hex is required";
    my $password     = $args{password}     // croak "password is required";
    my $log_n        = $args{log_n}        // croak "log_n is required";
    my $key_security = $args{key_security} // 0x02;

    croak "privkey_hex must be 64-char lowercase hex" unless $privkey_hex =~ $HEX64;
    croak "password is required" unless length $password;
    croak "log_n must be between 1 and 22" unless $log_n >= 1 && $log_n <= 22;
    croak "key_security must be 0x00, 0x01, or 0x02"
        unless $key_security == 0x00 || $key_security == 0x01 || $key_security == 0x02;

    my $privkey_raw = pack('H*', $privkey_hex);
    $password = encode('UTF-8', NFKC($password));

    my $salt  = random_bytes(16);
    my $nonce = random_bytes(24);

    my $sym_key = scrypt_raw($password, $salt, 2**$log_n, 8, 1, 32);

    my $aad = chr($key_security);
    my $ciphertext_and_tag = _xchacha20poly1305_encrypt($sym_key, $nonce, $aad, $privkey_raw);

    my $raw = chr($VERSION_BYTE) . chr($log_n) . $salt . $nonce . $aad . $ciphertext_and_tag;

    my $data5 = translate_8to5($raw);
    return encode_bech32('ncryptsec', $data5, 'bech32');
}

sub decrypt_private_key {
    my ($ncryptsec, $password, %opts) = @_;

    croak "ncryptsec string is required" unless defined $ncryptsec && length $ncryptsec;
    croak "password is required" unless defined $password && length $password;

    my ($hrp, $data5) = _nostr_decode_bech32($ncryptsec);
    croak "expected ncryptsec prefix, got $hrp" unless $hrp eq 'ncryptsec';

    my $raw = translate_5to8($data5);
    croak "invalid payload size" unless length($raw) == 91;

    my $version = ord(substr($raw, 0, 1));
    croak "unknown version $version (expected $VERSION_BYTE)" unless $version == $VERSION_BYTE;

    my $log_n        = ord(substr($raw, 1, 1));
    my $salt         = substr($raw, 2, 16);
    my $nonce        = substr($raw, 18, 24);
    my $aad          = substr($raw, 42, 1);
    my $ct_and_tag   = substr($raw, 43);

    $password = encode('UTF-8', NFKC($password));

    # Use log_n from opts if provided, otherwise use embedded value
    my $effective_log_n = $opts{log_n} // $log_n;
    my $sym_key = scrypt_raw($password, $salt, 2**$effective_log_n, 8, 1, 32);

    my $privkey_raw = eval { _xchacha20poly1305_decrypt($sym_key, $nonce, $aad, $ct_and_tag) };
    croak "decryption failed: wrong password or corrupted data" unless defined $privkey_raw;

    return unpack('H*', $privkey_raw);
}

# XChaCha20-Poly1305 built from HChaCha20 + IETF ChaCha20-Poly1305.
# HChaCha20 derives a 32-byte subkey from the first 16 bytes of the 24-byte
# nonce. The remaining 8 bytes (prepended with 4 zero bytes) become the
# 12-byte IETF nonce.

sub _xchacha20poly1305_encrypt {
    my ($key, $nonce, $aad, $plaintext) = @_;
    my ($subkey, $ietf_nonce) = _xchacha_derive($key, $nonce);

    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($subkey, $ietf_nonce);
    $ae->adata_add($aad);
    my $ct = $ae->encrypt_add($plaintext);
    my $tag = $ae->encrypt_done();
    return $ct . $tag;
}

sub _xchacha20poly1305_decrypt {
    my ($key, $nonce, $aad, $ct_and_tag) = @_;
    my ($subkey, $ietf_nonce) = _xchacha_derive($key, $nonce);

    my $ct  = substr($ct_and_tag, 0, length($ct_and_tag) - 16);
    my $tag = substr($ct_and_tag, -16);

    my $ae = Crypt::AuthEnc::ChaCha20Poly1305->new($subkey, $ietf_nonce);
    $ae->adata_add($aad);
    my $pt = $ae->decrypt_add($ct);
    my $result_tag = $ae->decrypt_done();
    croak "MAC mismatch" unless $result_tag eq $tag;
    return $pt;
}

sub _xchacha_derive {
    my ($key, $nonce) = @_;
    my $subkey = _hchacha20($key, substr($nonce, 0, 16));
    my $ietf_nonce = "\x00\x00\x00\x00" . substr($nonce, 16, 8);
    return ($subkey, $ietf_nonce);
}

# HChaCha20: 20-round ChaCha core producing a 32-byte subkey from a
# 32-byte key and 16-byte nonce.
sub _hchacha20 {
    my ($key, $nonce) = @_;
    my @s = unpack('V*', "expand 32-byte k" . $key . $nonce);

    for (1 .. 10) {
        @s[0,4,8,12]  = _quarter_round(@s[0,4,8,12]);
        @s[1,5,9,13]  = _quarter_round(@s[1,5,9,13]);
        @s[2,6,10,14] = _quarter_round(@s[2,6,10,14]);
        @s[3,7,11,15] = _quarter_round(@s[3,7,11,15]);
        @s[0,5,10,15] = _quarter_round(@s[0,5,10,15]);
        @s[1,6,11,12] = _quarter_round(@s[1,6,11,12]);
        @s[2,7,8,13]  = _quarter_round(@s[2,7,8,13]);
        @s[3,4,9,14]  = _quarter_round(@s[3,4,9,14]);
    }

    return pack('V4V4', @s[0..3], @s[12..15]);
}

sub _quarter_round {
    my ($a, $b, $c, $d) = @_;
    $a = ($a + $b) & 0xffffffff; $d = _rotl32($d ^ $a, 16);
    $c = ($c + $d) & 0xffffffff; $b = _rotl32($b ^ $c, 12);
    $a = ($a + $b) & 0xffffffff; $d = _rotl32($d ^ $a, 8);
    $c = ($c + $d) & 0xffffffff; $b = _rotl32($b ^ $c, 7);
    return ($a, $b, $c, $d);
}

sub _rotl32 {
    my ($v, $n) = @_;
    return (($v << $n) | (($v >> (32 - $n)) & ((1 << $n) - 1))) & 0xffffffff;
}

1;

__END__

=head1 NAME

Net::Nostr::KeyEncrypt - NIP-49 private key encryption

=head1 SYNOPSIS

    use Net::Nostr::KeyEncrypt qw(encrypt_private_key decrypt_private_key);

    # Encrypt a private key with a password
    my $ncryptsec = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'my-strong-password',
        log_n       => 16,
    );
    # ncryptsec1...

    # Decrypt an encrypted private key
    my $privkey_hex = decrypt_private_key($ncryptsec, 'my-strong-password');
    # 'aa' x 32

    # Specify key security level
    my $ncryptsec = encrypt_private_key(
        privkey_hex  => $privkey_hex,
        password     => $password,
        log_n        => 20,
        key_security => 0x01,  # not known to have been handled insecurely
    );

=head1 DESCRIPTION

Implements NIP-49 private key encryption. Encrypts a user's private key
with a password using scrypt key derivation and XChaCha20-Poly1305 AEAD
encryption. The output is a bech32-encoded C<ncryptsec> string that can
be stored or transferred safely.

The password is Unicode-normalized to NFKC form before use, ensuring
that the same password entered on different systems produces the same
encryption key.

=head1 FUNCTIONS

All functions are exportable. None are exported by default.

=head2 encrypt_private_key

    my $ncryptsec = encrypt_private_key(
        privkey_hex  => $hex_privkey,
        password     => $password,
        log_n        => $log_n,
        key_security => $byte,   # optional, defaults to 0x02
    );

Encrypts a private key with a password. Returns a bech32-encoded
C<ncryptsec> string. Croaks if any argument is missing, out of range,
or malformed.

Arguments:

=over 4

=item C<privkey_hex> - 64-char lowercase hex private key (required)

=item C<password> - encryption password (required, non-empty)

=item C<log_n> - scrypt cost parameter as a power of 2 (required, 1-22).
Higher values use more memory and time but are more resistant to brute
force. Recommended: 16 (64 MiB, ~100ms) for interactive use, 20+ for
long-term storage.

=item C<key_security> - one of C<0x00> (key known to have been handled
insecurely), C<0x01> (key not known insecure), or C<0x02> (unknown).
Defaults to C<0x02>. This byte is included as associated data in the
AEAD encryption and stored in the payload.

=back

    my $ncryptsec = encrypt_private_key(
        privkey_hex => 'aa' x 32,
        password    => 'my-strong-password',
        log_n       => 16,
    );

=head2 decrypt_private_key

    my $hex = decrypt_private_key($ncryptsec, $password);
    my $hex = decrypt_private_key($ncryptsec, $password, log_n => $n);

Decrypts an C<ncryptsec> string with a password. Returns the private key
as a 64-char lowercase hex string. Validates the bech32 encoding,
C<ncryptsec> prefix, version byte (must be C<0x02>), and payload size
(must be 91 bytes). Croaks on wrong password, corrupted data, or
invalid format.

The C<log_n> parameter is optional. If omitted, the value embedded in
the C<ncryptsec> payload is used. Providing C<log_n> explicitly overrides
the embedded value, which is useful when you know the cost parameter
in advance.

    my $hex = decrypt_private_key(
        'ncryptsec1qgg9947rlpvqu76pj5ecreduf9jxhselq2nae2kghhvd5g7dgjtcxfqtd67p9m0w57lspw8gsq6yphnm8623nsl8xn9j4jdzz84zm3frztj3z7s35vpzmqf6ksu8r89qk5z2zxfmu5gv8th8wclt0h4p',
        'nostr',
    );
    # '3501454135014541350145413501453fefb02227e449e57cf4d3a3ce05378683'

=head1 SEE ALSO

L<NIP-49|https://github.com/nostr-protocol/nips/blob/master/49.md>,
L<Net::Nostr>, L<Net::Nostr::Key>

=cut
