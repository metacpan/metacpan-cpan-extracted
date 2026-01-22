package SBOM::CycloneDX::Enum::ImpactAnalysisState;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        RESOLVED               => 'resolved',
        RESOLVED_WITH_PEDIGREE => 'resolved_with_pedigree',
        EXPLOITABLE            => 'exploitable',
        IN_TRIAGE              => 'in_triage',
        FALSE_POSITIVE         => 'false_positive',
        NOT_AFFECTED           => 'not_affected',
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

SBOM::CycloneDX::Enum::ImpactAnalysisState - Impact Analysis State

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(IMPACT_ANALYSIS_STATE);
    say IMPACT_ANALYSIS_STATE->RESOLVED_WITH_PEDIGREE;

    use SBOM::CycloneDX::Enum::TlpCImpactAnalysisStatelassification qw(:all);
    say EXPLOITABLE;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::ImpactAnalysisState> is ENUM package used by L<SBOM::CycloneDX::Vulnerability::Analysis>.

Declares the current state of an occurrence of a vulnerability, after
automated or manual analysis.

=head1 CONSTANTS

=over

=item * C<RESOLVED>, The vulnerability has been remediated.

=item * C<RESOLVED_WITH_PEDIGREE>, The vulnerability has been remediated
and evidence of the changes are provided in the affected components
pedigree containing verifiable commit history and/or diff(s).

=item * C<EXPLOITABLE>, The vulnerability may be directly or indirectly
exploitable.

=item * C<IN_TRIAGE>, The vulnerability is being investigated.

=item * C<FALSE_POSITIVE>, The vulnerability is not specific to the
component or service and was falsely identified or associated.

=item * C<NOT_AFFECTED>, The component or service is not affected by the
vulnerability. Justification should be specified for all not_affected
cases.

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
