package Sodium::FFI;
use strict;
use warnings;

our $VERSION = '0.003';

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
);

# add the various C Constants
push @EXPORT_OK, qw(
    SODIUM_VERSION_STRING SIZE_MAX randombytes_SEEDBYTES SODIUM_LIBRARY_MINIMAL
    SODIUM_LIBRARY_VERSION_MAJOR SODIUM_LIBRARY_VERSION_MINOR
    sodium_base64_VARIANT_ORIGINAL sodium_base64_VARIANT_ORIGINAL_NO_PADDING
    sodium_base64_VARIANT_URLSAFE sodium_base64_VARIANT_URLSAFE_NO_PADDING
    crypto_aead_aes256gcm_KEYBYTES crypto_aead_aes256gcm_NPUBBYTES crypto_aead_aes256gcm_ABYTES
    HAVE_AEAD_DETACHED HAVE_AESGCM
    crypto_aead_chacha20poly1305_KEYBYTES crypto_aead_chacha20poly1305_NPUBBYTES
    crypto_aead_chacha20poly1305_ABYTES
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

sub crypto_aead_chacha20poly1305_keygen {
    my $len = Sodium::FFI::crypto_aead_chacha20poly1305_KEYBYTES;
    return Sodium::FFI::randombytes_buf($len);
}

our %function = (
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

Sodium::FFI - FFI implementation of libsodium

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
C library. These bindings have been created using FFI via L<FFI::Platypus> to make
building and maintaining the bindings easier than was done via L<Crypt::NaCl::Sodium>.
While we also intend to fix up L<Crypt::NaCl::Sodium> so that it can use newer versions
of LibSodium, the FFI method is faster to build and release.

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
        crypto_aead_aes256gcm_keygen
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
