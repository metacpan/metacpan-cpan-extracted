package SBOM::CycloneDX::Enum::CommonExtensionName;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        BASIC_CONSTRAINTS            => 'basicConstraints',
        KEY_USAGE                    => 'keyUsage',
        EXTENDED_KEY_USAGE           => 'extendedKeyUsage',
        SUBJECT_ALTERNATIVE_NAME     => 'subjectAlternativeName',
        AUTHORITY_KEY_IDENTIFIER     => 'authorityKeyIdentifier',
        SUBJECT_KEY_IDENTIFIER       => 'subjectKeyIdentifier',
        AUTHORITY_INFORMATION_ACCESS => 'authorityInformationAccess',
        CERTIFICATE_POLICIES         => 'certificatePolicies',
        CRL_DISTRIBUTION_POINTS      => 'crlDistributionPoints',
        SIGNED_CERTIFICATE_TIMESTAMP => 'signedCertificateTimestamp',
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

SBOM::CycloneDX::Enum::CommonExtensionName - The name of the certificate extension

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(COMMON_EXTENSION_NAME);

    say COMMON_EXTENSION_NAME->KEY_USAGE;


    use SBOM::CycloneDX::Enum::CommonExtensionName;

    say SBOM::CycloneDX::Enum::CommonExtensionName->EXTENDED_KEY_USAGE;


    use SBOM::CycloneDX::Enum::CommonExtensionName qw(:all);

    say CRL_DISTRIBUTION_POINTS;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CommonExtensionName> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::CertificateExtension>.

A certificate extension is a field that provides additional information about the
certificate or its use. Extensions are used to convey additional information beyond
the standard fields.


=head1 CONSTANTS

=over

=item * C<BASIC_CONSTRAINTS>, Specifies whether a certificate can be used as a
CA certificate or not.

=item * C<KEY_USAGE>, Specifies the allowed uses of the public key in the certificate.

=item * C<EXTENDED_KEY_USAGE>, Specifies additional purposes for which the public
key can be used.

=item * C<SUBJECT_ALTERNATIVE_NAME>, Allows inclusion of additional names to
identify the entity associated with the certificate.

=item * C<AUTHORITY_KEY_IDENTIFIER>, Identifies the public key of the CA that
issued the certificate.

=item * C<SUBJECT_KEY_IDENTIFIER>, Identifies the public key associated with the
entity the certificate was issued to.

=item * C<AUTHORITY_INFORMATION_ACCESS>, Contains CA issuers and OCSP information.

=item * C<CERTIFICATE_POLICIES>, Defines the policies under which the certificate
was issued and can be used.

=item * C<CRL_DISTRIBUTION_POINTS>, Contains one or more URLs where a Certificate
Revocation List (CRL) can be obtained.

=item * C<SIGNED_CERTIFICATE_TIMESTAMP>, Shows that the certificate has been
publicly logged, which helps prevent the issuance of rogue certificates by a CA.
Log ID, timestamp and signature as proof.

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
