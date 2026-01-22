package SBOM::CycloneDX::Enum::CryptoPadding;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        PKCS5    => 'pkcs5',
        PKCS7    => 'pkcs7',
        PKCS1V15 => 'pkcs1v15',
        OAEP     => 'oaep',
        RAW      => 'raw',
        OTHER    => 'other',
        UNKNOWN  => 'unknown',
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

SBOM::CycloneDX::Enum::CryptoPadding - Crypto Padding

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_PADDING);

    say XYZ->PKCS5;


    use SBOM::CycloneDX::Enum::CryptoPadding;

    say SBOM::CycloneDX::Enum::CryptoPadding->PKCS7;


    use SBOM::CycloneDX::Enum::CryptoPadding qw(:all);

    say OAEP;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoPadding> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>.

The padding scheme that is used for the cryptographic algorithm.


=head1 CONSTANTS

=over

=item * C<PKCS5>, Public Key Cryptography Standard: Password-Based
Cryptography

=item * C<PKCS7>, Public Key Cryptography Standard: Cryptographic Message
Syntax

=item * C<PKCS1V15>, Public Key Cryptography Standard: RSA Cryptography
v1.5

=item * C<OAEP>, Optimal asymmetric encryption padding

=item * C<RAW>, Raw

=item * C<OTHER>, Another padding scheme

=item * C<UNKNOWN>, The padding scheme is not known

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
