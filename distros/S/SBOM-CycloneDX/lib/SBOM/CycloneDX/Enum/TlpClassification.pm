package SBOM::CycloneDX::Enum::TlpClassification;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (

        # Traffic Light Protocol (TLP) v2.0
        CLEAR            => 'CLEAR',
        GREEN            => 'GREEN',
        AMBER            => 'AMBER',
        AMBER_AND_STRICT => 'AMBER_AND_STRICT',
        RED              => 'RED',
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

SBOM::CycloneDX::Enum::TlpClassification - Traffic Light Protocol (TLP) Classification

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(TLP_CLASSIFICATION);
    say TLP_CLASSIFICATION->GREEN;

    use SBOM::CycloneDX::Enum::TlpClassification qw(:all);
    say AMBER_AND_STRICT;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::TlpClassification> is ENUM package used by L<SBOM::CycloneDX>.

Traffic Light Protocol (TLP) is a classification system for identifying the
potential risk associated with artefact, including whether it is subject to
certain types of legal, financial, or technical threats. Refer to L<https://www.first.org/tlp/>
for further information.

The default classification is C<CLEAR>.

=head1 CONSTANTS

=over

=item * C<CLEAR>, The information is not subject to any restrictions as regards
the sharing.

=item * C<GREEN>, The information is subject to limited disclosure, and recipients
can share it within their community but not via publicly accessible channels.

=item * C<AMBER>, The information is subject to limited disclosure, and recipients
can only share it on a need-to-know basis within their organization and with clients.

=item * C<AMBER_AND_STRICT>, The information is subject to limited disclosure,
and recipients can only share it on a need-to-know basis within their organization.

=item * C<RED>, The information is subject to restricted distribution to individual
recipients only and must not be shared.

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
