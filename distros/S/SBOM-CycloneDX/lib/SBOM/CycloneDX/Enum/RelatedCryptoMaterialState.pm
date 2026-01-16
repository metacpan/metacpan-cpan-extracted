package SBOM::CycloneDX::Enum::RelatedCryptoMaterialState;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        PRE_ACTIVATION => 'pre-activation',
        ACTIVE         => 'active',
        SUSPENDED      => 'suspended',
        DEACTIVATED    => 'deactivated',
        COMPROMISED    => 'compromised',
        DESTROYED      => 'destroyed',
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

SBOM::CycloneDX::Enum::RelatedCryptoMaterialState - The key state as defined by NIST SP 800-57

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(RELATED_CRYPTO_MATERIAL_STATE);

    say RELATED_CRYPTO_MATERIAL_STATE->PRE_ACTIVATION;


    use SBOM::CycloneDX::Enum::RelatedCryptoMaterialState;

    say SBOM::CycloneDX::Enum::RelatedCryptoMaterialState->SUSPENDED;


    use SBOM::CycloneDX::Enum::RelatedCryptoMaterialState qw(:all);

    say COMPROMISED;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::RelatedCryptoMaterialState> is ENUM package used by L<SBOM::CycloneDX>.


=head1 CONSTANTS

=over

=item * C<PRE_ACTIVATION>

=item * C<ACTIVE>

=item * C<SUSPENDED>

=item * C<DEACTIVATED>

=item * C<COMPROMISED>

=item * C<DESTROYED>

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
