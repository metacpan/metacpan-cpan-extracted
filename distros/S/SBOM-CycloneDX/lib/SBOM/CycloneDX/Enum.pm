package SBOM::CycloneDX::Enum;

use 5.010001;
use strict;
use warnings;
use utf8;

require SBOM::CycloneDX::Schema;
require SBOM::CycloneDX::Util;

use SBOM::CycloneDX::Enum::CommonExtensionName          ();
use SBOM::CycloneDX::Enum::ComponentType                ();
use SBOM::CycloneDX::Enum::CryptoAssetType              ();
use SBOM::CycloneDX::Enum::CryptoCertificationLevel     ();
use SBOM::CycloneDX::Enum::CryptoFunction               ();
use SBOM::CycloneDX::Enum::CryptoImplementationPlatform ();
use SBOM::CycloneDX::Enum::CryptoMode                   ();
use SBOM::CycloneDX::Enum::CryptoPadding                ();
use SBOM::CycloneDX::Enum::CryptoPrimitive              ();
use SBOM::CycloneDX::Enum::ExternalReferenceType        ();
use SBOM::CycloneDX::Enum::HashAlgorithm                ();
use SBOM::CycloneDX::Enum::LicenseType                  ();
use SBOM::CycloneDX::Enum::LifecyclePhase               ();
use SBOM::CycloneDX::Enum::ProtocolType                 ();
use SBOM::CycloneDX::Enum::RelatedCryptoMaterialState   ();
use SBOM::CycloneDX::Enum::RelatedCryptoMaterialType    ();
use SBOM::CycloneDX::Enum::TlpClassification            ();

use Cpanel::JSON::XS qw(decode_json);

use Exporter 'import';

our @EXPORT_OK = qw(
    COMMON_EXTENSION_NAME
    COMPONENT_TYPE
    CRYPTO_ASSET_TYPE
    CRYPTO_CERTIFICATION_LEVEL
    CRYPTO_FUNCTION
    CRYPTO_IMPLEMENTATION_PLATFORM
    CRYPTO_MODE
    CRYPTO_PADDING
    CRYPTO_PRIMITIVE
    EXTERNAL_REFERENCE_TYPE
    HASH_ALGORITHM
    LICENSE_TYPE
    LIFECYCLE_PHASE
    PROTOCOL_TYPE
    RELATED_CRYPTO_MATERIAL_STATE
    RELATED_CRYPTO_MATERIAL_TYPE
    TLP_CLASSIFICATION
);

state @SPDX_LICENSES = do {
    my $spdx_json_schema_file = SBOM::CycloneDX::Schema::schema_file('spdx.schema.json');
    my $spdx_json_schema      = decode_json(SBOM::CycloneDX::Util::file_read($spdx_json_schema_file));

    @{$spdx_json_schema->{enum}};
};

use constant SPDX_LICENSES => \@SPDX_LICENSES;

# LEGACY
use constant COMMON_EXTENSION_NAMES          => SBOM::CycloneDX::Enum::CommonExtensionName->values();
use constant COMPONENT_TYPES                 => SBOM::CycloneDX::Enum::ComponentType->values();
use constant CRYPTO_ASSET_TYPES              => SBOM::CycloneDX::Enum::CryptoAssetType->values();
use constant CRYPTO_CERTIFICATION_LEVELS     => SBOM::CycloneDX::Enum::CryptoCertificationLevel->values();
use constant CRYPTO_FUNCTIONS                => SBOM::CycloneDX::Enum::CryptoFunction->values();
use constant CRYPTO_IMPLEMENTATION_PLATFORMS => SBOM::CycloneDX::Enum::CryptoImplementationPlatform->values();
use constant CRYPTO_MODES                    => SBOM::CycloneDX::Enum::CryptoMode->values();
use constant CRYPTO_PADDINGS                 => SBOM::CycloneDX::Enum::CryptoAssetType->values();
use constant CRYPTO_PRIMITIVES               => SBOM::CycloneDX::Enum::CryptoPrimitive->values();
use constant EXTERNAL_REFERENCE_TYPES        => SBOM::CycloneDX::Enum::ExternalReferenceType->values();
use constant HASH_ALGORITHMS                 => SBOM::CycloneDX::Enum::HashAlgorithm->values();
use constant LICENSE_TYPES                   => SBOM::CycloneDX::Enum::LicenseType->values();
use constant LIFECYCLE_PHASES                => SBOM::CycloneDX::Enum::LifecyclePhase->values();
use constant PROTOCOL_TYPES                  => SBOM::CycloneDX::Enum::ProtocolType->values();
use constant RELATED_CRYPTO_MATERIAL_STATES  => SBOM::CycloneDX::Enum::RelatedCryptoMaterialState->values();
use constant RELATED_CRYPTO_MATERIAL_TYPES   => SBOM::CycloneDX::Enum::RelatedCryptoMaterialType->values();
use constant TLP_CLASSIFICATIONS             => SBOM::CycloneDX::Enum::TlpClassification->values();


use constant {
    COMMON_EXTENSION_NAME          => 'SBOM::CycloneDX::Enum::CommonExtensionName',
    COMPONENT_TYPE                 => 'SBOM::CycloneDX::Enum::ComponentType',
    CRYPTO_ASSET_TYPE              => 'SBOM::CycloneDX::Enum::CryptoAssetType',
    CRYPTO_CERTIFICATION_LEVEL     => 'SBOM::CycloneDX::Enum::CryptoCertificationLevel',
    CRYPTO_FUNCTION                => 'SBOM::CycloneDX::Enum::CryptoFunction',
    CRYPTO_IMPLEMENTATION_PLATFORM => 'SBOM::CycloneDX::Enum::CryptoImplementationPlatform',
    CRYPTO_MODE                    => 'SBOM::CycloneDX::Enum::CryptoMode',
    CRYPTO_PADDING                 => 'SBOM::CycloneDX::Enum::CryptoPadding',
    CRYPTO_PRIMITIVE               => 'SBOM::CycloneDX::Enum::CryptoPrimitive',
    EXTERNAL_REFERENCE_TYPE        => 'SBOM::CycloneDX::Enum::ExternalReferenceType',
    HASH_ALGORITHM                 => 'SBOM::CycloneDX::Enum::HashAlgorithm',
    LICENSE_TYPE                   => 'SBOM::CycloneDX::Enum::LicenseType',
    LIFECYCLE_PHASE                => 'SBOM::CycloneDX::Enum::LifecyclePhase',
    PROTOCOL_TYPE                  => 'SBOM::CycloneDX::Enum::ProtocolType',
    RELATED_CRYPTO_MATERIAL_STATE  => 'SBOM::CycloneDX::Enum::RelatedCryptoMaterialState',
    RELATED_CRYPTO_MATERIAL_TYPE   => 'SBOM::CycloneDX::Enum::RelatedCryptoMaterialType',
    TLP_CLASSIFICATION             => 'SBOM::CycloneDX::Enum::TlpClassification',
};

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum - Enumeration

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(COMPONENT_TYPE);

    $bom->component( type => COMPONENT_TYPE->APPLICATION );


    use SBOM::CycloneDX::Enum::ComponentType qw(:all);

    $bom->component( type => APPLICATION );


    use SBOM::CycloneDX::Enum::ComponentType;

    $bom->component( type => SBOM::CycloneDX::Enum::ComponentType->APPLICATION );


    use SBOM::CycloneDX::Enum;

    say $_ for (@{SBOM::CycloneDX::Enum->SPDX_LICENSES})

=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum> is internal class used by L<SBOM::CycloneDX>.


=head1 CONSTANTS

=over

=item * C<COMMON_EXTENSION_NAME>, L<SBOM::CycloneDX::Enum::CommonExtensionName>

=item * C<COMPONENT_TYPE>, L<SBOM::CycloneDX::Enum::ComponentType>

=item * C<CRYPTO_ASSET_TYPE>, L<SBOM::CycloneDX::Enum::CryptoAssetType>

=item * C<CRYPTO_CERTIFICATION_LEVEL>, L<SBOM::CycloneDX::Enum::CryptoCertificationLevel>

=item * C<CRYPTO_FUNCTION>, L<SBOM::CycloneDX::Enum::CryptoFunction>

=item * C<CRYPTO_IMPLEMENTATION_PLATFORM> , L<SBOM::CycloneDX::Enum::CryptoImplementationPlatform>

=item * C<CRYPTO_MODE>, L<SBOM::CycloneDX::Enum::CryptoMode>

=item * C<CRYPTO_PADDING>, L<SBOM::CycloneDX::Enum::CryptoPadding>

=item * C<CRYPTO_PRIMITIVE>, L<SBOM::CycloneDX::Enum::CryptoPrimitive>

=item * C<EXTERNAL_REFERENCE_TYPE>, L<SBOM::CycloneDX::Enum::ExternalReferenceType>

=item * C<HASH_ALGORITHM>, L<SBOM::CycloneDX::Enum::HashAlgorithm>

=item * C<LICENSE_TYPE>, L<SBOM::CycloneDX::Enum::LicenseType>

=item * C<LIFECYCLE_PHASE>, L<SBOM::CycloneDX::Enum::LifecyclePhase>

=item * C<PROTOCOL_TYPE>, L<SBOM::CycloneDX::Enum::ProtocolType>

=item * C<RELATED_CRYPTO_MATERIAL_STATE>, L<SBOM::CycloneDX::Enum::RelatedCryptoMaterialState>

=item * C<RELATED_CRYPTO_MATERIAL_TYPE>, L<SBOM::CycloneDX::Enum::RelatedCryptoMaterialType>

=item * C<TLP_CLASSIFICATION>, L<SBOM::CycloneDX::Enum::TlpClassification>

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
