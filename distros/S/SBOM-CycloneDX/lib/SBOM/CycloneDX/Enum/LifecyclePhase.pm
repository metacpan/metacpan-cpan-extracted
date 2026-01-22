package SBOM::CycloneDX::Enum::LifecyclePhase;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        DESIGN       => 'design',
        PRE_BUILD    => 'pre-build',
        BUILD        => 'build',
        POST_BUILD   => 'post-build',
        OPERATIONS   => 'operations',
        DISCOVERY    => 'discovery',
        DECOMMISSION => 'decommission',
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

SBOM::CycloneDX::Enum::LifecyclePhase - Lifecycle Phase

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(LIFECYCLE_PHASE);

    say LIFECYCLE_PHASE->DESIGN;


    use SBOM::CycloneDX::Enum::LifecyclePhase;

    say SBOM::CycloneDX::Enum::LifecyclePhase->BUILD;


    use SBOM::CycloneDX::Enum::LifecyclePhase qw(:all);

    say DECOMMISSION;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::LifecyclePhase> is ENUM package used by L<SBOM::CycloneDX::Metadata::Lifecycle>.

A pre-defined phase in the product lifecycle.


=head1 CONSTANTS

=over

=item * C<DESIGN>, BOM produced early in the development lifecycle
containing an inventory of components and services that are proposed or
planned to be used. The inventory may need to be procured, retrieved, or
resourced prior to use.

=item * C<PRE_BUILD>, BOM consisting of information obtained prior to a
build process and may contain source files and development artifacts and
manifests. The inventory may need to be resolved and retrieved prior to
use.

=item * C<BUILD>, BOM consisting of information obtained during a build
process where component inventory is available for use. The precise
versions of resolved components are usually available at this time as well
as the provenance of where the components were retrieved from.

=item * C<POST_BUILD>, BOM consisting of information obtained after a build
process has completed and the resulting components(s) are available for
further analysis. Built components may exist as the result of a CI/CD
process, may have been installed or deployed to a system or device, and may
need to be retrieved or extracted from the system or device.

=item * C<OPERATIONS>, BOM produced that represents inventory that is
running and operational. This may include staging or production
environments and will generally encompass multiple SBOMs describing the
applications and operating system, along with HBOMs describing the hardware
that makes up the system. Operations Bill of Materials (OBOM) can provide
full-stack inventory of runtime environments, configurations, and
additional dependencies.

=item * C<DISCOVERY>, BOM consisting of information observed through
network discovery providing point-in-time enumeration of embedded,
on-premise, and cloud-native services such as server applications,
connected devices, microservices, and serverless functions.

=item * C<DECOMMISSION>, BOM containing inventory that will be, or has been
retired from operations.

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
