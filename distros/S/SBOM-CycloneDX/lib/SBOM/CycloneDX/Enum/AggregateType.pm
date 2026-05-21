package SBOM::CycloneDX::Enum::AggregateType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        COMPLETE                                => "complete",
        INCOMPLETE                              => "incomplete",
        INCOMPLETE_FIRST_PARTY_ONLY             => "incomplete_first_party_only",
        INCOMPLETE_FIRST_PARTY_PROPRIETARY_ONLY => "incomplete_first_party_proprietary_only",
        INCOMPLETE_FIRST_PARTY_OPENSOURCE_ONLY  => "incomplete_first_party_opensource_only",
        INCOMPLETE_THIRD_PARTY_ONLY             => "incomplete_third_party_only",
        INCOMPLETE_THIRD_PARTY_PROPRIETARY_ONLY => "incomplete_third_party_proprietary_only",
        INCOMPLETE_THIRD_PARTY_OPENSOURCE_ONLY  => "incomplete_third_party_opensource_only",
        UNKNOWN                                 => "unknown",
        NOT_SPECIFIED                           => "not_specified"
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

SBOM::CycloneDX::Enum::AggregateType - Specifies an aggregate type that describes
how complete a relationship is

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(AGGREGATE_TYPE);

    say AGGREGATE_TYPE->NOT_SPECIFIED;


    use SBOM::CycloneDX::Enum::AggregateType;

    say SBOM::CycloneDX::Enum::AggregateType->COMPLETE;


    use SBOM::CycloneDX::Enum::AggregateType qw(:all);

    say INCOMPLETE;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::AggregateType> is ENUM package used by L<SBOM::CycloneDX::Composition>.


=head1 CONSTANTS

=over

=item * C<COMPLETE>, The relationship is complete. No further relationships
including constituent components, services, or dependencies are known to
exist.

=item * C<INCOMPLETE>, The relationship is incomplete. Additional
relationships exist and may include constituent components, services, or
dependencies.

=item * C<INCOMPLETE_FIRST_PARTY_ONLY>, The relationship is incomplete.
Only relationships for first-party components, services, or their
dependencies are represented.

=item * C<INCOMPLETE_FIRST_PARTY_PROPRIETARY_ONLY>, The relationship is
incomplete. Only relationships for first-party components, services, or
their dependencies are represented, limited specifically to those that are
proprietary.

=item * C<INCOMPLETE_FIRST_PARTY_OPENSOURCE_ONLY>, The relationship is
incomplete. Only relationships for first-party components, services, or
their dependencies are represented, limited specifically to those that are
opensource.

=item * C<INCOMPLETE_THIRD_PARTY_ONLY>, The relationship is incomplete.
Only relationships for third-party components, services, or their
dependencies are represented.

=item * C<INCOMPLETE_THIRD_PARTY_PROPRIETARY_ONLY>, The relationship is
incomplete. Only relationships for third-party components, services, or
their dependencies are represented, limited specifically to those that are
proprietary.

=item * C<INCOMPLETE_THIRD_PARTY_OPENSOURCE_ONLY>, The relationship is
incomplete. Only relationships for third-party components, services, or
their dependencies are represented, limited specifically to those that are
opensource.

=item * C<UNKNOWN>, The relationship may be complete or incomplete. This
usually signifies a 'best-effort' to obtain constituent components,
services, or dependencies but the completeness is inconclusive.

=item * C<NOT_SPECIFIED>, The relationship completeness is not specified.

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
