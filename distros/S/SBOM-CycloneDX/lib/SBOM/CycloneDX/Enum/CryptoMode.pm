package SBOM::CycloneDX::Enum::CryptoMode;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        CBC     => 'cbc',
        ECB     => 'ecb',
        CCM     => 'ccm',
        GCM     => 'gcm',
        CFB     => 'cfb',
        OFB     => 'ofb',
        CTR     => 'ctr',
        OTHER   => 'other',
        UNKNOWN => 'unknown',
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

SBOM::CycloneDX::Enum::CryptoMode - Crypto Mode

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_MODE);

    say CRYPTO_MODE->CBC;


    use SBOM::CycloneDX::Enum::CryptoMode;

    say SBOM::CycloneDX::Enum::CryptoMode->ECB;


    use SBOM::CycloneDX::Enum::CryptoMode qw(:all);

    say GCM;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoMode> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>.

The mode of operation in which the cryptographic algorithm (block cipher)
is used.


=head1 CONSTANTS

=over

=item * L<CBC>, Cipher block chaining

=item * L<ECB>, Electronic codebook

=item * L<CCM>, Counter with cipher block chaining message authentication
code

=item * L<GCM>, Galois/counter

=item * L<CFB>, Cipher feedback

=item * L<OFB>, Output feedback

=item * L<CTR>, Counter

=item * L<OTHER>, Another mode of operation

=item * L<UNKNOWN>, The mode of operation is not known

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
