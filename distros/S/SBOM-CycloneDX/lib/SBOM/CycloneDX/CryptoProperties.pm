package SBOM::CycloneDX::CryptoProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::CryptoProperties::AlgorithmProperties;
use SBOM::CycloneDX::CryptoProperties::CertificateProperties;
use SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties;
use SBOM::CycloneDX::CryptoProperties::ProtocolProperties;
use SBOM::CycloneDX::Enum;

use Types::Standard qw(Str Enum InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has asset_type => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->CRYPTO_ASSET_TYPES()], required => 1);

has algorithm_properties => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::CryptoProperties::AlgorithmProperties'],
    default => sub { SBOM::CycloneDX::CryptoProperties::AlgorithmProperties->new }
);

has certificate_properties => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::CryptoProperties::CertificateProperties'],
    default => sub { SBOM::CycloneDX::CryptoProperties::CertificateProperties->new }
);

has related_crypto_material_properties => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties'],
    default => sub { SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties->new }
);

has protocol_properties => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::CryptoProperties::ProtocolProperties'],
    default => sub { SBOM::CycloneDX::CryptoProperties::ProtocolProperties->new }
);

has oid => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{assetType} = $self->asset_type if $self->asset_type;

    $json->{algorithmProperties}   = $self->algorithm_properties   if %{$self->algorithm_properties->TO_JSON};
    $json->{certificateProperties} = $self->certificate_properties if %{$self->certificate_properties->TO_JSON};

    $json->{relatedCryptoMaterialProperties} = $self->related_crypto_material_properties
        if %{$self->related_crypto_material_properties->TO_JSON};

    $json->{protocolProperties} = $self->protocol_properties if %{$self->protocol_properties->TO_JSON};

    $json->{oid} = $self->oid if $self->oid;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties - Cryptographic Properties

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties> Cryptographic assets have properties
that uniquely define them and that make them actionable for further
reasoning. As an example, it makes a difference if one knows the algorithm
family (e.g. AES) or the specific variant or instantiation (e.g.
AES-128-GCM). This is because the security level and the algorithm
primitive (authenticated encryption) are only defined by the definition of
the algorithm variant. The presence of a weak cryptographic algorithm like
SHA1 vs. HMAC-SHA1 also makes a difference.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties->new( %PARAMS )

Properties:

=over

=item C<algorithm_properties>, Additional properties specific to a
cryptographic algorithm.

=item C<asset_type>, Cryptographic assets occur in several forms.
Algorithms and protocols are most commonly implemented in specialized
cryptographic libraries. They may, however, also be 'hardcoded' in software
components. Certificates and related cryptographic material like keys,
tokens, secrets or passwords are other cryptographic assets to be modelled.

=item C<certificate_properties>, Properties for cryptographic assets of
asset type 'certificate'

=item C<oid>, The object identifier (OID) of the cryptographic asset.

=item C<protocol_properties>, Properties specific to cryptographic assets
of type: `protocol`.

=item C<related_crypto_material_properties>, Properties for cryptographic
assets of asset type: `related-crypto-material`

=back

=item $crypto_properties->algorithm_properties

=item $crypto_properties->asset_type

=item $crypto_properties->certificate_properties

=item $crypto_properties->oid

=item $crypto_properties->protocol_properties

=item $crypto_properties->related_crypto_material_properties

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
