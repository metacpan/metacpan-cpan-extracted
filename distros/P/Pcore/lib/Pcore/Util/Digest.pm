package Pcore::Util::Digest;

use Pcore -export;
use Digest::MD5 qw[md5 md5_hex];
use Digest::SHA1 qw[sha1 sha1_hex];
use Digest::SHA qw[
  sha224 sha224_hex
  sha256 sha256_hex
  sha384 sha384_hex
  sha512 sha512_hex
  sha512224 sha512224_hex
  sha512256 sha512256_hex

  hmac_sha1 hmac_sha1_hex
  hmac_sha224 hmac_sha224_hex
  hmac_sha256 hmac_sha256_hex
  hmac_sha384 hmac_sha384_hex
  hmac_sha512 hmac_sha512_hex
  hmac_sha512224 hmac_sha512224_hex
  hmac_sha512256 hmac_sha512256_hex
];
use Digest::SHA3 qw[sha3_224 sha3_224_hex sha3_256 sha3_256_hex sha3_384 sha3_384_hex sha3_512 sha3_512_hex];

our $EXPORT = {
    CRC  => [qw[crc32]],
    MD5  => [qw[md5 md5_hex]],
    SHA1 => [
        qw[
          sha1 sha1_hex sha1_b64
          sha224 sha224_hex sha224_b64
          sha256 sha256_hex sha256_b64
          sha384 sha384_hex sha384_b64
          sha512 sha512_hex sha512_b64
          sha512224 sha512224_hex sha512224_b64
          sha512256 sha512256_hex sha512256_b64
          ]
    ],
    HMAC_SHA1 => [
        qw[
          hmac_sha1 hmac_sha1_hex hmac_sha1_b64
          hmac_sha224 hmac_sha224_hex hmac_sha224_b64
          hmac_sha256 hmac_sha256_hex hmac_sha256_b64
          hmac_sha384 hmac_sha384_hex hmac_sha384_b64
          hmac_sha512 hmac_sha512_hex hmac_sha512_b64
          hmac_sha512224 hmac_sha512224_hex hmac_sha512224_b64
          hmac_sha512256 hmac_sha512256_hex hmac_sha512256_b64
          ]
    ],
    SHA3 => [
        qw[
          sha3_224 sha3_224_hex sha3_224_b64
          sha3_256 sha3_256_hex sha3_256_b64
          sha3_384 sha3_384_hex sha3_384_b64
          sha3_512 sha3_512_hex sha3_512_b64
          ]
    ],
};

*sha1_b64 = \&Digest::SHA1::sha1_base64;

*sha224_b64    = \&Digest::SHA::sha224_base64;
*sha256_b64    = \&Digest::SHA::sha256_base64;
*sha384_b64    = \&Digest::SHA::sha384_base64;
*sha512_b64    = \&Digest::SHA::sha512_base64;
*sha512224_b64 = \&Digest::SHA::sha512224_base64;
*sha512256_b64 = \&Digest::SHA::sha512256_base64;

*hmac_sha1_b64      = \&Digest::SHA::hmac_sha1_base64;
*hmac_sha224_b64    = \&Digest::SHA::hmac_sha224_base64;
*hmac_sha256_b64    = \&Digest::SHA::hmac_sha256_base64;
*hmac_sha384_b64    = \&Digest::SHA::hmac_sha384_base64;
*hmac_sha512_b64    = \&Digest::SHA::hmac_sha512_base64;
*hmac_sha512224_b64 = \&Digest::SHA::hmac_sha512224_base64;
*hmac_sha512256_b64 = \&Digest::SHA::hmac_sha512256_base64;

*sha3_224_b64 = \&Digest::SHA3::sha3_224_base64;
*sha3_256_b64 = \&Digest::SHA3::sha3_256_base64;
*sha3_384_b64 = \&Digest::SHA3::sha3_384_base64;
*sha3_512_b64 = \&Digest::SHA3::sha3_512_base64;

sub crc32 {
    require String::CRC32;

    return &String::CRC32::crc32;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

1;
__END__
=pod

=encoding utf8

=cut
