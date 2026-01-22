package SBOM::CycloneDX::Enum::ImpactAnalysisJustification;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        CODE_NOT_PRESENT                => 'code_not_present',
        CODE_NOT_REACHABLE              => 'code_not_reachable',
        REQUIRES_CONFIGURATION          => 'requires_configuration',
        REQUIRES_DEPENDENCY             => 'requires_dependency',
        REQUIRES_ENVIRONMENT            => 'requires_environment',
        PROTECTED_BY_COMPILER           => 'protected_by_compiler',
        PROTECTED_AT_RUNTIME            => 'protected_at_runtime',
        PROTECTED_AT_PERIMETER          => 'protected_at_perimeter',
        PROTECTED_BY_MITIGATING_CONTROL => 'protected_by_mitigating_control',
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

SBOM::CycloneDX::Enum::ImpactAnalysisJustification - Impact Analysis Justification

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(IMPACT_ANALYSIS_JUSTIFICATION);
    say IMPACT_ANALYSIS_STATE->REQUIRES_DEPENDENCY;

    use SBOM::CycloneDX::Enum::ImpactAnalysisJustification qw(:all);
    say PROTECTED_AT_RUNTIME;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::ImpactAnalysisJustification> is ENUM package used by L<SBOM::CycloneDX::Vulnerability::Analysis>.

The rationale of why the impact analysis state was asserted

=head1 CONSTANTS

=over

=item * C<CODE_NOT_PRESENT>, The code has been removed or tree-shaked.

=item * C<CODE_NOT_REACHABLE>, The vulnerable code is not invoked at
runtime.

=item * C<REQUIRES_CONFIGURATION>, Exploitability requires a configurable
option to be set/unset.

=item * C<REQUIRES_DEPENDENCY>, Exploitability requires a dependency that
is not present.

=item * C<REQUIRES_ENVIRONMENT>, Exploitability requires a certain
environment which is not present.

=item * C<PROTECTED_BY_COMPILER>, Exploitability requires a compiler flag
to be set/unset.

=item * C<PROTECTED_AT_RUNTIME>, Exploits are prevented at runtime.

=item * C<PROTECTED_AT_PERIMETER>, Attacks are blocked at physical,
logical, or network perimeter.

=item * C<PROTECTED_BY_MITIGATING_CONTROL>, Preventative measures have been
implemented that reduce the likelihood and/or impact of the vulnerability.

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
