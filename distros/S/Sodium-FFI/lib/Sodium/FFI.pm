package Sodium::FFI;
use strict;
use warnings;

our $VERSION = '0.008';

use Carp qw(croak);
use Exporter qw(import);

use Alien::Sodium;
use FFI::Platypus;
use Path::Tiny qw(path);
use Sub::Util qw(set_subname);

# these are the methods we can easily attach
our @EXPORT_OK = qw(
    randombytes_random randombytes_uniform
    sodium_version_string sodium_library_version_minor sodium_base64_encoded_len
    crypto_aead_aes256gcm_keygen crypto_aead_chacha20poly1305_keygen
    crypto_aead_chacha20poly1305_ietf_keygen crypto_auth_keygen
);

# add the various C Constants
push @EXPORT_OK, qw(
    crypto_auth_BYTES crypto_auth_KEYBYTES
    SODIUM_VERSION_STRING SIZE_MAX randombytes_SEEDBYTES SODIUM_LIBRARY_MINIMAL
    SODIUM_LIBRARY_VERSION_MAJOR SODIUM_LIBRARY_VERSION_MINOR
    sodium_base64_VARIANT_ORIGINAL sodium_base64_VARIANT_ORIGINAL_NO_PADDING
    sodium_base64_VARIANT_URLSAFE sodium_base64_VARIANT_URLSAFE_NO_PADDING
    crypto_aead_aes256gcm_KEYBYTES crypto_aead_aes256gcm_NPUBBYTES crypto_aead_aes256gcm_ABYTES
    HAVE_AEAD_DETACHED HAVE_AESGCM
    crypto_aead_chacha20poly1305_KEYBYTES crypto_aead_chacha20poly1305_NPUBBYTES
    crypto_aead_chacha20poly1305_ABYTES
    crypto_aead_chacha20poly1305_IETF_KEYBYTES crypto_aead_chacha20poly1305_IETF_NPUBBYTES
    crypto_aead_chacha20poly1305_IETF_ABYTES
    crypto_sign_SEEDBYTES crypto_sign_BYTES crypto_sign_SECRETKEYBYTES crypto_sign_PUBLICKEYBYTES
    crypto_box_SEALBYTES crypto_box_PUBLICKEYBYTES crypto_box_SECRETKEYBYTES
    crypto_box_MACBYTES crypto_box_NONCEBYTES crypto_box_SEEDBYTES crypto_box_BEFORENMBYTES
);

our $ffi;
BEGIN {
    $ffi = FFI::Platypus->new(api => 1, lib => Alien::Sodium->dynamic_libs);
    $ffi->bundle();
}
# All of these functions don't need to be gated by version.
$ffi->attach('randombytes_random' => [] => 'uint32');
$ffi->attach('randombytes_uniform' => ['uint32'] => 'uint32');
$ffi->attach('sodium_version_string' => [] => 'string');
$ffi->attach('sodium_library_version_major' => [] => 'int');
$ffi->attach('sodium_library_version_minor' => [] => 'int');
$ffi->attach('sodium_base64_encoded_len' => ['size_t', 'int'] => 'size_t');

sub crypto_aead_aes256gcm_keygen {
    my $len = Sodium::FFI::crypto_aead_aes256gcm_KEYBYTES;
    return Sodium::FFI::randombytes_buf($len);
}

sub crypto_aead_chacha20poly1305_ietf_keygen {
    my $len = Sodium::FFI::crypto_aead_chacha20poly1305_IETF_KEYBYTES;
    return Sodium::FFI::randombytes_buf($len);
}

sub crypto_aead_chacha20poly1305_keygen {
    my $len = Sodium::FFI::crypto_aead_chacha20poly1305_KEYBYTES;
    return Sodium::FFI::randombytes_buf($len);
}

sub crypto_auth_keygen {
    my $len = Sodium::FFI::crypto_auth_KEYBYTES;
    return Sodium::FFI::randombytes_buf($len);
}

our %function = (
    # int
    # crypto_auth(unsigned char *out, const unsigned char *in,
    #     unsigned long long inlen, const unsigned char *k);
    'crypto_auth' => [
        ['string', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $key) = @_;
            my $msg_len = length($msg);
            my $key_len = length($key);

            unless($key_len == Sodium::FFI::crypto_auth_KEYBYTES) {
                croak("Secret key length should be crypto_auth_KEYBYTES bytes");
            }

            my $mac = "\0" x Sodium::FFI::crypto_auth_BYTES;
            my $real_len = 0;
            my $ret = $xsub->($mac, $msg, $msg_len, $key);
            croak("Internal error") unless $ret == 0;
            return $mac;
        }
    ],

    # int
    # crypto_auth_verify(const unsigned char *h, const unsigned char *in,
    #     unsigned long long inlen, const unsigned char *k);
    'crypto_auth_verify' => [
        ['string', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $mac, $msg, $key) = @_;
            my $mac_len = length($mac);
            my $msg_len = length($msg);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($key_len == Sodium::FFI::crypto_auth_KEYBYTES) {
                croak("Secret key length should be crypto_auth_KEYBYTES bytes");
            }
            unless ($mac_len == Sodium::FFI::crypto_auth_BYTES) {
                croak("authentication tag length should be crypto_auth_BYTES bytes");
            }

            my $ret = $xsub->($mac, $msg, $msg_len, $key);
            return 1 if $ret == 0;
            return 0;
        }
    ],

    # int
    # crypto_aead_chacha20poly1305_ietf_decrypt(unsigned char *m,
    #     unsigned long long *mlen_p,
    #     unsigned char *nsec,
    #     const unsigned char *c,
    #     unsigned long long clen,
    #     const unsigned char *ad,
    #     unsigned long long adlen,
    #     const unsigned char *npub,
    #     const unsigned char *k);
    'crypto_aead_chacha20poly1305_ietf_decrypt' => [
        ['string', 'size_t*', 'string', 'string', 'size_t', 'string', 'size_t', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $ciphertext, $ad, $nonce, $key) = @_;
            my $ciphertext_len = length($ciphertext);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_chacha20poly1305_IETF_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_chacha20poly1305_IETF_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_chacha20poly1305_IETF_KEYBYTES) {
                croak("Secret key length should be crypto_aead_chacha20poly1305_IETF_KEYBYTES bytes");
            }
            if ($ciphertext_len < Sodium::FFI::crypto_aead_chacha20poly1305_IETF_ABYTES) {
                croak("cipher text length not right");
            }
            my $msg_len = $ciphertext_len;
            if ($msg_len > $SIZE_MAX) {
                croak("Message length greater than max size");
            }
            my $msg = "\0" x $msg_len;
            my $real_len = 0;
            my $ret = $xsub->($msg, \$real_len, undef, $ciphertext, $ciphertext_len, $ad, $ad_len, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("Invalid resultant length");
            }
            if ($real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("arithmetic overflow");
            }
            return substr($msg, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_chacha20poly1305_ietf_encrypt(unsigned char *c,
    #     unsigned long long *clen_p,
    #     const unsigned char *m,
    #     unsigned long long mlen,
    #     const unsigned char *ad,
    #     unsigned long long adlen,
    #     const unsigned char *nsec,
    #     const unsigned char *npub,
    #     const unsigned char *k);
    'crypto_aead_chacha20poly1305_ietf_encrypt' => [
        ['string', 'size_t*', 'string', 'size_t', 'string', 'size_t', 'string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $ad, $nonce, $key) = @_;
            my $msg_len = length($msg);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_chacha20poly1305_IETF_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_chacha20poly1305_IETF_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_chacha20poly1305_IETF_KEYBYTES) {
                croak("Secret key length should be crypto_aead_chacha20poly1305_IETF_KEYBYTES bytes");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_aead_chacha20poly1305_IETF_ABYTES) {
                croak("arithmetic overflow");
            }

            my $ciphertext_len = $msg_len + Sodium::FFI::crypto_aead_chacha20poly1305_IETF_ABYTES;
            my $ciphertext = "\0" x $ciphertext_len;
            my $real_len = 0;
            my $ret = $xsub->($ciphertext, \$real_len, $msg, $msg_len, $ad, $ad_len, undef, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len > $SIZE_MAX || $real_len > $ciphertext_len) {
                croak("Invalid resultant length");
            }
            return substr($ciphertext, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_chacha20poly1305_decrypt(unsigned char *m,
        # unsigned long long *mlen_p,
        # unsigned char *nsec,
        # const unsigned char *c,
        # unsigned long long clen,
        # const unsigned char *ad,
        # unsigned long long adlen,
        # const unsigned char *npub,
        # const unsigned char *k);
    'crypto_aead_chacha20poly1305_decrypt' => [
        ['string', 'size_t*', 'string', 'string', 'size_t', 'string', 'size_t', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $ciphertext, $ad, $nonce, $key) = @_;
            my $ciphertext_len = length($ciphertext);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_chacha20poly1305_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_chacha20poly1305_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_chacha20poly1305_KEYBYTES) {
                croak("Secret key length should be crypto_aead_chacha20poly1305_KEYBYTES bytes");
            }
            if ($ciphertext_len < Sodium::FFI::crypto_aead_chacha20poly1305_ABYTES) {
                croak("cipher text length not right");
            }
            my $msg_len = $ciphertext_len;
            if ($msg_len > $SIZE_MAX) {
                croak("Message length greater than max size");
            }
            my $msg = "\0" x $msg_len;
            my $real_len = 0;
            my $ret = $xsub->($msg, \$real_len, undef, $ciphertext, $ciphertext_len, $ad, $ad_len, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("Invalid resultant length");
            }
            if ($real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("arithmetic overflow");
            }
            return substr($msg, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_chacha20poly1305_encrypt(unsigned char *c,
    #     unsigned long long *clen_p,
    #     const unsigned char *m,
    #     unsigned long long mlen,
    #     const unsigned char *ad,
    #     unsigned long long adlen,
    #     const unsigned char *nsec,
    #     const unsigned char *npub,
    #     const unsigned char *k)
    'crypto_aead_chacha20poly1305_encrypt' => [
        ['string', 'size_t*', 'string', 'size_t', 'string', 'size_t', 'string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $ad, $nonce, $key) = @_;
            my $msg_len = length($msg);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_chacha20poly1305_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_chacha20poly1305_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_chacha20poly1305_KEYBYTES) {
                croak("Secret key length should be crypto_aead_chacha20poly1305_KEYBYTES bytes");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_aead_chacha20poly1305_ABYTES) {
                croak("arithmetic overflow");
            }

            my $ciphertext_len = $msg_len + Sodium::FFI::crypto_aead_chacha20poly1305_ABYTES;
            my $ciphertext = "\0" x $ciphertext_len;
            my $real_len = 0;
            my $ret = $xsub->($ciphertext, \$real_len, $msg, $msg_len, $ad, $ad_len, undef, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len > $SIZE_MAX || $real_len > $ciphertext_len) {
                croak("Invalid resultant length");
            }
            return substr($ciphertext, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_aes256gcm_encrypt(unsigned char *c,
        # unsigned long long *clen_p,
        # const unsigned char *m,
        # unsigned long long mlen,
        # const unsigned char *ad,
        # unsigned long long adlen,
        # const unsigned char *nsec,
        # const unsigned char *npub,
        # const unsigned char *k);
    'crypto_aead_aes256gcm_encrypt' => [
        ['string', 'size_t*', 'string', 'size_t', 'string', 'size_t', 'string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $ad, $nonce, $key) = @_;
            croak("AESGCM not available.") unless Sodium::FFI::crypto_aead_aes256gcm_is_available();
            my $msg_len = length($msg);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_aes256gcm_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_aes256gcm_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_aes256gcm_KEYBYTES) {
                croak("Secret key length should be crypto_aead_aes256gcm_KEYBYTES bytes");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_aead_aes256gcm_ABYTES) {
                croak("arithmetic overflow");
            }
            if ($msg_len > (16 * ((1 << 32) - 2)) - Sodium::FFI::crypto_aead_aes256gcm_ABYTES) {
                croak("message too long for a single key");
            }
            my $ciphertext_len = $msg_len + Sodium::FFI::crypto_aead_aes256gcm_ABYTES;
            my $ciphertext = "\0" x $ciphertext_len;
            my $real_len = 0;
            my $ret = $xsub->($ciphertext, \$real_len, $msg, $msg_len, $ad, $ad_len, undef, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len > $SIZE_MAX || $real_len > $ciphertext_len) {
                croak("Invalid resultant length");
            }
            return substr($ciphertext, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_aes256gcm_decrypt(unsigned char *m,
        # unsigned long long *mlen_p,
        # unsigned char *nsec,
        # const unsigned char *c,
        # unsigned long long clen,
        # const unsigned char *ad,
        # unsigned long long adlen,
        # const unsigned char *npub,
        # const unsigned char *k);
    'crypto_aead_aes256gcm_decrypt' => [
        ['string', 'size_t*', 'string', 'string', 'size_t', 'string', 'size_t', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $ciphertext, $ad, $nonce, $key) = @_;
            croak("AESGCM not available.") unless Sodium::FFI::crypto_aead_aes256gcm_is_available();
            my $ciphertext_len = length($ciphertext);
            my $ad_len = length($ad);
            my $nonce_len = length($nonce);
            my $key_len = length($key);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;

            unless ($nonce_len == Sodium::FFI::crypto_aead_aes256gcm_NPUBBYTES) {
                croak("Nonce length should be crypto_aead_aes256gcm_NPUBBYTES bytes");
            }
            unless($key_len == Sodium::FFI::crypto_aead_aes256gcm_KEYBYTES) {
                croak("Secret key length should be crypto_aead_aes256gcm_KEYBYTES bytes");
            }
            if ($ciphertext_len < Sodium::FFI::crypto_aead_aes256gcm_ABYTES) {
                croak("cipher text length not right");
            }
            if ($ciphertext_len - Sodium::FFI::crypto_aead_aes256gcm_ABYTES > 16 * ((1 << 32) - 2)) {
                croak("cipher text too long for a single key");
            }
            my $msg_len = $ciphertext_len;
            if ($msg_len > $SIZE_MAX) {
                croak("Message length greater than max size");
            }
            my $msg = "\0" x $msg_len;
            my $real_len = 0;
            my $ret = $xsub->($msg, \$real_len, undef, $ciphertext, $ciphertext_len, $ad, $ad_len, $nonce, $key);
            croak("Internal error") unless $ret == 0;
            if ($real_len <= 0 || $real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("Invalid resultant length");
            }
            return substr($msg, 0, $real_len);
        }
    ],

    # int
    # crypto_aead_aes256gcm_is_available()
    'crypto_aead_aes256gcm_is_available' => [
        [] => 'int',
        sub {
            my ($xsub) = @_;
            if (Sodium::FFI::HAVE_AESGCM) {
                return $xsub->();
            }
            return 0;
        }
    ],

    # int
    # crypto_box_easy(unsigned char *c, const unsigned char *m,
    #   unsigned long long mlen, const unsigned char *n,
    #   const unsigned char *pk, const unsigned char *sk);
    'crypto_box_easy' => [
        ['string', 'string', 'size_t', 'string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $nonce, $pk, $sk) = @_;
            my $msg_len = length($msg);
            my $nonce_len = length($nonce);
            my $pk_len = length($pk);
            my $sk_len = length($sk);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            if ($nonce_len != Sodium::FFI::crypto_box_NONCEBYTES) {
                croak("The nonce must be crypto_box_NONCEBYTES in length");
            }
            if ($pk_len != Sodium::FFI::crypto_box_PUBLICKEYBYTES) {
                croak("The public key must be crypto_box_PUBLICKEYBYTES in length");
            }
            if ($sk_len != Sodium::FFI::crypto_box_SECRETKEYBYTES) {
                croak("The secret key must be crypto_box_SECRETKEYBYTES in length");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_box_MACBYTES) {
                croak("Arithmetic overflow");
            }
            my $cipher_len = Sodium::FFI::crypto_box_MACBYTES + $msg_len;
            my $cipher_text = "\0" x $cipher_len;
            my $ret = $xsub->($cipher_text, $msg, $msg_len, $nonce, $pk, $sk);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return $cipher_text;
        }
    ],

    # int
    # crypto_box_keypair(unsigned char *pk, unsigned char *sk);
    'crypto_box_keypair' => [
        ['string', 'string'] => 'int',
        sub {
            my ($xsub) = @_;
            my $pubkey = "\0" x Sodium::FFI::crypto_box_PUBLICKEYBYTES ;
            my $seckey = "\0" x Sodium::FFI::crypto_box_SECRETKEYBYTES;
            my $ret = $xsub->($pubkey, $seckey);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return ($pubkey, $seckey);
        }
    ],

    # int
    # crypto_box_open_easy(unsigned char *m, const unsigned char *c,
    #   unsigned long long clen, const unsigned char *n,
    #   const unsigned char *pk, const unsigned char *sk);
    'crypto_box_open_easy' => [
        ['string', 'string', 'size_t', 'string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $cipher_text, $nonce, $pk, $sk) = @_;
            my $cipher_len = length($cipher_text);
            my $nonce_len = length($nonce);
            my $pk_len = length($pk);
            my $sk_len = length($sk);
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            if ($nonce_len != Sodium::FFI::crypto_box_NONCEBYTES) {
                croak("The nonce must be crypto_box_NONCEBYTES in length");
            }
            if ($pk_len != Sodium::FFI::crypto_box_PUBLICKEYBYTES) {
                croak("The public key must be crypto_box_PUBLICKEYBYTES in length");
            }
            if ($sk_len != Sodium::FFI::crypto_box_SECRETKEYBYTES) {
                croak("The secret key must be crypto_box_SECRETKEYBYTES in length");
            }
            if ($cipher_len <= Sodium::FFI::crypto_box_MACBYTES) {
                croak("The cipher text should be larger than crypto_box_MACBYTES bytes");
            }

            my $msg_len = $cipher_len - Sodium::FFI::crypto_box_MACBYTES;
            my $msg = "\0" x $msg_len;
            my $ret = $xsub->($msg, $cipher_text, $cipher_len, $nonce, $pk, $sk);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return $msg;
        }
    ],

    # int
    # crypto_box_seed_keypair(unsigned char *pk, unsigned char *sk, const unsigned char *seed);
    'crypto_box_seed_keypair' => [
        ['string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $seed) = @_;
            my $seed_len = length($seed);
            unless ($seed_len == Sodium::FFI::crypto_box_SEEDBYTES) {
                croak("Seed length must be crypto_box_SEEDBYTES in length");
            }
            my $pubkey = "\0" x Sodium::FFI::crypto_box_PUBLICKEYBYTES;
            my $seckey = "\0" x Sodium::FFI::crypto_box_SECRETKEYBYTES;
            my $ret = $xsub->($pubkey, $seckey, $seed);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return ($pubkey, $seckey);
        }
    ],

    # int
    # crypto_scalarmult_base(unsigned char *q, const unsigned char *n);
    'crypto_scalarmult_base' => [
        ['string', 'string'] => 'int',
        sub {
            my ($xsub, $secret_key) = @_;
            my $sk_len = length($secret_key);
            unless ($sk_len == Sodium::FFI::crypto_box_SECRETKEYBYTES) {
                croak("Secret Key length must be crypto_box_SECRETKEYBYTES in length");
            }
            my $pubkey = "\0" x Sodium::FFI::crypto_box_PUBLICKEYBYTES;
            my $ret = $xsub->($pubkey, $secret_key);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return $pubkey;
        }
    ],

    # int
    # crypto_sign_keypair(unsigned char *pk, unsigned char *sk);
    'crypto_sign_keypair' => [
        ['string', 'string'] => 'int',
        sub {
            my ($xsub) = @_;
            my $pubkey = "\0" x Sodium::FFI::crypto_sign_PUBLICKEYBYTES;
            my $seckey = "\0" x Sodium::FFI::crypto_sign_SECRETKEYBYTES;
            my $ret = $xsub->($pubkey, $seckey);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return ($pubkey, $seckey);
        }
    ],

    # int
    # crypto_sign_seed_keypair(unsigned char *pk, unsigned char *sk, const unsigned char *seed);
    'crypto_sign_seed_keypair' => [
        ['string', 'string', 'string'] => 'int',
        sub {
            my ($xsub, $seed) = @_;
            my $seed_len = length($seed);
            unless ($seed_len == Sodium::FFI::crypto_sign_SEEDBYTES) {
                croak("Seed length must be crypto_sign_SEEDBYTES in length");
            }
            my $pubkey = "\0" x Sodium::FFI::crypto_sign_PUBLICKEYBYTES;
            my $seckey = "\0" x Sodium::FFI::crypto_sign_SECRETKEYBYTES;
            my $ret = $xsub->($pubkey, $seckey, $seed);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            return ($pubkey, $seckey);
        }
    ],

    # int
    # crypto_sign(unsigned char *sm, unsigned long long *smlen_p,
    #     const unsigned char *m, unsigned long long mlen,
    #     const unsigned char *sk);
    'crypto_sign' => [
        ['string', 'size_t*', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $key) = @_;
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            my $msg_len = length($msg);
            my $key_len = length($key);
            unless ($key_len == Sodium::FFI::crypto_sign_SECRETKEYBYTES) {
                croak("Secret Key length must be crypto_sign_SECRETKEYBYTES in length");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_sign_BYTES) {
                croak("Arithmetic overflow");
            }
            my $real_len = 0;
            my $signed_len = $msg_len + Sodium::FFI::crypto_sign_BYTES;
            my $signed = "\0" x $signed_len;
            my $ret = $xsub->($signed, \$real_len, $msg, $msg_len, $key);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            if ($real_len >= $SIZE_MAX || $real_len > $signed_len) {
                croak("Arithmetic overflow");
            }
            return substr($signed, 0, $real_len);
        }
    ],

    # int
    # crypto_sign_detached(unsigned char *sig, unsigned long long *siglen_p,
    #     const unsigned char *m, unsigned long long mlen,
    #     const unsigned char *sk);
    'crypto_sign_detached' => [
        ['string', 'size_t*', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $key) = @_;
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            my $msg_len = length($msg);
            my $key_len = length($key);
            unless ($key_len == Sodium::FFI::crypto_sign_SECRETKEYBYTES) {
                croak("Secret Key length must be crypto_sign_SECRETKEYBYTES in length");
            }
            my $signature = "\0" x Sodium::FFI::crypto_sign_BYTES;
            my $real_len = 0;
            my $ret = $xsub->($signature, \$real_len, $msg, $msg_len, $key);
            if ($ret != 0) {
                croak("Signature creation failed.");
            }
            if ($real_len <= 0 || $real_len > Sodium::FFI::crypto_sign_BYTES) {
                croak("Signature size isn't correct.");
            }
            return substr($signature, 0, $real_len);
        }
    ],

    # int
    # crypto_sign_open(unsigned char *m, unsigned long long *mlen_p,
    #     const unsigned char *sm, unsigned long long smlen,
    #     const unsigned char *pk);
    'crypto_sign_open' => [
        ['string', 'size_t*', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $msg, $key) = @_;
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            my $msg_len = length($msg);
            my $key_len = length($key);
            unless ($key_len == Sodium::FFI::crypto_sign_PUBLICKEYBYTES) {
                croak("Public Key length must be crypto_sign_PUBLICKEYBYTES in length");
            }
            if ($SIZE_MAX - $msg_len <= Sodium::FFI::crypto_sign_BYTES) {
                croak("Arithmetic overflow");
            }
            my $real_len = 0;
            my $open = "\0" x $msg_len;
            my $ret = $xsub->($open, \$real_len, $msg, $msg_len, $key);
            if ($ret != 0) {
                croak("Some internal error happened");
            }
            if ($real_len >= $SIZE_MAX || $real_len > $msg_len) {
                croak("Arithmetic overflow");
            }
            return substr($open, 0, $real_len);
        }
    ],

    # int
    # crypto_sign_verify_detached(const unsigned char *sig,
    #     const unsigned char *m,
    #     unsigned long long mlen,
    #     const unsigned char *pk);
    'crypto_sign_verify_detached' => [
        ['string', 'string', 'size_t', 'string'] => 'int',
        sub {
            my ($xsub, $sig, $msg, $key) = @_;
            my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
            my $sig_len = length($sig);
            my $msg_len = length($msg);
            my $key_len = length($key);
            unless ($sig_len == Sodium::FFI::crypto_sign_BYTES) {
                croak("Signature length must be crypto_sign_BYTES in length");
            }
            unless ($key_len == Sodium::FFI::crypto_sign_PUBLICKEYBYTES) {
                croak("Public Key length must be crypto_sign_PUBLICKEYBYTES in length");
            }
            my $ret = $xsub->($sig, $msg, $msg_len, $key);
            return 1 if ($ret == 0);
            return 0;
        }
    ],

    # void
    # randombytes_buf(void * const buf, const size_t size)
    'randombytes_buf' => [
        ['string', 'size_t'] => 'void',
        sub {
            my ($xsub, $len) = @_;
            $len //= 0;
            return '' unless $len > 0;
            my $buffer = "\0" x ($len + 1);
            $xsub->($buffer, $len);
            return substr($buffer, 0, $len);
        }
    ],

    # void
    # sodium_add(unsigned char *a, const unsigned char *b, const size_t len)
    'sodium_add' => [
        ['string', 'string', 'size_t'] => 'void',
        sub {
            my ($xsub, $bin_string1, $bin_string2, $len) = @_;
            return unless $bin_string1 && $bin_string2;
            $len //= length($bin_string1);
            my $copy = substr($bin_string1, 0);
            $xsub->($copy, $bin_string2, $len);
            return $copy;
        }
    ],

    # int
    # sodium_base642bin(
    #   unsigned char * const bin, const size_t bin_maxlen,
    #   const char * const b64, const size_t b64_len,
    #   const char * const ignore, size_t * const bin_len,
    #   const char ** const b64_end, const int variant);
    'sodium_base642bin' => [
        ['string', 'size_t', 'string', 'size_t', 'string', 'size_t*', 'string*', 'int'] => 'int',
        sub {
            my ($xsub, $b64, $variant) = @_;
            my $b64_len = length($b64);
            $variant //= Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;

            my $bin_max_len = $b64_len / 4 * 3 + 2;
            my $bin = "\0" x $bin_max_len;
            my $bin_real_len = 0;

            my $ignore = undef;
            my $end = undef;
            $xsub->($bin, $bin_max_len, $b64, $b64_len, $ignore, \$bin_real_len, \$end, $variant);
            # $bin =~ s/\0//g;
            return substr($bin, 0, $bin_real_len);
        }
    ],

    # char *
    # sodium_bin2base64(char * const b64, const size_t b64_maxlen,
    #   const unsigned char * const bin, const size_t bin_len,
    #   const int variant);
    'sodium_bin2base64' => [
        ['string', 'size_t', 'string', 'size_t', 'int'] => 'string',
        sub {
            my ($xsub, $bin, $variant) = @_;
            my $bin_len = length($bin);
            $variant //= Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;

            my $b64_len = Sodium::FFI::sodium_base64_encoded_len($bin_len, $variant);
            my $b64 = "\0" x $b64_len;

            $xsub->($b64, $b64_len, $bin, $bin_len, $variant);
            $b64 =~ s/\0//g;
            return $b64;
        }
    ],

    # char *
    # sodium_bin2hex(char *const hex, const size_t hex_maxlen,
    #   const unsigned char *const bin, const size_t bin_len)
    'sodium_bin2hex' => [
        ['string', 'size_t', 'string', 'size_t'] => 'string',
        sub {
            my ($xsub, $bin_string) = @_;
            return unless $bin_string;
            my $bin_len = length($bin_string);
            my $hex_max = $bin_len * 2;

            my $buffer = "\0" x ($hex_max + 1);
            $xsub->($buffer, $hex_max + 1, $bin_string, $bin_len);
            return substr($buffer, 0, $hex_max);
        }
    ],

    # int
    # sodium_hex2bin(
    #    unsigned char *const bin, const size_t bin_maxlen,
    #    const char *const hex, const size_t hex_len,
    #    const char *const ignore, size_t *const bin_len, const char **const hex_end)
    'sodium_hex2bin' => [
        ['string', 'size_t', 'string', 'size_t', 'string', 'size_t *', 'string *'] => 'int',
        sub {
            my ($xsub, $hex_string, %params) = @_;
            $hex_string //= '';
            my $hex_len = length($hex_string);

            # these two are mostly always void/undef
            my $ignore = $params{ignore};
            my $hex_end = $params{hex_end};

            my $bin_max_len = $params{max_len} // 0;
            if ($bin_max_len <= 0) {
                $bin_max_len = $hex_len;
                $bin_max_len = int($hex_len / 2) unless $ignore;
            }
            my $buffer = "\0" x ($hex_len + 1);
            my $bin_len = 0;

            my $ret = $xsub->($buffer, $hex_len, $hex_string, $hex_len, $ignore, \$bin_len, \$hex_end);
            unless ($ret == 0) {
                croak("sodium_hex2bin failed with: $ret");
            }

            return substr($buffer, 0, $bin_max_len) if $bin_max_len < $bin_len;
            return substr($buffer, 0, $bin_len);
        }
    ],

    # void
    # sodium_increment(unsigned char *n, const size_t nlen)
    'sodium_increment' => [
        ['string', 'size_t'] => 'void',
        sub {
            my ($xsub, $bin_string, $len) = @_;
            return unless $bin_string;
            $len //= length($bin_string);
            my $copy = substr($bin_string, 0);
            $xsub->($copy, $len);
            return $copy;
        }
    ],

    # int
    # sodium_is_zero(const unsigned char *n, const size_t nlen)
    'sodium_is_zero' => [
        ['string', 'size_t'] => 'int',
        sub {
            my ($xsub, $bin_string, $len) = @_;
            $len //= length($bin_string);
            return $xsub->($bin_string, $len);
        }
    ],

    # int
    # sodium_memcmp(const void * const b1_, const void * const b2_, size_t len);
    'sodium_memcmp' => [
        ['string', 'string', 'size_t'] => 'int',
        sub {
            my ($xsub, $string_x, $string_y, $len) = @_;
            return unless $string_x;
            $len //= length($string_x);
            return $xsub->($string_x, $string_y, $len);
        }
    ],

);

our %maybe_function = (
    # void
    # randombytes_buf_deterministic(void * const buf, const size_t size,
    #   const unsigned char seed[randombytes_SEEDBYTES]);
    'randombytes_buf_deterministic' => {
        added => [1,0,12],
        ffi => [
            ['string', 'size_t', 'string'] => 'void',
            sub {
                my ($xsub, $len, $seed) = @_;
                $len //= 0;
                return '' unless $len > 0;
                my $buffer = "\0" x ($len + 1);
                $xsub->($buffer, $len, $seed);
                return substr($buffer, 0, $len);
            }
        ],
        fallback => sub { croak("randombytes_buf_deterministic not implemented until libsodium v1.0.12"); },
    },


    # int
    # sodium_compare(const unsigned char *b1_,
    #   const unsigned char *b2_, size_t len)
    'sodium_compare' => {
        added => [1,0,4],
        ffi => [
            ['string', 'string', 'size_t'] => 'int',
            sub {
                my ($xsub, $bin_string1, $bin_string2, $len) = @_;
                return unless $bin_string1 && $bin_string2;
                $len //= length($bin_string1);
                my $int = $xsub->($bin_string1, $bin_string2, $len);
                return $int;
            }
        ],
        fallback => sub { croak("sodium_compare not implemented until libsodium v1.0.4"); },
    },

    # int
    # sodium_library_minimal(void)
    'sodium_library_minimal' => {
        added => [1,0,12],
        ffi => [[], 'int'],
        fallback => sub { croak("sodium_library_minimal not implemented until libsodium v1.0.12"); },
    },

    # int
    # sodium_pad(size_t *padded_buflen_p, unsigned char *buf,
    # size_t unpadded_buflen, size_t blocksize, size_t max_buflen)
    'sodium_pad' => {
        added => [1,0,14],
        ffi => [
            ['size_t', 'string', 'size_t', 'size_t', 'size_t'] => 'int',
            sub {
                my ($xsub, $unpadded, $block_size) = @_;
                my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
                my $unpadded_len = length($unpadded);
                $block_size //= 16;
                $block_size = 16 if $block_size < 0;

                my $xpadlen = $block_size - 1;
                if (($block_size & ($block_size - 1)) == 0) {
                    $xpadlen -= $unpadded_len & ($block_size - 1);
                } else {
                    $xpadlen -= $unpadded_len % $block_size;
                }
                if ($SIZE_MAX - $unpadded_len <= $xpadlen) {
                    croak("Input is too large.");
                }

                my $xpadded_len = $unpadded_len + $xpadlen;
                my $padded = "\0" x ($xpadded_len + 1);
                if ($unpadded_len > 0) {
                    my $st = 1;
                    my $i = 0;
                    my $k = $unpadded_len;
                    for my $j (0..$xpadded_len) {
                        substr($padded, $j, 1) = substr($unpadded, $i, 1);
                        $k -= $st;
                        $st = (~((((($k >> 48) | ($k >> 32) | ($k >> 16) | $k) & 0xffff) - 1) >> 16)) & 1;
                        $i += $st;
                    }
                }
                my $int = $xsub->(undef, $padded, $unpadded_len, $block_size, $xpadded_len + 1);
                return $padded;
            }
        ],
        fallback => sub { croak("sodium_pad not implemented until libsodium v1.0.14"); },
    },

    # void
    # sodium_sub(unsigned char *a, const unsigned char *b, const size_t len);
    'sodium_sub' => {
        added => [1,0,17],
        ffi => [
            ['string', 'string', 'size_t'] => 'void',
            sub {
                my ($xsub, $bin_string1, $bin_string2, $len) = @_;
                return unless $bin_string1 && $bin_string2;
                $len //= length($bin_string1);
                my $copy = substr($bin_string1, 0);
                $xsub->($copy, $bin_string2, $len);
                return $copy;
            }
        ],
        fallback => sub { croak("sodium_sub not implemented until libsodium v1.0.17"); },
    },

    # int
    # sodium_unpad(size_t *unpadded_buflen_p, const unsigned char *buf,
    # size_t padded_buflen, size_t blocksize)
    'sodium_unpad' => {
        added => [1,0,14],
        ffi => [
            ['size_t*', 'string', 'size_t', 'size_t'] => 'int',
            sub {
                my ($xsub, $padded, $block_size) = @_;
                $block_size //= 16;
                $block_size = 16 if $block_size < 0;

                my $SIZE_MAX = Sodium::FFI::SIZE_MAX;
                my $padded_len = length($padded);
                if ($padded_len < $block_size) {
                    croak("Invalid padding.");
                }
                my $unpadded_len = 0;
                my $int = $xsub->(\$unpadded_len, $padded, $padded_len, $block_size);
                return substr($padded, 0, $unpadded_len);
            }
        ],
        fallback => sub { croak("sodium_unpad not implemented until libsodium v1.0.14"); },
    },
);

foreach my $func (keys %function) {
    $ffi->attach($func, @{$function{$func}});
    push(@EXPORT_OK, $func) unless ref($func);
}

foreach my $func (keys %maybe_function) {
    my $href = $maybe_function{$func};
    if (_version_or_better(@{$href->{added}})) {
        $ffi->attach($func, @{$href->{ffi}});
    }
    else {
        # monkey patch in the subref
        no strict 'refs';
        no warnings 'redefine';
        my $pkg = __PACKAGE__;
        *{"${pkg}::$func"} = set_subname("${pkg}::$func", $href->{fallback});
    }
    push @EXPORT_OK, $func;
}

sub _version_or_better {
    my ($maj, $min, $pat) = @_;
    $maj //= 0;
    $min //= 0;
    $pat //= 0;
    foreach my $partial ($maj, $min, $pat) {
        if ($partial =~ /[^0-9]/) {
            croak("_version_or_better requires 1 - 3 integers representing major, minor and patch numbers");
        }
    }
    # if no number was passed in, then the current version is higher
    return 1 unless ($maj || $min || $pat);

    my $version_string = Sodium::FFI::sodium_version_string();
    croak("No version string") unless $version_string;
    my ($smaj, $smin, $spatch) = split(/\./, $version_string);
    return 0 if $smaj < $maj; # full version behind of requested
    return 1 if $smaj > $maj; # full version ahead of requested
    # now we should be matching major versions
    return 1 unless $min; # if we were only given major, move on
    return 0 if $smin < $min; # same major, lower minor
    return 1 if $smaj > $min; # same major, higher minor
    # now we should be matching major and minor, check patch
    return 1 unless $pat; # move on if we were given maj, min only
    return 0 if $spatch < $pat;
    return 1;
}

1;

__END__


=head1 NAME

Sodium::FFI - Sodium is a modern, easy-to-use software library for encryption, decryption, signatures, password hashing, and more.

=head1 SYNOPSIS

  use strict;
  use warnings;
  use v5.34;

  use Sodium::FFI ();

  my $text = "1234";
  my $padded = Sodium::FFI::pad($text, 16);
  say Sodium::FFI::unpad($padded);

=head1 DESCRIPTION

L<Sodium::FFI> is a set of Perl bindings for the L<LibSodium|https://doc.libsodium.org/>
C library. Sodium is a modern, easy-to-use software library for encryption, decryption,
signatures, password hashing, and more. These bindings have been created using FFI
via L<FFI::Platypus>.

While we also intend to eventually fix L<Crypt::NaCl::Sodium> so that it can use newer versions
of LibSodium.

=head1 Crypto Auth Functions

LibSodium provides a few
L<Crypto Auth Functions|https://doc.libsodium.org/secret-key_cryptography/secret-key_authentication>
to encrypt and verify messages with a key.

=head2 crypto_auth

    use Sodium::FFI qw(randombytes_buf crypto_auth crypto_auth_keygen);
    # First, let's create a key
    my $key = crypto_auth_keygen();
    # let's encrypt 12 bytes of random data... for fun
    my $message = randombytes_buf(12);
    my $encrypted_bytes = crypto_auth($message, $key);
    say $encrypted_bytes;

The L<crypto_auth|https://doc.libsodium.org/secret-key_cryptography/secret-key_authentication#usage>
function encrypts a message using a secret key and returns that message as a string of bytes.

=head2 crypto_auth_verify

    use Sodium::FFI qw(randombytes_buf crypto_auth_verify crypto_auth_keygen);

    my $message = randombytes_buf(12);
    # you'd really need to already have the key, but here
    my $key = crypto_auth_keygen();
    # your encrypted data would come from a call to crypto_auth
    my $encrypted; # assume this is full of bytes
    # let's verify
    my $boolean = crypto_auth_verify($encrypted, $message, $key);
    say $boolean;

The L<crypto_auth_verify|https://doc.libsodium.org/secret-key_cryptography/secret-key_authentication#usage>
function returns a boolean letting us know if the encrypted message and the original message are verified with the
secret key.

=head2 crypto_auth_keygen

    use Sodium::FFI qw(crypto_auth_keygen);
    my $key = crypto_auth_keygen();
    # this could also be written:
    use Sodium::FFI qw(randombytes_buf crypto_auth_KEYBYTES);
    my $key = randombytes_buf(crypto_auth_KEYBYTES);

The L<crypto_auth_keygen|https://doc.libsodium.org/secret-key_cryptography/secret-key_authentication#usage>
function returns a byte string of C<crypto_auth_KEYBYTES> bytes.

=head1 AES256-GCM Crypto Functions

LibSodium provides a few
L<AES256-GCM functions|https://doc.libsodium.org/secret-key_cryptography/aead/aes-256-gcm>
to encrypt or decrypt a message with a nonce and key. Note that these functions may not be
available on your hardware and will C<croak> in such a case.

=head2 crypto_aead_aes256gcm_decrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_aes256gcm_decrypt
        crypto_aead_aes256gcm_is_available
        crypto_aead_aes256gcm_keygen crypto_aead_aes256gcm_NPUBBYTES
    );

    if (crypto_aead_aes256gcm_is_available()) {
        # you'd really need to already have the nonce and key, but here
        my $key = crypto_aead_aes256gcm_keygen();
        my $nonce = randombytes_buf(crypto_aead_aes256gcm_NPUBBYTES);
        # your encrypted data would come from a call to crypto_aead_aes256gcm_encrypt
        my $encrypted; # assume this is full of bytes
        # any additional data bytes that were encrypted should also be included
        # they can be undef
        my $additional_data = undef; # we don't care to add anything extra
        # let's decrypt!
        my $decrypted_bytes = crypto_aead_aes256gcm_decrypt(
            $encrypted, $additional_data, $nonce, $key
        );
        say $decrypted_bytes;
    }

The L<crypto_aead_aes256gcm_decrypt|https://doc.libsodium.org/secret-key_cryptography/aead/aes-256-gcm#combined-mode>
function returns a string of bytes after verifying that the ciphertext
includes a valid tag using a secret key, a public nonce, and additional data.

=head2 crypto_aead_aes256gcm_encrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_aes256gcm_encrypt
        crypto_aead_aes256gcm_is_available
        crypto_aead_aes256gcm_keygen crypto_aead_aes256gcm_NPUBBYTES
    );
    if (crypto_aead_aes256gcm_is_available()) {
        # First, let's create a key and nonce
        my $key = crypto_aead_aes256gcm_keygen();
        my $nonce = randombytes_buf(crypto_aead_aes256gcm_NPUBBYTES);
        # let's encrypt 12 bytes of random data... for fun
        my $message = randombytes_buf(12);
        # any additional data bytes that were encrypted should also be included
        # they can be undef
        my $additional_data = undef; # we don't care to add anything extra
        $additional_data = randombytes_buf(12); # or some random byte string
        my $encrypted_bytes = crypto_aead_aes256gcm_encrypt(
            $message, $additional_data, $nonce, $key
        );
        say $encrypted_bytes;
    }

The L<crypto_aead_aes256gcm_encrypt|https://doc.libsodium.org/secret-key_cryptography/aead/aes-256-gcm#combined-mode>
function encrypts a message using a secret key and a public nonce and returns that message
as a string of bytes.

=head2 crypto_aead_aes256gcm_is_available

    use Sodium::FFI qw(crypto_aead_aes256gcm_is_available);
    if (crypto_aead_aes256gcm_is_available()) {
        # ... encrypt and decrypt some data here
    }

The L<crypto_aead_aes256gcm_is_available|https://doc.libsodium.org/secret-key_cryptography/aead/aes-256-gcm#limitations>
function returns C<1> if the current CPU supports the AES256-GCM implementation, C<0> otherwise.

=head2 crypto_aead_aes256gcm_keygen

    use Sodium::FFI qw(
        crypto_aead_aes256gcm_keygen crypto_aead_aes256gcm_is_available
    );
    if (crypto_aead_aes256gcm_is_available()) {
        my $key = crypto_aead_aes256gcm_keygen();
        # this could also be written:
        use Sodium::FFI qw(randombytes_buf crypto_aead_aes256gcm_KEYBYTES);
        my $key = randombytes_buf(crypto_aead_aes256gcm_KEYBYTES);
    }

The L<crypto_aead_aes256gcm_keygen|https://doc.libsodium.org/secret-key_cryptography/aead/aes-256-gcm#detached-mode>
function returns a byte string of C<crypto_aead_aes256gcm_KEYBYTES> bytes.

=head1 chacha20poly1305 Crypto Functions

LibSodium provides a few
L<chacha20poly1305 functions|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/original_chacha20-poly1305_construction>
to encrypt or decrypt a message with a nonce and key.

=head2 crypto_aead_chacha20poly1305_decrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_chacha20poly1305_decrypt
        crypto_aead_chacha20poly1305_keygen crypto_aead_chacha20poly1305_NPUBBYTES
    );

    # you'd really need to already have the nonce and key, but here
    my $key = crypto_aead_chacha20poly1305_keygen();
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_NPUBBYTES);
    # your encrypted data would come from a call to crypto_aead_chacha20poly1305_encrypt
    my $encrypted; # assume this is full of bytes
    # any additional data bytes that were encrypted should also be included
    # they can be undef
    my $additional_data = undef; # we don't care to add anything extra
    # let's decrypt!
    my $decrypted_bytes = crypto_aead_chacha20poly1305_decrypt(
        $encrypted, $additional_data, $nonce, $key
    );
    say $decrypted_bytes;

The L<crypto_aead_chacha20poly1305_decrypt|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/original_chacha20-poly1305_construction#combined-mode>
function returns a string of bytes after verifying that the ciphertext
includes a valid tag using a secret key, a public nonce, and additional data.

=head2 crypto_aead_chacha20poly1305_encrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_chacha20poly1305_encrypt
        crypto_aead_chacha20poly1305_keygen crypto_aead_chacha20poly1305_NPUBBYTES
    );
    # First, let's create a key and nonce
    my $key = crypto_aead_chacha20poly1305_keygen();
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_NPUBBYTES);
    # let's encrypt 12 bytes of random data... for fun
    my $message = randombytes_buf(12);
    # any additional data bytes that were encrypted should also be included
    # they can be undef
    my $additional_data = undef; # we don't care to add anything extra
    $additional_data = randombytes_buf(12); # or some random byte string
    my $encrypted_bytes = crypto_aead_chacha20poly1305_encrypt(
        $message, $additional_data, $nonce, $key
    );
    say $encrypted_bytes;

The L<crypto_aead_chacha20poly1305_encrypt|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/original_chacha20-poly1305_construction#combined-mode>
function encrypts a message using a secret key and a public nonce and returns that message
as a string of bytes.

=head2 crypto_aead_chacha20poly1305_keygen

    use Sodium::FFI qw(
        crypto_aead_chacha20poly1305_keygen
    );
    my $key = crypto_aead_chacha20poly1305_keygen();
    # this could also be written:
    use Sodium::FFI qw(randombytes_buf crypto_aead_chacha20poly1305_KEYBYTES);
    my $key = randombytes_buf(crypto_aead_chacha20poly1305_KEYBYTES);

The L<crypto_aead_chacha20poly1305_keygen|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/original_chacha20-poly1305_construction#detached-mode>
function returns a byte string of C<crypto_aead_chacha20poly1305_KEYBYTES> bytes.

=head1 chacha20poly1305_ietf Crypto Functions

LibSodium provides a few
L<chacha20poly1305 IETF functions|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction>
to encrypt or decrypt a message with a nonce and key.

The C<IETF> variant of the C<ChaCha20-Poly1305> construction can safely encrypt a practically unlimited number of messages,
but individual messages cannot exceed approximately C<256 GiB>.

=head2 crypto_aead_chacha20poly1305_ietf_decrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_chacha20poly1305_ietf_decrypt
        crypto_aead_chacha20poly1305_ietf_keygen crypto_aead_chacha20poly1305_IETF_NPUBBYTES
    );

    # you'd really need to already have the nonce and key, but here
    my $key = crypto_aead_chacha20poly1305_ietf_keygen();
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_IETF_NPUBBYTES);
    # your encrypted data would come from a call to crypto_aead_chacha20poly1305_ietf_encrypt
    my $encrypted; # assume this is full of bytes
    # any additional data bytes that were encrypted should also be included
    # they can be undef
    my $additional_data = undef; # we don't care to add anything extra
    # let's decrypt!
    my $decrypted_bytes = crypto_aead_chacha20poly1305_ietf_decrypt(
        $encrypted, $additional_data, $nonce, $key
    );
    say $decrypted_bytes;

The L<crypto_aead_chacha20poly1305_ietf_decrypt|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction#combined-mode>
function returns a string of bytes after verifying that the ciphertext
includes a valid tag using a secret key, a public nonce, and additional data.

=head2 crypto_aead_chacha20poly1305_ietf_encrypt

    use Sodium::FFI qw(
        randombytes_buf crypto_aead_chacha20poly1305_ietf_encrypt
        crypto_aead_chacha20poly1305_ietf_keygen crypto_aead_chacha20poly1305_IETF_NPUBBYTES
    );
    # First, let's create a key and nonce
    my $key = crypto_aead_chacha20poly1305_ietf_keygen();
    my $nonce = randombytes_buf(crypto_aead_chacha20poly1305_IETF_NPUBBYTES);
    # let's encrypt 12 bytes of random data... for fun
    my $message = randombytes_buf(12);
    # any additional data bytes that were encrypted should also be included
    # they can be undef
    my $additional_data = undef; # we don't care to add anything extra
    $additional_data = randombytes_buf(12); # or some random byte string
    my $encrypted_bytes = crypto_aead_chacha20poly1305_ietf_encrypt(
        $message, $additional_data, $nonce, $key
    );
    say $encrypted_bytes;

The L<crypto_aead_chacha20poly1305_ietf_encrypt|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction#combined-mode>
function encrypts a message using a secret key and a public nonce and returns that message
as a string of bytes.

=head2 crypto_aead_chacha20poly1305_ietf_keygen

    use Sodium::FFI qw(
        crypto_aead_chacha20poly1305_ietf_keygen
    );
    my $key = crypto_aead_chacha20poly1305_ietf_keygen();
    # this could also be written:
    use Sodium::FFI qw(randombytes_buf crypto_aead_chacha20poly1305_IETF_KEYBYTES);
    my $key = randombytes_buf(crypto_aead_chacha20poly1305_IETF_KEYBYTES);

The L<crypto_aead_chacha20poly1305_ietf_keygen|https://doc.libsodium.org/secret-key_cryptography/aead/chacha20-poly1305/ietf_chacha20-poly1305_construction#detached-mode>
function returns a byte string of C<crypto_aead_chacha20poly1305_IETF_KEYBYTES> bytes.

=head1 Public Key Cryptography - Crypto Boxes

LibSodium provides a few
L<Public Key Authenticated Encryption|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption>
and
L<Sealed Box Encryption|https://doc.libsodium.org/public-key_cryptography/sealed_boxes>
functions to allow sending messages using authenticated encryption.

=head2 crypto_box_easy

    use Sodium::FFI qw(crypto_box_keypair crypto_box_easy randombytes_buf crypto_box_NONCEBYTES);
    my $nonce = randombytes_buf(crypto_box_NONCEBYTES);
    my ($public_key, $secret_key) = crypto_box_keypair();
    my $msg = "test";
    my $cipher_text = crypto_box_easy($msg, $nonce, $public_key, $secret_key);

The L<crypto_box_easy|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#combined-mode>
function encrypts a message using the recipient's public key, the sender's secret key, and a nonce.

=head2 crypto_box_keypair

    use Sodium::FFI qw(crypto_box_keypair);
    my ($public_key, $secret_key) = crypto_box_keypair();

The L<crypto_box_keypair|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#key-pair-generation>
function randomly generates a secret key and a corresponding public key.

=head2 crypto_box_open_easy

    use Sodium::FFI qw(crypto_box_keypair crypto_box_easy crypto_box_open_easy randombytes_buf crypto_box_NONCEBYTES);
    my $nonce = randombytes_buf(crypto_box_NONCEBYTES);
    my ($public_key, $secret_key) = crypto_box_keypair();
    my $msg = "test";
    my $cipher_text = crypto_box_easy($msg, $nonce, $public_key, $secret_key);
    my $decrypted = crypto_box_open_easy($cipher_text, $nonce, $public_key, $secret_key);
    if ($decrypted eq $msg) {
        say "Yay!";
    }

The L<crypto_box_open_easy|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#combined-mode>
function decrypts a cipher text produced by L<crypto_box_easy>.

=head2 crypto_box_seed_keypair

    use Sodium::FFI qw(crypto_box_seed_keypair crypto_sign_SEEDBYTES randombytes_buf);
    my $seed = randombytes_buf(crypto_sign_SEEDBYTES);
    my ($public_key, $secret_key) = crypto_box_seed_keypair($seed);

The L<crypto_box_seed_keypair|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#key-pair-generation>
function randomly generates a secret key deterministically derived from a single key seed.

=head2 crypto_scalarmult_base

    use Sodium::FFI qw(crypto_box_keypair crypto_scalarmult_base);
    my ($public_key, $secret_key) = crypto_box_keypair();
    my $computed_public = crypto_scalarmult_base($secret_key);
    if ($public_key eq $computed_public) {
        say "Yay!";
    }

The L<crypto_scalarmult_base|https://doc.libsodium.org/public-key_cryptography/authenticated_encryption#key-pair-generation>
function can be used to compute the public key given a secret key previously generated with L<crypto_box_keypair>.

=head1 Public Key Cryptography - Public Key Signatures

LibSodium provides a few
L<Public Key Signature Functions|https://doc.libsodium.org/public-key_cryptography/public-key_signatures>
where a signer generates a key pair (public key and secret key) and appends the secret
key to any number of messages. The one doing the verification will need to know and trust the public key
before messages signed using it can be verified. This is not authenticated encryption.

=head2 crypto_sign

    use Sodium::FFI qw(crypto_sign_keypair crypto_sign);
    my $msg = "Let's sign this and stuff!";
    my ($public_key, $secret_key) = crypto_sign_keypair();
    my $signed_msg = crypto_sign($msg, $secret_key);

The L<crypto_sign|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#combined-mode>
function prepends a signature to an unaltered message.

=head2 crypto_sign_detached

    use Sodium::FFI qw(crypto_sign_keypair crypto_sign_detached);
    my $msg = "Let's sign this and stuff!";
    my ($public_key, $secret_key) = crypto_sign_keypair();
    my $signature = crypto_sign_detached($msg, $secret_key);

The L<crypto_sign_detached|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#detached-mode>
function signs the message with the secret key and returns the signature.

=head2 crypto_sign_keypair

    use Sodium::FFI qw(crypto_sign_keypair);
    my ($public_key, $secret_key) = crypto_sign_keypair();

The L<crypto_sign_keypair|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#key-pair-generation>
function randomly generates a secret key and a corresponding public key.

=head2 crypto_sign_open

    use Sodium::FFI qw(crypto_sign_open);
    # we should have the public key and signed message to open
    my $signed_msg = ...;
    my $public_key = ...;
    my $msg = crypto_sign_open($signed_msg, $public_key);

The L<crypto_sign_open|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#combined-mode>
function checks that a signed message has a valid signature for the public key. If so, it returns that message
and if not, it will throw.

=head2 crypto_sign_seed_keypair

    use Sodium::FFI qw(crypto_sign_seed_keypair crypto_sign_SEEDBYTES randombytes_buf);
    my $seed = randombytes_buf(crypto_sign_SEEDBYTES);
    my ($public_key, $secret_key) = crypto_sign_seed_keypair($seed);

The L<crypto_sign_seed_keypair|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#key-pair-generation>
function randomly generates a secret key deterministically derived from a single key seed and a corresponding public key.

=head2 crypto_sign_verify_detached

    use Sodium::FFI qw(crypto_sign_verify_detached);
    my $signature = ...;
    my $message = ...;
    my $public_key = ...;
    my $boolean = crypto_sign_verify_detached($signature, $message, $public_key);

The L<crypto_sign_verify_detached|https://doc.libsodium.org/public-key_cryptography/public-key_signatures#detached-mode>
function verifies that a signature is valid for the supplied message with public key. It returns
a boolean value, C<1> for true, C<0> for false.

=head1 Random Number Functions

LibSodium provides a few
L<Random Number Generator Functions|https://doc.libsodium.org/generating_random_data>
to assist you in getting your data ready for encryption, decryption, or hashing.

=head2 randombytes_buf

    use Sodium::FFI qw(randombytes_buf);
    my $bytes = randombytes_buf(2);
    say $bytes; # contains two bytes of random data

The L<randombytes_buf|https://doc.libsodium.org/generating_random_data#usage>
function returns string of random bytes limited by a provided length.

=head2 randombytes_buf_deterministic

    use Sodium::FFI qw(randombytes_buf_deterministic);
    # create some seed string of length Sodium::FFI::randombytes_SEEDBYTES
    my $seed = 'x' x Sodium::FFI::randombytes_SEEDBYTES;
    # use that seed to create a random string
    my $length = 2;
    my $bytes = randombytes_buf_deterministic($length, $seed);
    say $bytes; # contains two bytes of random data

The L<randombytes_buf_deterministic|https://doc.libsodium.org/generating_random_data#usage>
function returns string of random bytes limited by a provided length.

It returns a byte string indistinguishable from random bytes without knowing the C<$seed>.
For a given seed, this function will always output the same sequence.
The seed string you create should be C<randombytes_SEEDBYTES> bytes long.
Up to 256 GB can be produced with a single seed.

=head2 randombytes_random

    use Sodium::FFI qw(randombytes_random);
    my $random = randombytes_random();
    say $random;

The L<randombytes_random|https://doc.libsodium.org/generating_random_data#usage>
function returns an unpredictable value between C<0> and C<0xffffffff> (included).

=head2 randombytes_uniform

    use Sodium::FFI qw(randombytes_uniform);
    my $upper_limit = 0xffffffff;
    my $random = randombytes_uniform($upper_limit);
    say $random;

The L<randombytes_uniform|https://doc.libsodium.org/generating_random_data#usage>
function returns an unpredictable value between C<0> and C<$upper_bound> (excluded).
Unlike C<< randombytes_random() % $upper_bound >>, it guarantees a uniform
distribution of the possible output values even when C<$upper_bound> is not a
power of C<2>. Note that an C<$upper_bound> less than C<2> leaves only a single element
to be chosen, namely C<0>.

=head1 Utility/Helper Functions

LibSodium provides a few L<Utility/Helper Functions|https://doc.libsodium.org/helpers>
to assist you in getting your data ready for encryption, decryption, or hashing.

=head2 sodium_add

    use Sodium::FFI qw(sodium_add);
    my $left = "111";
    $left = sodium_add($left, 111);
    say $left; # bbb

The L<sodium_add|https://doc.libsodium.org/helpers#adding-large-numbers>
function adds 2 large numbers.

=head2 sodium_base642bin

    use Sodium::FFI qw(sodium_base642bin);
    say sodium_base642bin('/wA='); # \377\000
    my $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;
    say sodium_base642bin('/wA=', $variant); # \377\000
    $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL_NO_PADDING;
    say sodium_base642bin('/wA', $variant); # \377\000
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE;
    say sodium_base642bin('_wA=', $variant); # \377\000
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE_NO_PADDING;
    say sodium_base642bin('_wA', $variant); # \377\000

The L<sodium_base642bin|https://doc.libsodium.org/helpers#base64-encoding-decoding>
function takes a base64 encoded string and turns it back into a binary string.

=head2 sodium_bin2base64

    use Sodium::FFI qw(sodium_bin2base64);
    say sodium_bin2base64("\377\000"); # /wA=
    my $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL;
    say sodium_bin2base64("\377\000", $variant); # /wA=
    $variant = Sodium::FFI::sodium_base64_VARIANT_ORIGINAL_NO_PADDING;
    say sodium_bin2base64("\377\000", $variant); # /wA
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE;
    say sodium_bin2base64("\377\000", $variant); # _wA=
    $variant = Sodium::FFI::sodium_base64_VARIANT_URLSAFE_NO_PADDING;
    say sodium_bin2base64("\377\000", $variant); # _wA

The L<sodium_bin2base64|https://doc.libsodium.org/helpers#base64-encoding-decoding>
function takes a binary string and turns it into a base64 encoded string.

=head2 sodium_bin2hex

    use Sodium::FFI qw(sodium_bin2hex);
    my $binary = "ABC";
    my $hex = sodium_bin2hex($binary);
    say $hex; # 414243

The L<sodium_bin2hex|https://doc.libsodium.org/helpers#hexadecimal-encoding-decoding>
function takes a binary string and turns it into a hex string.

=head2 sodium_compare

    use Sodium::FFI qw(sodium_compare);
    say sodium_compare("\x01", "\x02"); # -1
    say sodium_compare("\x02", "\x01"); # 1
    say sodium_compare("\x01", "\x01"); # 0

The L<sodium_compare|https://doc.libsodium.org/helpers#comparing-large-numbers>
function compares two large numbers encoded in little endian format.
Results in C<-1> when C<< $left < $right >>
Results in C<0> when C<$left eq $right>
Results in C<1> when C<< $left > $right >>

=head2 sodium_hex2bin

    use Sodium::FFI qw(sodium_hex2bin);
    my $hex = "414243";
    my $bin = sodium_hex2bin($hex);
    say $bin; # ABC

The L<sodium_hex2bin|https://doc.libsodium.org/helpers#hexadecimal-encoding-decoding>
function takes a hex string and turns it into a binary string.

=head2 sodium_increment

    use Sodium::FFI qw(sodium_increment);
    my $x = "\x01";
    $x = sodium_increment($x); # "\x02";

The L<sodium_increment|https://doc.libsodium.org/helpers#incrementing-large-numbers>
function takes an arbitrarily long unsigned number and increments it.

=head2 sodium_is_zero

    use Sodium::FFI qw(sodium_is_zero);
    my $string = "\x00\x00\x01"; # zero zero 1
    # entire string not zeros
    say sodium_is_zero($string); # 0
    # first byte of string is zero
    say sodium_is_zero($string, 1); # 1
    # first two bytes of string is zero
    say sodium_is_zero($string, 2); # 1

The L<sodium_is_zero|https://doc.libsodium.org/helpers#testing-for-all-zeros>
function tests a string for all zeros.

=head2 sodium_library_minimal

    use Sodium::FFI qw(sodium_library_minimal);
    say sodium_library_minimal; # 0 or 1

The C<sodium_library_minimal> function lets you know if this is a minimal version.

=head2 sodium_library_version_major

    use Sodium::FFI qw(sodium_library_version_major);
    say sodium_library_version_major; # 10

The C<sodium_library_version_major> function returns the major version of the library.

=head2 sodium_library_version_minor

    use Sodium::FFI qw(sodium_library_version_minor);
    say sodium_library_version_minor; # 3

The C<sodium_library_version_minor> function returns the minor version of the library.

=head2 sodium_memcmp

    use Sodium::FFI qw(sodium_memcmp);
    my $string1 = "abcdef";
    my $string2 = "abc";
    my $match_length = 3;
    # string 1 and 2 are equal for the first 3
    say sodium_memcmp($string1, $string2, $match_length); # 0
    # they are not equal for 4 slots
    say sodium_memcmp("abcdef", "abc", 4); # -1

The L<sodium_memcmp|https://doc.libsodium.org/helpers#constant-time-test-for-equality>
function compares two strings in constant time.
Results in C<-1> when strings 1 and 2 aren't equal.
Results in C<0> when strings 1 and 2 are equal.

=head2 sodium_pad

    use Sodium::FFI qw(sodium_pad);
    my $bin_string = "\x01";
    my $block_size = 4;
    say sodium_pad($bin_string, $block_size); # 01800000

The L<sodium_pad|https://doc.libsodium.org/padding> function adds
padding data to a buffer in order to extend its total length to a
multiple of the block size.

=head2 sodium_sub

    use Sodium::FFI qw(sodium_sub);
    my $x = "\x02";
    my $y = "\x01";
    my $z = sodium_sub($x, $y);
    say $x; # \x01

The L<sodium_sub|https://doc.libsodium.org/helpers#subtracting-large-numbers>
function subtracts 2 large, unsigned numbers encoded in little-endian format.

=head2 sodium_unpad

    use Sodium::FFI qw(sodium_unpad);
    my $bin_string = "\x01\x80\x00\x00\x0";
    my $block_size = 4;
    say sodium_unpad($bin_string, $block_size); # 01

The L<sodium_unpad|https://doc.libsodium.org/padding> function
computes the original, unpadded length of a message previously
padded using C<sodium_pad>.

=head2 sodium_version_string

    use Sodium::FFI qw(sodium_version_string);
    say sodium_version_string; # 1.0.18

The C<sodium_version_string> function returns the stringified version information
for the version of LibSodium that you have installed.

=head1 COPYRIGHT

 Copyright 2020 Chase Whitener. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
