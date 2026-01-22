package SBOM::CycloneDX::Enum::PatentAssertionType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        OWNERSHIP              => 'ownership',
        LICENSE                => 'license',
        THIRD_PARTY_CLAIM      => 'third-party-claim',
        STANDARDS_INCLUSION    => 'standards-inclusion',
        PRIOR_ART              => 'prior-art',
        EXCLUSIVE_RIGHTS       => 'exclusive-rights',
        NON_ASSERTION          => 'non-assertion',
        RESEARCH_OR_EVALUATION => 'research-or-evaluation'
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

SBOM::CycloneDX::Enum::PatentAssertionType - Assertion Type

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(PATENT_ASSERTION_TYPE);

    say PATENT_ASSERTION_TYPE->THIRD_PARTY_CLAIM;


    use SBOM::CycloneDX::Enum::PatentAssertionType;

    say SBOM::CycloneDX::Enum::PatentAssertionType->EXCLUSIVE_RIGHTS;


    use SBOM::CycloneDX::Enum::PatentAssertionType qw(:all);

    say RESEARCH_OR_EVALUATION;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::PatentAssertionType> is ENUM package used by L<SBOM::CycloneDX::PatentAssertion>.

The type of assertion being made about the patent or patent family.
Examples include ownership, licensing, and standards inclusion.


=head1 CONSTANTS

=over

=item * C<OWNERSHIP>, The manufacturer asserts ownership of the patent or
patent family.

=item * C<LICENSE>, The manufacturer asserts they have a license to use the
patent or patent family.

=item * C<THIRD_PARTY_CLAIM>, A third party has asserted a claim or
potential infringement against the manufacturer’s component or service.

=item * C<STANDARDS_INCLUSION>, The patent is part of a standard essential
patent (SEP) portfolio relevant to the component or service.

=item * C<PRIOR_ART>, The manufacturer asserts the patent or patent family
as prior art that invalidates another patent or claim.

=item * C<EXCLUSIVE_RIGHTS>, The manufacturer asserts exclusive rights
granted through a licensing agreement.

=item * C<NON_ASSERTION>, The manufacturer asserts they will not enforce
the patent or patent family against certain uses or users.

=item * C<RESEARCH_OR_EVALUATION>, The patent or patent family is being
used under a research or evaluation license.

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
