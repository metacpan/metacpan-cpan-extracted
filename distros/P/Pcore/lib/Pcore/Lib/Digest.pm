package Pcore::Lib::Digest;

use Pcore -export;

our $EXPORT = {
    CRC  => [qw[crc32_int]],
    MD5  => [qw[md5_bin md5_hex md5_b64 md5_stream]],
    SHA1 => [qw[sha1_bin sha1_hex sha1_b64 sha1_stream]],
    SHA2 => [ qw[
        sha224_bin sha224_hex sha224_b64
        sha256_bin sha256_hex sha256_b64
        sha384_bin sha384_hex sha384_b64
        sha512_bin sha512_hex sha512_b64
        sha512224_bin sha512224_hex sha512224_b64
        sha512256_bin sha512256_hex sha512256_b64
    ] ],
    HMAC_SHA1 => [qw[hmac_sha1_bin hmac_sha1_hex hmac_sha1_b64]],
    HMAC_SHA2 => [ qw[
        hmac_sha224_bin hmac_sha224_hex hmac_sha224_b64
        hmac_sha256_bin hmac_sha256_hex hmac_sha256_b64
        hmac_sha384_bin hmac_sha384_hex hmac_sha384_b64
        hmac_sha512_bin hmac_sha512_hex hmac_sha512_b64
        hmac_sha512224_bin hmac_sha512224_hex hmac_sha512224_b64
        hmac_sha512256_bin hmac_sha512256_hex hmac_sha512256_b64
    ] ],
    SHA3 => [ qw[
        sha3_224_bin sha3_224_hex sha3_224_b64
        sha3_256_bin sha3_256_hex sha3_256_b64
        sha3_384_bin sha3_384_hex sha3_384_b64
        sha3_512_bin sha3_512_hex sha3_512_b64
    ] ],
};

my $IMPORT = {
    crc32_int => [ 'String::CRC32', 'crc32' ],

    md5_bin => [ 'Digest::MD5', 'md5' ],
    md5_hex => ['Digest::MD5'],
    md5_b64 => [ 'Digest::MD5', 'md5_base64' ],

    sha1_bin => [ 'Digest::SHA1', 'sha1' ],
    sha1_hex => ['Digest::SHA1'],
    sha1_b64 => [ 'Digest::SHA1', 'sha1_base64' ],

    sha224_bin => [ 'Digest::SHA', 'sha224' ],
    sha224_hex => ['Digest::SHA'],
    sha224_b64 => [ 'Digest::SHA', 'sha224_base64' ],

    sha256_bin => [ 'Digest::SHA', 'sha256' ],
    sha256_hex => ['Digest::SHA'],
    sha256_b64 => [ 'Digest::SHA', 'sha256_base64' ],

    sha384_bin => [ 'Digest::SHA', 'sha384' ],
    sha384_hex => ['Digest::SHA'],
    sha384_b64 => [ 'Digest::SHA', 'sha384_base64' ],

    sha512_bin => [ 'Digest::SHA', 'sha512' ],
    sha512_hex => ['Digest::SHA'],
    sha512_b64 => [ 'Digest::SHA', 'sha512_base64' ],

    sha512224_bin => [ 'Digest::SHA', 'sha512224' ],
    sha512224_hex => ['Digest::SHA'],
    sha512224_b64 => [ 'Digest::SHA', 'sha512224_base64' ],

    sha512256_bin => [ 'Digest::SHA', 'sha512256' ],
    sha512256_hex => ['Digest::SHA'],
    sha512256_b64 => [ 'Digest::SHA', 'sha512256_base64' ],

    hmac_sha1_bin => [ 'Digest::SHA', 'hmac_sha1' ],
    hmac_sha1_hex => ['Digest::SHA'],
    hmac_sha1_b64 => [ 'Digest::SHA', 'hmac_sha1_base64' ],

    hmac_sha224_bin => [ 'Digest::SHA', 'hmac_sha224' ],
    hmac_sha224_hex => ['Digest::SHA'],
    hmac_sha224_b64 => [ 'Digest::SHA', 'hmac_sha224_base64' ],

    hmac_sha256_bin => [ 'Digest::SHA', 'hmac_sha256' ],
    hmac_sha256_hex => ['Digest::SHA'],
    hmac_sha256_b64 => [ 'Digest::SHA', 'hmac_sha256_base64' ],

    hmac_sha384_bin => [ 'Digest::SHA', 'hmac_sha384' ],
    hmac_sha384_hex => ['Digest::SHA'],
    hmac_sha384_b64 => [ 'Digest::SHA', 'hmac_sha384_base64' ],

    hmac_sha512_bin => [ 'Digest::SHA', 'hmac_sha512' ],
    hmac_sha512_hex => ['Digest::SHA'],
    hmac_sha512_b64 => [ 'Digest::SHA', 'hmac_sha512_base64' ],

    hmac_sha512224_bin => [ 'Digest::SHA', 'hmac_sha512224' ],
    hmac_sha512224_hex => ['Digest::SHA'],
    hmac_sha512224_b64 => [ 'Digest::SHA', 'hmac_sha512224_base64' ],

    hmac_sha512256_bin => [ 'Digest::SHA', 'hmac_sha512256' ],
    hmac_sha512256_hex => ['Digest::SHA'],
    hmac_sha512256_b64 => [ 'Digest::SHA', 'hmac_sha512256_base64' ],

    sha3_224_bin => [ 'Digest::SHA3', 'sha3_224' ],
    sha3_224_hex => ['Digest::SHA3'],
    sha3_224_b64 => [ 'Digest::SHA3', 'sha3_224_base64' ],

    sha3_256_bin => [ 'Digest::SHA3', 'sha3_256' ],
    sha3_256_hex => ['Digest::SHA3'],
    sha3_256_b64 => [ 'Digest::SHA3', 'sha3_256_base64' ],

    sha3_384_bin => [ 'Digest::SHA3', 'sha3_384' ],
    sha3_384_hex => ['Digest::SHA3'],
    sha3_384_b64 => [ 'Digest::SHA3', 'sha3_384_base64' ],

    sha3_512_bin => [ 'Digest::SHA3', 'sha3_512' ],
    sha3_512_hex => ['Digest::SHA3'],
    sha3_512_b64 => [ 'Digest::SHA3', 'sha3_512_base64' ],
};

sub ON_EXPORT ($name) {
    my $spec = delete $IMPORT->{$name};

    return if !$spec;

    P->class->load( $spec->[0] );

    *{$name} = \&{"$spec->[0]\::@{[ $spec->[1] // $name ]}"};

    return;
}

sub AUTOLOAD {    ## no critic qw[ClassHierarchies::ProhibitAutoloading]
    my $name = our $AUTOLOAD =~ s/\A.*:://smr;

    ON_EXPORT($name);

    # check, that method was installed to avoid deep recursion for AUTOLOAD
    die qq[Sub "$name" is not defined] if !*{$name}{CODE};

    goto \&$name;
}

sub md5_stream {
    require Digest::MD5;

    return Digest::MD5->new;
}

sub sha1_stream {
    require Digest::SHA1;

    return Digest::SHA1->new;
}

1;
__END__
=pod

=encoding utf8

=cut
