package SBOM::CycloneDX::Enum::CryptoAssetType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        ALGORITHM               => 'algorithm',
        CERTIFICATE             => 'certificate',
        PROTOCOL                => 'protocol',
        RELATED_CRYPTO_MATERIAL => 'related-crypto-material'
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

SBOM::CycloneDX::Enum::CryptoAssetType - Crypto Asset Type

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_ASSET_TYPE);

    say CRYPTO_FUNCTION->ALGORITHM;


    use SBOM::CycloneDX::Enum::CryptoAssetType;

    say SBOM::CycloneDX::Enum::CryptoAssetType->CERTIFICATE;


    use SBOM::CycloneDX::Enum::CryptoAssetType qw(:all);

    say RELATED_CRYPTO_MATERIAL;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoAssetType> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties>.

Cryptographic assets occur in several forms. Algorithms and protocols are
most commonly implemented in specialized cryptographic libraries. They may,
however, also be 'hardcoded' in software components. Certificates and
related cryptographic material like keys, tokens, secrets or passwords are
other cryptographic assets to be modelled.


=head1 CONSTANTS

=over

=item * C<ALGORITHM>, Mathematical function commonly used for data
encryption, authentication, and digital signatures.

=item * C<CERTIFICATE>, An electronic document that is used to provide the
identity or validate a public key.

=item * C<PROTOCOL>, A set of rules and guidelines that govern the behavior
and communication with each other.

=item * C<RELATED_CRYPTO_MATERIAL>, Other cryptographic assets related to
algorithms, certificates, and protocols such as keys and tokens.

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
