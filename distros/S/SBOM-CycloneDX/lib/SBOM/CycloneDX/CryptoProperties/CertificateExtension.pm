package SBOM::CycloneDX::CryptoProperties::CertificateExtension;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Enum;

use Types::Standard qw(Str Enum);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has common_extension_name  => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->COMMON_EXTENSION_NAMES()]);
has common_extension_value => (is => 'rw', isa => Str);
has custom_extension_name  => (is => 'rw', isa => Str);
has custom_extension_value => (is => 'rw', isa => Str);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{commonExtensionName}  = $self->common_extension_name  if $self->common_extension_name;
    $json->{commonExtensionValue} = $self->common_extension_value if $self->common_extension_value;
    $json->{customExtensionName}  = $self->custom_extension_name  if $self->custom_extension_name;
    $json->{customExtensionValue} = $self->custom_extension_value if $self->custom_extension_value;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::CryptoProperties::CertificateExtension - Certificate Extensions

=head1 SYNOPSIS

    SBOM::CycloneDX::CryptoProperties::CertificateExtension->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::CryptoProperties::CertificateExtension> A certificate
extension is a field that provides additional information about the
certificate or its use. Extensions are used to convey additional
information beyond the standard fields.

=head2 METHODS

=over

=item SBOM::CycloneDX::CryptoProperties::CertificateExtension->new( %PARAMS )

Properties:

=over

=item C<common_extension_name>, The name of the extension.

=over

=item * C<basicConstraints>, Specifies whether a certificate can be used as a 
CA certificate or not.

=item * C<keyUsage>, Specifies the allowed uses of the public key in the 
certificate.

=item * C<extendedKeyUsage>, Specifies additional purposes for which the public 
key can be used.

=item * C<subjectAlternativeName>, Allows inclusion of additional names to 
identify the entity associated with the certificate.

=item * C<authorityKeyIdentifier>, Identifies the public key of the CA that 
issued the certificate.

=item * C<subjectKeyIdentifier>, Identifies the public key associated with the 
entity the certificate was issued to.

=item * C<authorityInformationAccess>, Contains CA issuers and OCSP information.

=item * C<certificatePolicies>, Defines the policies under which the 
certificate was issued and can be used.

=item * C<crlDistributionPoints>, Contains one or more URLs where a Certificate 
Revocation List (CRL) can be obtained.

=item * C<signedCertificateTimestamp>, Shows that the certificate has been 
publicly logged, which helps prevent the issuance of rogue certificates by a 
CA. Log ID, timestamp and signature as proof

=back

=item C<common_extension_value>, The value of the certificate extension.

=back

Custom extensions may convey application-specific or vendor-specific data not 
covered by standard extensions. The structure and semantics of custom 
extensions are typically defined outside of public standards. CycloneDX 
leverages properties to support this capability.

=over

=item C<custom_extension_name>, The name for the custom certificate extension.

=item C<custom_extension_value>, The description of the custom certificate extension.

=back

=item $certificate_extension->common_extension_name

=item $certificate_extension->common_extension_value

=item $certificate_extension->custom_extension_name

=item $certificate_extension->custom_extension_value

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
