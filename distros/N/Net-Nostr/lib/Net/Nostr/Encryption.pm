package Net::Nostr::Encryption;

use strictures 2;

use Carp qw(croak);
use Crypt::PK::ECC;
use Crypt::KeyDerivation qw(hkdf_extract);
use Crypt::Stream::ChaCha;
use Crypt::Mac::HMAC qw(hmac);
use Crypt::PRNG qw(random_bytes);
use Encode qw(encode decode);
use MIME::Base64 ();
use POSIX qw(floor);

use constant {
    VERSION_2         => 2,
    MIN_PLAINTEXT_LEN => 1,
    MAX_PLAINTEXT_LEN => 65535,
    MIN_PAYLOAD_LEN   => 132,
    MAX_PAYLOAD_LEN   => 87472,
    MIN_RAW_LEN       => 99,
    MAX_RAW_LEN       => 65603,
};

sub get_conversation_key {
    my ($class, $privkey_hex, $pubkey_hex) = @_;

    croak "privkey_hex must be 64-char lowercase hex"
        unless defined $privkey_hex && $privkey_hex =~ /\A[0-9a-f]{64}\z/;
    croak "pubkey_hex must be 64-char lowercase hex"
        unless defined $pubkey_hex && $pubkey_hex =~ /\A[0-9a-f]{64}\z/;

    my $priv_raw = pack('H*', $privkey_hex);
    my $pub_raw  = pack('H*', $pubkey_hex);

    # Import private key
    my $priv = Crypt::PK::ECC->new;
    eval { $priv->import_key_raw($priv_raw, 'secp256k1') };
    croak "invalid private key" if $@;
    croak "invalid private key" unless $priv->is_private;

    # Import public key as compressed (02 prefix + x coordinate)
    my $pub = Crypt::PK::ECC->new;
    eval { $pub->import_key_raw("\x02" . $pub_raw, 'secp256k1') };
    croak "invalid public key" if $@;

    # ECDH - produces raw x coordinate of shared point
    my $shared_x = $priv->shared_secret($pub);

    # HKDF-extract with salt='nip44-v2'
    return hkdf_extract($shared_x, 'nip44-v2', 'SHA256');
}

sub get_message_keys {
    my ($class, $conversation_key, $nonce) = @_;
    croak "invalid conversation_key length" unless length($conversation_key) == 32;
    croak "invalid nonce length" unless length($nonce) == 32;

    my $keys = _hkdf_expand($conversation_key, $nonce, 76);
    return (
        substr($keys, 0, 32),   # chacha_key
        substr($keys, 32, 12),  # chacha_nonce
        substr($keys, 44, 32),  # hmac_key
    );
}

sub calc_padded_len {
    my ($class, $unpadded_len) = @_;
    return 32 if $unpadded_len <= 32;

    my $next_power = 1 << (floor(_log2($unpadded_len - 1)) + 1);
    my $chunk = $next_power <= 256 ? 32 : $next_power / 8;
    return $chunk * (floor(($unpadded_len - 1) / $chunk) + 1);
}

sub encrypt {
    my ($class, $plaintext, $conversation_key, $nonce) = @_;

    my $unpadded = encode('UTF-8', $plaintext);
    my $unpadded_len = length($unpadded);
    croak "invalid plaintext length" if $unpadded_len < MIN_PLAINTEXT_LEN;
    croak "invalid plaintext length" if $unpadded_len > MAX_PLAINTEXT_LEN;

    $nonce //= random_bytes(32);

    my ($chacha_key, $chacha_nonce, $hmac_key) =
        $class->get_message_keys($conversation_key, $nonce);

    # Pad
    my $padded_len = $class->calc_padded_len($unpadded_len);
    my $padded = pack('n', $unpadded_len) . $unpadded . ("\x00" x ($padded_len - $unpadded_len));

    # Encrypt with ChaCha20
    my $chacha = Crypt::Stream::ChaCha->new($chacha_key, $chacha_nonce);
    my $ciphertext = $chacha->crypt($padded);

    # HMAC-SHA256 with AAD (nonce)
    my $mac = hmac('SHA256', $hmac_key, $nonce . $ciphertext);

    # Base64 encode: version(1) + nonce(32) + ciphertext + mac(32)
    return MIME::Base64::encode_base64(chr(VERSION_2) . $nonce . $ciphertext . $mac, '');
}

sub decrypt {
    my ($class, $payload, $conversation_key) = @_;

    my ($nonce, $ciphertext, $mac) = $class->_decode_payload($payload);

    my ($chacha_key, $chacha_nonce, $hmac_key) =
        $class->get_message_keys($conversation_key, $nonce);

    # Verify MAC
    my $calculated_mac = hmac('SHA256', $hmac_key, $nonce . $ciphertext);
    croak "invalid MAC" unless _ct_eq($calculated_mac, $mac);

    # Decrypt
    my $chacha = Crypt::Stream::ChaCha->new($chacha_key, $chacha_nonce);
    my $padded = $chacha->crypt($ciphertext);

    # Unpad
    return $class->_unpad($padded);
}

sub _decode_payload {
    my ($class, $payload) = @_;
    my $plen = length($payload);

    croak "unknown version" if $plen == 0 || substr($payload, 0, 1) eq '#';
    croak "invalid payload size" if $plen < MIN_PAYLOAD_LEN || $plen > MAX_PAYLOAD_LEN;

    my $data = MIME::Base64::decode_base64($payload);
    my $dlen = length($data);
    croak "invalid data size" if $dlen < MIN_RAW_LEN || $dlen > MAX_RAW_LEN;

    my $version = ord(substr($data, 0, 1));
    croak "unknown version $version" unless $version == VERSION_2;

    my $nonce      = substr($data, 1, 32);
    my $ciphertext = substr($data, 33, $dlen - 65);
    my $mac        = substr($data, $dlen - 32);

    return ($nonce, $ciphertext, $mac);
}

sub _unpad {
    my ($class, $padded) = @_;
    my $unpadded_len = unpack('n', substr($padded, 0, 2));
    croak "invalid padding" if $unpadded_len == 0;

    my $unpadded = substr($padded, 2, $unpadded_len);
    croak "invalid padding" unless length($unpadded) == $unpadded_len;

    my $expected_padded_len = 2 + $class->calc_padded_len($unpadded_len);
    croak "invalid padding" unless length($padded) == $expected_padded_len;

    return decode('UTF-8', $unpadded);
}

# Constant-time equality comparison
sub _ct_eq {
    my ($a, $b) = @_;
    return 0 unless length($a) == length($b);
    my $result = 0;
    for my $i (0 .. length($a) - 1) {
        $result |= ord(substr($a, $i, 1)) ^ ord(substr($b, $i, 1));
    }
    return $result == 0;
}

# HKDF-Expand with SHA256 (manual implementation since CryptX's hkdf_expand
# returns empty for our inputs)
sub _hkdf_expand {
    my ($prk, $info, $len) = @_;
    my $hash_len = 32;
    my $n = int(($len + $hash_len - 1) / $hash_len);
    my $okm = '';
    my $t = '';
    for my $i (1 .. $n) {
        $t = hmac('SHA256', $prk, $t . $info . chr($i));
        $okm .= $t;
    }
    return substr($okm, 0, $len);
}

sub _log2 {
    my ($n) = @_;
    return log($n) / log(2);
}

1;

__END__

=head1 NAME

Net::Nostr::Encryption - NIP-44 versioned encrypted payloads

=head1 SYNOPSIS

    use Net::Nostr::Encryption;
    use Net::Nostr::Key;

    my $alice = Net::Nostr::Key->new;
    my $bob   = Net::Nostr::Key->new;

    # Calculate shared conversation key
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $alice->privkey_hex, $bob->pubkey_hex,
    );

    # Encrypt a message
    my $payload = Net::Nostr::Encryption->encrypt('Hello, Bob!', $conv_key);

    # Bob decrypts using the same conversation key
    my $conv_key2 = Net::Nostr::Encryption->get_conversation_key(
        $bob->privkey_hex, $alice->pubkey_hex,
    );
    my $plaintext = Net::Nostr::Encryption->decrypt($payload, $conv_key2);
    # $plaintext is 'Hello, Bob!'

=head1 DESCRIPTION

Implements NIP-44 version 2 encrypted payloads using secp256k1 ECDH,
HKDF-SHA256, ChaCha20, and HMAC-SHA256. This module provides the
encryption primitives - it does not define any event kinds.

The encryption is symmetric: C<get_conversation_key(a_priv, B_pub)>
produces the same key as C<get_conversation_key(b_priv, A_pub)>.

=head1 METHODS

=head2 get_conversation_key

    my $key = Net::Nostr::Encryption->get_conversation_key($privkey_hex, $pubkey_hex);

Computes the shared conversation key between two users via ECDH and
HKDF-extract. Both keys must be 64-character lowercase hex strings;
croaks if either is missing or malformed. The private key is a
secp256k1 scalar, the public key is a 32-byte x-only coordinate.
Returns 32 raw bytes.

    my $conv = Net::Nostr::Encryption->get_conversation_key(
        $my_key->privkey_hex, $their_pubkey_hex,
    );

=head2 get_message_keys

    my ($chacha_key, $chacha_nonce, $hmac_key) =
        Net::Nostr::Encryption->get_message_keys($conversation_key, $nonce);

Derives per-message keys from a conversation key and nonce using
HKDF-expand. Both arguments are 32 raw bytes. Returns three raw byte
strings: ChaCha20 key (32 bytes), ChaCha20 nonce (12 bytes), and
HMAC key (32 bytes).

=head2 calc_padded_len

    my $padded = Net::Nostr::Encryption->calc_padded_len($unpadded_len);

Calculates the padded length for a given plaintext length. The padding
scheme uses power-of-two-based chunking with a minimum padded size of 32.

    Net::Nostr::Encryption->calc_padded_len(1);    # 32
    Net::Nostr::Encryption->calc_padded_len(32);   # 32
    Net::Nostr::Encryption->calc_padded_len(33);   # 64
    Net::Nostr::Encryption->calc_padded_len(257);  # 320

=head2 encrypt

    my $payload = Net::Nostr::Encryption->encrypt($plaintext, $conversation_key);
    my $payload = Net::Nostr::Encryption->encrypt($plaintext, $conversation_key, $nonce);

Encrypts a plaintext string using the NIP-44 v2 scheme. The conversation
key is 32 raw bytes (from C<get_conversation_key>). An optional 32-byte
nonce can be provided for deterministic encryption (useful for testing);
otherwise a cryptographically random nonce is generated.

Returns a base64-encoded payload string. The plaintext is UTF-8 encoded
before encryption and UTF-8 decoded after decryption. Croaks if the
plaintext is empty or exceeds 65535 bytes (after UTF-8 encoding).

    my $payload = Net::Nostr::Encryption->encrypt('secret message', $conv_key);

=head2 decrypt

    my $plaintext = Net::Nostr::Encryption->decrypt($payload, $conversation_key);

Decrypts a NIP-44 payload. The payload is the base64 string from C<encrypt>.
Croaks on invalid version, bad MAC, invalid padding, or malformed payload.

    my $msg = Net::Nostr::Encryption->decrypt($payload, $conv_key);

=head1 SEE ALSO

L<NIP-44|https://github.com/nostr-protocol/nips/blob/master/44.md>,
L<Net::Nostr>, L<Net::Nostr::Key>

=cut
