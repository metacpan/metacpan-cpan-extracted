package SBOM::CycloneDX::Enum::CryptoImplementationPlatform;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        GENERIC => 'generic',
        X86_32  => 'x86_32',
        X86_64  => 'x86_64',
        ARMV7_A => 'armv7-a',
        ARMV7_M => 'armv7-m',
        ARMV8_A => 'armv8-a',
        ARMV8_M => 'armv8-m',
        ARMV9_A => 'armv9-a',
        ARMV9_M => 'armv9-m',
        S390X   => 's390x',
        PPC64   => 'ppc64',
        PPC64LE => 'ppc64le',
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

SBOM::CycloneDX::Enum::CryptoImplementationPlatform - Implementation platform

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_IMPLEMENTATION_PLATFORM);

    say CRYPTO_IMPLEMENTATION_PLATFORM->X86_64;


    use SBOM::CycloneDX::Enum::CryptoImplementationPlatform;

    say SBOM::CycloneDX::Enum::CryptoImplementationPlatform->GENERIC;


    use SBOM::CycloneDX::Enum::CryptoImplementationPlatform qw(:all);

    say ARMV7_A;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoImplementationPlatform> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>.

The target platform for which the algorithm is implemented. The
implementation can be 'generic', running on any platform or for a specific
platform.


=head1 CONSTANTS

=over

=item * L<GENERIC>

=item * L<X86_32>

=item * L<X86_64>

=item * L<ARMV7_A>

=item * L<ARMV7_M>

=item * L<ARMV8_A>

=item * L<ARMV8_M>

=item * L<ARMV9_A>

=item * L<ARMV9_M>

=item * L<S390X>

=item * L<PPC64>

=item * L<PPC64LE>

=item * L<OTHER>

=item * L<UNKNOWN>

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
