package SBOM::CycloneDX::Enum::RelatedCryptoMaterialType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        PRIVATE_KEY           => 'private-key',
        PUBLIC_KEY            => 'public-key',
        SECRET_KEY            => 'secret-key',
        KEY                   => 'key',
        CIPHERTEXT            => 'ciphertext',
        SIGNATURE             => 'signature',
        DIGEST                => 'digest',
        INITIALIZATION_VECTOR => 'initialization-vector',
        NONCE                 => 'nonce',
        SEED                  => 'seed',
        SALT                  => 'salt',
        SHARED_SECRET         => 'shared-secret',
        TAG                   => 'tag',
        ADDITIONAL_DATA       => 'additional-data',
        PASSWORD              => 'password',
        CREDENTIAL            => 'credential',
        TOKEN                 => 'token',
        OTHER                 => 'other',
        UNKNOWN               => 'unknown',
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

SBOM::CycloneDX::Enum::RelatedCryptoMaterialType - The type for the related cryptographic material

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(RELATED_CRYPTO_MATERIAL_TYPE);

    say RELATED_CRYPTO_MATERIAL_TYPE->PRIVATE_KEY;


    use SBOM::CycloneDX::Enum::RelatedCryptoMaterialType;

    say SBOM::CycloneDX::Enum::RelatedCryptoMaterialType->SECRET_KEY;


    use SBOM::CycloneDX::Enum::RelatedCryptoMaterialType qw(:all);

    say INITIALIZATION_VECTOR;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::RelatedCryptoMaterialType> is ENUM package used by L<SBOM::CycloneDX>.


=head1 CONSTANTS

=over

=item * L<PRIVATE_KEY>, The confidential key of a key pair used in
asymmetric cryptography.

=item * L<PUBLIC_KEY>, The non-confidential key of a key pair used in
asymmetric cryptography.

=item * L<SECRET_KEY>, A key used to encrypt and decrypt messages in
symmetric cryptography.

=item * L<KEY>, A piece of information, usually an octet string, which,
when processed through a cryptographic algorithm, processes cryptographic
data.

=item * L<CIPHERTEXT>, The result of encryption performed on plaintext
using an algorithm (or cipher).

=item * L<SIGNATURE>, A cryptographic value that is calculated from the
data and a key known only by the signer.

=item * L<DIGEST>, The output of the hash function.

=item * L<INITIALIZATION_VECTOR>, A fixed-size random or pseudo-random
value used as an input parameter for cryptographic algorithms.

=item * L<NONCE>, A random or pseudo-random number that can only be used
once in a cryptographic communication.

=item * L<SEED>, The input to a pseudo-random number generator. Different
seeds generate different pseudo-random sequences.

=item * L<SALT>, A value used in a cryptographic process, usually to ensure
that the results of computations for one instance cannot be reused by an
attacker.

=item * L<SHARED_SECRET>, A piece of data known only to the parties
involved, in a secure communication.

=item * L<TAG>, A message authentication code (MAC), sometimes known as an
authentication tag, is a short piece of information used for authenticating
and integrity-checking a message.

=item * L<ADDITIONAL_DATA>, An unspecified collection of data with
relevance to cryptographic activity.

=item * L<PASSWORD>, A secret word, phrase, or sequence of characters used
during authentication or authorization.

=item * L<CREDENTIAL>, Establishes the identity of a party to
communication, usually in the form of cryptographic keys or passwords.

=item * L<TOKEN>, An object encapsulating a security identity.

=item * L<OTHER>, Another type of cryptographic asset.

=item * L<UNKNOWN>, The type of cryptographic asset is not known.

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
