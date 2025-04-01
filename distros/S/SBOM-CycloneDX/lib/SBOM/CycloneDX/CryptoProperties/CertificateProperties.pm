package SBOM::CycloneDX::CryptoProperties::CertificateProperties;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has subject_name => (is => 'rw', isa => Str);
has issuer_name  => (is => 'rw', isa => Str);

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

has signature_algorithm_ref => (is => 'rw', isa => Str);    # Bom-ref like
has subject_public_key_ref  => (is => 'rw', isa => Str);    # Bom-ref like
has certificate_format      => (is => 'rw', isa => Str);
has certificate_extension   => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{subjectName}           = $self->subject_name            if $self->subject_name;
    $json->{issuerName}            = $self->issuer_name             if $self->issuer_name;
    $json->{notValidBefore}        = $self->not_valid_before        if $self->not_valid_before;
    $json->{notValidAfter}         = $self->not_valid_after         if $self->not_valid_after;
    $json->{signatureAlgorithmRef} = $self->signature_algorithm_ref if $self->signature_algorithm_ref;
    $json->{subjectPublicKeyRef}   = $self->subject_public_key_ref  if $self->subject_public_key_ref;
    $json->{certificateFormat}     = $self->certificate_format      if $self->certificate_format;
    $json->{certificateExtension}  = $self->certificate_extension   if $self->certificate_extension;

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

=item C<certificate_extension>, The file extension of the certificate

=item C<certificate_format>, The format of the certificate

=item C<issuer_name>, The issuer name for the certificate

=item C<not_valid_after>, The date and time according to ISO-8601 standard
from which the certificate is not valid anymore

=item C<not_valid_before>, The date and time according to ISO-8601 standard
from which the certificate is valid

=item C<signature_algorithm_ref>, The bom-ref to signature algorithm used
by the certificate

=item C<subject_name>, The subject name for the certificate

=item C<subject_public_key_ref>, The bom-ref to the public key of the
subject

=back

=item $certificate_properties->certificate_extension

=item $certificate_properties->certificate_format

=item $certificate_properties->issuer_name

=item $certificate_properties->not_valid_after

=item $certificate_properties->not_valid_before

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
