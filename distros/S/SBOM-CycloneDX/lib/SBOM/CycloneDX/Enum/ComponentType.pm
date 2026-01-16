package SBOM::CycloneDX::Enum::ComponentType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        APPLICATION            => 'application',
        FRAMEWORK              => 'framework',
        LIBRARY                => 'library',
        CONTAINER              => 'container',
        PLATFORM               => 'platform',
        OPERATING_SYSTEM       => 'operating-system',
        DEVICE                 => 'device',
        DEVICE_DRIVER          => 'device-driver',
        FIRMWARE               => 'firmware',
        FILE                   => 'file',
        MACHINE_LEARNING_MODEL => 'machine-learning-model',
        DATA                   => 'data',
        CRYPTOGRAPHIC_ASSET    => 'cryptographic-asset',
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

SBOM::CycloneDX::Enum::ComponentType - Component Type

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(COMPONENT_TYPE);

    say COMPONENT_TYPE->APPLICATION;


    use SBOM::CycloneDX::Enum::ComponentType;

    say SBOM::CycloneDX::Enum::ComponentType->LIBRARY;


    use SBOM::CycloneDX::Enum::ComponentType qw(:all);

    say OPERATING_SYSTEM;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::ComponentType> is ENUM package used by L<SBOM::CycloneDX::Component>.

Specifies the type of component. For software components, classify as application
if no more specific appropriate classification is available or cannot be determined
for the component.


=head1 CONSTANTS

=over

=item * C<APPLICATION>, A software application. Refer to L<https://en.wikipedia.org/wiki/Application_software>
for information about applications.

=item * C<FRAMEWORK>, A software framework. Refer to L<https://en.wikipedia.org/wiki/Software_framework>
for information on how frameworks vary slightly from libraries.

=item * C<LIBRARY>, A software library. Refer to L<https://en.wikipedia.org/wiki/Library_(computing)>
for information about libraries. All third-party and open source reusable
components will likely be a library. If the library also has key features of a
framework, then it should be classified as a framework. If not, or is unknown,
then specifying library is recommended.",

=item * C<CONTAINER>, A packaging and/or runtime format, not specific to any
particular technology, which isolates software inside the container from software
outside of a container through virtualization technology. Refer to L<https://en.wikipedia.org/wiki/OS-level_virtualization>.

=item * C<PLATFORM>, A runtime environment that interprets or executes software.
This may include runtimes such as those that execute bytecode, just-in-time
compilers, interpreters, or low-code/no-code application platforms.

=item * C<OPERATING_SYSTEM>, A software operating system without regard to
deployment model (i.e. installed on physical hardware, virtual machine, image,
etc). Refer to L<https://en.wikipedia.org/wiki/Operating_system>.

=item * C<DEVICE>, A hardware device such as a processor or chip-set. A hardware
device containing firmware SHOULD include a component for the physical hardware
itself and another component of type 'firmware' or 'operating-system' (whichever
is relevant), describing information about the software running on the device.
See also the list of L<known device properties|https://github.com/CycloneDX/cyclonedx-property-taxonomy/blob/main/cdx/device.md>.

=item * C<DEVICE_DRIVER>, A special type of software that operates or controls a
particular type of device. Refer to L<https://en.wikipedia.org/wiki/Device_driver>.

=item * C<FIRMWARE>, A special type of software that provides low-level control
over a device's hardware. Refer to L<https://en.wikipedia.org/wiki/Firmware>.

=item * C<FILE>, A computer file. Refer to L<https://en.wikipedia.org/wiki/Computer_file>
for information about files.

=item * C<MACHINE_LEARNING_MODEL>, A model based on training data that can make
predictions or decisions without being explicitly programmed to do so.

=item * C<DATA>, A collection of discrete values that convey information.

=item * C<CRYPTOGRAPHIC_ASSET>, A cryptographic asset including algorithms,
protocols, certificates, keys, tokens, and secrets.

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
