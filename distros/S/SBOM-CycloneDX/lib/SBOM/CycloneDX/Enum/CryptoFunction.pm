package SBOM::CycloneDX::Enum::CryptoFunction;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        GENERATE    => 'generate',
        KEYGEN      => 'keygen',
        ENCRYPT     => 'encrypt',
        DECRYPT     => 'decrypt',
        DIGEST      => 'digest',
        TAG         => 'tag',
        KEYDERIVE   => 'keyderive',
        SIGN        => 'sign',
        VERIFY      => 'verify',
        ENCAPSULATE => 'encapsulate',
        DECAPSULATE => 'decapsulate',
        OTHER       => 'other',
        UNKNOWN     => 'unknown',
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

SBOM::CycloneDX::Enum::CryptoFunction - The cryptographic functions implemented by the cryptographic algorithm

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(CRYPTO_FUNCTION);

    say CRYPTO_FUNCTION->GENERATE;


    use SBOM::CycloneDX::Enum::CryptoFunction;

    say SBOM::CycloneDX::Enum::CryptoFunction->KEYGEN;


    use SBOM::CycloneDX::Enum::CryptoFunction qw(:all);

    say DECRYPT;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::CryptoFunction> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>.


=head1 CONSTANTS

=over

=item * C<GENERATE>

=item * C<KEYGEN>

=item * C<ENCRYPT>

=item * C<DECRYPT>

=item * C<DIGEST>

=item * C<TAG>

=item * C<KEYDERIVE>

=item * C<SIGN>

=item * C<VERIFY>

=item * C<ENCAPSULATE>

=item * C<DECAPSULATE>

=item * C<OTHER>

=item * C<UNKNOWN>

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
