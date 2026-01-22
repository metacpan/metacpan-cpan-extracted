package SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::CryptoProperties::SecuredBy;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::Hash;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str Enum Num InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has type  => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('RELATED_CRYPTO_MATERIAL_TYPE')]);
has id    => (is => 'rw', isa => Str);
has state => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('RELATED_CRYPTO_MATERIAL_STATE')]);

has algorithm_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has creation_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has activation_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has update_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has expiration_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has value  => (is => 'rw', isa => Str);
has size   => (is => 'rw', isa => Num);
has format => (is => 'rw', isa => Str);

has secured_by => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::CryptoProperties::SecuredBy'],
    default => sub { SBOM::CycloneDX::CryptoProperties::SecuredBy->new }
);

has fingerprint => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Hash']);

has related_cryptographic_assets => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{type}                       = $self->type                         if $self->type;
    $json->{id}                         = $self->id                           if $self->id;
    $json->{state}                      = $self->state                        if $self->state;
    $json->{algorithmRef}               = $self->algorithm_ref                if $self->algorithm_ref;
    $json->{creationDate}               = $self->creation_date                if $self->creation_date;
    $json->{activationDate}             = $self->activation_date              if $self->activation_date;
    $json->{updateDate}                 = $self->update_date                  if $self->update_date;
    $json->{expirationDate}             = $self->expiration_date              if $self->expiration_date;
    $json->{value}                      = $self->value                        if $self->value;
    $json->{size}                       = $self->size                         if $self->size;
    $json->{format}                     = $self->format                       if $self->format;
    $json->{securedBy}                  = $self->secured_by                   if %{$self->secured_by->TO_JSON};
    $json->{fingerprint}                = $self->fingerprint                  if $self->fingerprint;
    $json->{relatedCryptographicAssets} = $self->related_cryptographic_assets if @{$self->related_cryptographic_assets};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties - Related Cryptographic Material Properties

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties> specifies
properties for cryptographic assets of asset type: "related-crypto-material".

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties->new( %PARAMS )

Properties:

=over

=item * C<activation_date>, The date and time (timestamp) when the related
cryptographic material was activated.

=item * C<algorithm_ref>, The bom-ref to the algorithm used to generate the
related cryptographic material.

=item * C<creation_date>, The date and time (timestamp) when the related
cryptographic material was created.

=item * C<expiration_date>, The date and time (timestamp) when the related
cryptographic material expires.

=item * C<fingerprint>, The fingerprint is a cryptographic hash of the asset.

See L<SBOM::CycloneDX::Hash>

=item * C<format>, The format of the related cryptographic material (e.g. P8,
PEM, DER).

=item * C<id>, The unique identifier for the related cryptographic
material.

=item * C<related_cryptographic_assets>, A list of cryptographic assets related
to this component.

See L<SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset>

=item * C<secured_by>, The mechanism by which the cryptographic asset is
secured by.

=item * C<size>, The size of the cryptographic asset (in bits).

=item * C<state>, The key state as defined by NIST SP 800-57.

=item * C<type>, The type for the related cryptographic material

=item * C<update_date>, The date and time (timestamp) when the related
cryptographic material was updated.

=item * C<value>, The associated value of the cryptographic material.

=back

=item $related_crypto_material_properties->activation_date

=item $related_crypto_material_properties->algorithm_ref

=item $related_crypto_material_properties->creation_date

=item $related_crypto_material_properties->expiration_date

=item $related_crypto_material_properties->format

=item $related_crypto_material_properties->id

=item $related_crypto_material_properties->secured_by

=item $related_crypto_material_properties->size

=item $related_crypto_material_properties->state

=item $related_crypto_material_properties->type

=item $related_crypto_material_properties->update_date

=item $related_crypto_material_properties->value

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
