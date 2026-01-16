package SBOM::CycloneDX::Enum::LicenseType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        ACADEMIC         => 'academic',
        APPLIANCE        => 'appliance',
        CLIENT_ACCESS    => 'client-access',
        CONCURRENT_USER  => 'concurrent-user',
        CORE_POINTS      => 'core-points',
        CUSTOM_METRIC    => 'custom-metric',
        DEVICE           => 'device',
        EVALUATION       => 'evaluation',
        NAMED_USER       => 'named-user',
        NODE_LOCKED      => 'node-locked',
        OEM              => 'oem',
        PERPETUAL        => 'perpetual',
        PROCESSOR_POINTS => 'processor-points',
        SUBSCRIPTION     => 'subscription',
        USER             => 'user',
        OTHER            => 'other',
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

SBOM::CycloneDX::Enum::LicenseType - License Type

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(LICENSE_TYPE);

    say LICENSE_TYPE->APPLIANCE;


    use SBOM::CycloneDX::Enum::LicenseType;

    say SBOM::CycloneDX::Enum::LicenseType->CAL;


    use SBOM::CycloneDX::Enum::LicenseType qw(:all);

    say PERPETUAL;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::LicenseType> is ENUM package used by L<SBOM::CycloneDX>.


=head1 CONSTANTS

=over

=item * L<ACADEMIC>, A license that grants use of software solely for the
purpose of education or research.

=item * L<APPLIANCE>, A license covering use of software embedded in a
specific piece of hardware.

=item * L<CLIENT_ACCESS>, A Client Access License (CAL) allows client
computers to access services provided by server software.

=item * L<CONCURRENT_USER>, A Concurrent User license (aka floating
license) limits the number of licenses for a software application and
licenses are shared among a larger number of users.

=item * L<CORE_POINTS>, A license where the core of a computer's processor
is assigned a specific number of points.

=item * L<CUSTOM_METRIC>, A license for which consumption is measured by
non-standard metrics.

=item * L<DEVICE>, A license that covers a defined number of installations
on computers and other types of devices.

=item * L<EVALUATION>, A license that grants permission to install and use
software for trial purposes.

=item * L<NAMED_USER>, A license that grants access to the software to one
or more pre-defined users.

=item * L<NODE_LOCKED>, A license that grants access to the software on one
or more pre-defined computers or devices.

=item * L<OEM>, An Original Equipment Manufacturer license that is
delivered with hardware, cannot be transferred to other hardware, and is
valid for the life of the hardware.

=item * L<PERPETUAL>, A license where the software is sold on a one-time
basis and the licensee can use a copy of the software indefinitely.

=item * L<PROCESSOR_POINTS>, A license where each installation consumes
points per processor.

=item * L<SUBSCRIPTION>, A license where the licensee pays a fee to use the
software or service.

=item * L<USER>, A license that grants access to the software or service by
a specified number of users.

=item * L<OTHER>, Another license type.

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
