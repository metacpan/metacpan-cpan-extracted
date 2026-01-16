package SBOM::CycloneDX::CryptoProperties::CertificateProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has serial_number => (is => 'rw', isa => Str);
has subject_name  => (is => 'rw', isa => Str);
has issuer_name   => (is => 'rw', isa => Str);

has not_valid_before => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has not_valid_after => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has signature_algorithm_ref    => (is => 'rw', isa => Str);    # [DEPRECATED 1.7] Bom-ref like
has subject_public_key_ref     => (is => 'rw', isa => Str);    # [DEPRECATED 1.7] Bom-ref like
has certificate_format         => (is => 'rw', isa => Str);
has certificate_extension      => (is => 'rw', isa => Str);    # [DEPRECATED 1.7]
has certificate_file_extension => (is => 'rw', isa => Str);

has fingerprint => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Hash']);

has certificate_state => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::CryptoProperties::CertificateState']],
    default => sub { SBOM::CycloneDX::List->new }
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

has deactivation_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has revocation_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has destruction_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has certificate_extensions => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::CryptoProperties::CertificateExtension']],
    default => sub { SBOM::CycloneDX::List->new }
);

has related_cryptographic_assets => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{serialNumber}               = $self->serial_number                if $self->serial_number;
    $json->{subjectName}                = $self->subject_name                 if $self->subject_name;
    $json->{issuerName}                 = $self->issuer_name                  if $self->issuer_name;
    $json->{notValidBefore}             = $self->not_valid_before             if $self->not_valid_before;
    $json->{notValidAfter}              = $self->not_valid_after              if $self->not_valid_after;
    $json->{signatureAlgorithmRef}      = $self->signature_algorithm_ref      if $self->signature_algorithm_ref;
    $json->{subjectPublicKeyRef}        = $self->subject_public_key_ref       if $self->subject_public_key_ref;
    $json->{certificateFormat}          = $self->certificate_format           if $self->certificate_format;
    $json->{certificateExtension}       = $self->certificate_extension        if $self->certificate_extension;
    $json->{certificateFileExtension}   = $self->certificate_file_extension   if $self->certificate_file_extension;
    $json->{fingerprint}                = $self->fingerprint                  if $self->fingerprint;
    $json->{certificateState}           = $self->certificate_state            if @{$self->certificate_state};
    $json->{creationDate}               = $self->creation_date                if $self->creation_date;
    $json->{activationDate}             = $self->activation_date              if $self->activation_date;
    $json->{deactivationDate}           = $self->deactivation_date            if $self->deactivation_date;
    $json->{revocationDate}             = $self->revocation_date              if $self->revocation_date;
    $json->{destructionDate}            = $self->destruction_date             if $self->destruction_date;
    $json->{certificateExtensions}      = $self->certificate_extensions       if @{$self->certificate_extensions};
    $json->{relatedCryptographicAssets} = $self->related_cryptographic_assets if @{$self->related_cryptographic_assets};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::CertificateProperties - Properties for cryptographic
assets of asset type 'certificate'

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::CertificateProperties->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::CertificateProperties> specifies the properties for
cryptographic assets of asset type 'certificate'.

=head2 METHODS

L<SBOM::CycloneDX::CryptoProperties::CertificateProperties> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::CryptoProperties::CertificateProperties->new( %PARAMS )

Properties:

=over

=item C<activation_date>, The date and time (timestamp) when the certificate was activated.

=item C<certificate_extension>, [DEPRECATED] This will be removed in a future version.
Use C<certificate_file_extension> instead. The file extension of the certificate.

=item C<certificate_extensions>, A certificate extension is a field that
provides additional information about the certificate or its use. Extensions
are used to convey additional information beyond the standard fields.

See L<SBOM::CycloneDX::CryptoProperties::CertificateExtension>

=item C<certificate_file_extension>, The file extension of the certificate

=item C<certificate_format>, The format of the certificate

=item C<certificate_state>, Certificate Lifecycle State

The certificate lifecycle is a comprehensive process that manages digital
certificates from their initial creation to eventual expiration or revocation.
It typically involves several stages.

See L<SBOM::CycloneDX::CertificateProperties::CertificateState>

=item C<creation_date>, The date and time (timestamp) when the certificate was created or pre-activated.

=item C<deactivation_date>, The date and time (timestamp) when the related certificate was deactivated.

=item C<destruction_date>, The date and time (timestamp) when the certificate was destroyed.

=item C<fingerprint>, The fingerprint is a cryptographic hash of the certificate excluding it's signature.

See L<SBOM::CycloneDX::Hash>

=item C<issuer_name>, The issuer name for the certificate

=item C<not_valid_after>, The date and time according to ISO-8601 standard
from which the certificate is not valid anymore

=item C<not_valid_before>, The date and time according to ISO-8601 standard
from which the certificate is valid

=item C<related_cryptographic_assets>, 

=item C<revocation_date>, The date and time (timestamp) when the certificate was revoked.

=item C<serial_number>, The serial number is a unique identifier for the certificate issued by a CA.

=item C<signature_algorithm_ref>, [DEPRECATED] This will be removed in a future version. Use C<related_cryptographic_assets> instead.
The bom-ref to signature algorithm used by the certificate.

=item C<subject_name>, The subject name for the certificate

=item C<subject_public_key_ref>, [DEPRECATED] This will be removed in a future version. Use C<related_cryptographic_assets> instead.
The bom-ref to the public key of the subject.

=back

=item $certificate_properties->activation_date

=item $certificate_properties->certificate_extension

=item $certificate_properties->certificate_extensions

=item $certificate_properties->certificate_format

=item $certificate_properties->certificate_state

=item $certificate_properties->creation_date

=item $certificate_properties->deactivation_date

=item $certificate_properties->destruction_date

=item $certificate_properties->fingerprint

=item $certificate_properties->issuer_name

=item $certificate_properties->not_valid_after

=item $certificate_properties->not_valid_before

=item $certificate_properties->related_cryptographic_assets

=item $certificate_properties->revocation_date

=item $certificate_properties->serial_number

=item $certificate_properties->signature_algorithm_ref

=item $certificate_properties->subject_name

=item $certificate_properties->subject_public_key_ref

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
