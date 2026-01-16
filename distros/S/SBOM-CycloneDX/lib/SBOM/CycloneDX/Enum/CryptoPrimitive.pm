package SBOM::CycloneDX::Enum::CryptoPrimitive;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        DRBG          => 'drbg',
        MAC           => 'mac',
        BLOCK_CIPHER  => 'block-cipher',
        STREAM_CIPHER => 'stream-cipher',
        SIGNATURE     => 'signature',
        HASH          => 'hash',
        PKE           => 'pke',
        XOF           => 'xof',
        KDF           => 'kdf',
        KEY_AGREE     => 'key-agree',
        KEM           => 'kem',
        AE            => 'ae',
        COMBINER      => 'combiner',
        KEY_WRAP      => 'key-wrap',
        OTHER         => 'other',
        UNKNOWN       => 'unknown',
    );

    require constant;
    constant->import(\%ENUM);

    @EXPORT_OK   = sort keys %ENUM;
    %EXPORT_TAGS = (all => \@EXPORT_OK);

}

sub values { sort values %ENUM }


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum::CryptoPrimitive - primitive

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_PRIMITIVE);

    say CRYPTO_PRIMITIVE->BLOCK_CIPHER;


    use SBOM::CycloneDX::Enum::CryptoPrimitive;

    say SBOM::CycloneDX::Enum::CryptoPrimitive->PKE;


    use SBOM::CycloneDX::Enum::CryptoPrimitive qw(:all);

    say KDF;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoPrimitive> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>.

Cryptographic building blocks used in higher-level cryptographic systems
and protocols. Primitives represent different cryptographic routines:
deterministic random bit generators (drbg, e.g. CTR_DRBG from NIST
SP800-90A-r1), message authentication codes (mac, e.g. HMAC-SHA-256),
blockciphers (e.g. AES), streamciphers (e.g. Salsa20), signatures (e.g.
ECDSA), hash functions (e.g. SHA-256), public-key encryption schemes (pke,
e.g. RSA), extended output functions (xof, e.g. SHAKE256), key derivation
functions (e.g. pbkdf2), key agreement algorithms (e.g. ECDH), key
encapsulation mechanisms (e.g. ML-KEM), authenticated encryption (ae, e.g.
AES-GCM) and the combination of multiple algorithms (combiner, e.g.
SP800-56Cr2).


=head1 CONSTANTS

=over

=item * L<DRBG>, Deterministic Random Bit Generator (DRBG) is a type of
pseudorandom number generator designed to produce a sequence of bits from
an initial seed value. DRBGs are commonly used in cryptographic
applications where reproducibility of random values is important.

=item * L<MAC>, In cryptography, a Message Authentication Code (MAC) is
information used for authenticating and integrity-checking a message.

=item * L<BLOCK_CIPHER>, A block cipher is a symmetric key algorithm that
operates on fixed-size blocks of data. It encrypts or decrypts the data in
block units, providing confidentiality. Block ciphers are widely used in
various cryptographic modes and protocols for secure data transmission.

=item * L<STREAM_CIPHER>, A stream cipher is a symmetric key cipher where
plaintext digits are combined with a pseudorandom cipher digit stream
(keystream).

=item * L<SIGNATURE>, In cryptography, a signature is a digital
representation of a message or data that proves its origin, identity, and
integrity. Digital signatures are generated using cryptographic algorithms
and are widely used for authentication and verification in secure
communication.

=item * L<HASH>, A hash function is a mathematical algorithm that takes an
input (or 'message') and produces a fixed-size string of characters, which
is typically a hash value. Hash functions are commonly used in various
cryptographic applications, including data integrity verification and
password hashing.

=item * L<PKE>, Public Key Encryption (PKE) is a type of encryption that
uses a pair of public and private keys for secure communication. The public
key is used for encryption, while the private key is used for decryption.
PKE is a fundamental component of public-key cryptography.

=item * L<XOF>, An XOF is an extendable output function that can take
arbitrary input and creates a stream of output, up to a limit determined by
the size of the internal state of the hash function that underlies the XOF.

=item * L<KDF>, A Key Derivation Function (KDF) derives key material from
another source of entropy while preserving the entropy of the input.

=item * L<KEY_AGREE>, In cryptography, a key-agreement is a protocol
whereby two or more parties agree on a cryptographic key in such a way that
both influence the outcome.

=item * L<KEM>, A Key Encapsulation Mechanism (KEM) algorithm is a
mechanism for transporting random keying material to a recipient using the
recipient's public key.

=item * L<AE>, Authenticated Encryption (AE) is a cryptographic process
that provides both confidentiality and data integrity. It ensures that the
encrypted data has not been tampered with and comes from a legitimate
source. AE is commonly used in secure communication protocols.

=item * L<COMBINER>, A combiner aggregates many candidates for a
cryptographic primitive and generates a new candidate for the same
primitive.

=item * L<KEY_WRAP>, Key-wrap is a cryptographic technique used to securely
encrypt and protect cryptographic keys using algorithms like AES.

=item * L<OTHER>, Another primitive type.

=item * L<UNKNOWN>, The primitive is not known.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
