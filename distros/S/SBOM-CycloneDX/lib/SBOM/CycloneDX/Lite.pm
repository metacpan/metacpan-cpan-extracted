package SBOM::CycloneDX::Lite;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter ();

require SBOM::CycloneDX;
require SBOM::CycloneDX::Component;
require SBOM::CycloneDX::ExternalReference;
require SBOM::CycloneDX::Hash;
require SBOM::CycloneDX::License;
require SBOM::CycloneDX::OrganizationalContact;
require SBOM::CycloneDX::OrganizationalEntity;
require SBOM::CycloneDX::Property;


our @EXPORT_OK = qw(
    bom
    component
    contact
    external_reference
    hash
    license
    organization
    property

    application_component
    container_component
    cryptographic_asset_component
    data_component
    device_component
    device_driver_component
    file_component
    firmware_component
    framework_component
    library_component
    machine_learning_model_component
    operating_system_component
    platform_component
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $LATEST_SPEC_VERSION = (
    sort {
        my ($am, $an) = split /\./, $a, 2;
        my ($bm, $bn) = split /\./, $b, 2;
        $am <=> $bm || $an <=> $bn
    } keys %SBOM::CycloneDX::JSON_SCHEMA
)[-1];

our $DEFAULT_SPEC_VERSION = $LATEST_SPEC_VERSION;

sub import {

    my $class = shift;

    foreach (@_) {
        if ($_ =~ /^\:v(1_\d)$/) {
            $DEFAULT_SPEC_VERSION = $1;
            $DEFAULT_SPEC_VERSION =~ tr/_/./;
        }
        if ($_ eq ':latest') {
            $DEFAULT_SPEC_VERSION = $LATEST_SPEC_VERSION;
        }
    }

    local $Exporter::ExportLevel = 1;
    Exporter::import($class, grep { $_ !~ /^:v1_/ && $_ ne ':latest' } @_);

}

sub bom                { SBOM::CycloneDX->new(spec_version => $DEFAULT_SPEC_VERSION, @_) }
sub component          { SBOM::CycloneDX::Component->new(@_) }
sub contact            { SBOM::CycloneDX::OrganizationalContact->new(@_) }
sub external_reference { SBOM::CycloneDX::ExternalReference->new(@_) }
sub hash               { SBOM::CycloneDX::Hash->new(@_) }
sub license            { SBOM::CycloneDX::License->new(@_) }
sub organization       { SBOM::CycloneDX::OrganizationalEntity->new(@_) }
sub property           { SBOM::CycloneDX::Property->new(@_) }

sub application_component            { component(type => 'application',            @_) }
sub container_component              { component(type => 'container',              @_) }
sub cryptographic_asset_component    { component(type => 'cryptographic-asset',    @_) }
sub data_component                   { component(type => 'data',                   @_) }
sub device_component                 { component(type => 'device',                 @_) }
sub device_driver_component          { component(type => 'device-driver',          @_) }
sub file_component                   { component(type => 'file',                   @_) }
sub firmware_component               { component(type => 'firmware',               @_) }
sub framework_component              { component(type => 'framework',              @_) }
sub library_component                { component(type => 'library',                @_) }
sub machine_learning_model_component { component(type => 'machine-learning-model', @_) }
sub operating_system_component       { component(type => 'operating-system',       @_) }
sub platform_component               { component(type => 'platform',               @_) }

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Lite - Simple accessors and helpers for SBOM::CycloneDX

=head1 SYNOPSIS

    use SBOM::CycloneDX::Lite qw(:v1_7 :all);

    my $bom = bom;

    my $root_component = application_component(
        name     => 'MyApp',
        licenses => [license('Artistic-2.0')],
        bom_ref  => 'MyApp'
    );

    my $metadata = $bom->metadata;

    $metadata->tools->add(cyclonedx_tool);

    $metadata->component($root_component);

    my $component1 = library_component(
        name     => 'some-component',
        group    => 'acme',
        version  => '1.33.7-beta.1',
        licenses => [license(name => '(c) 2021 Acme inc.')],
        bom_ref  => 'myComponent@1.33.7-beta.1',
        purl     => URI::PackageURL->new(
            type      => 'generic',
            namespace => 'acme',
            name      => 'some-component',
            version   => '1.33.7-beta.1'
        ),
    );

    $bom->components->add($component1);
    $bom->add_dependency($root_component, [$component1]);

    my $component2 = library_component(
        name     => 'some-library',
        licenses => [license('GPL-3.0-only WITH Classpath-exception-2.0')],
        bom_ref  => 'some-lib',
    );

    $bom->components->add($component2);
    $bom->add_dependency($root_component, [$component2]);

    my @errors = $bom->validate;

    if (@errors) {
        say $_ for (@errors);
        Carp::croak 'Validation error';
    }

    say $bom->to_string;



=head1 DESCRIPTION

L<SBOM::CycloneDX::Lite> is an EXPERIMENTAL lightweight layer built on top of 
L<SBOM::CycloneDX> to quickly create CycloneDX BOM files.

It focuses on the most commonly used BOM fields and provides a simple, 
low-boilerplate interface. It accepts friendly input and normalizes it into 
canonical CycloneDX structures.

=head2 EXPORTED TAGS

=over

=item C<:latest>

Select the latest CycloneDX schema version supported by L<SBOM::CycloneDX>
distribution.

=item C<:v1_7>

Select the CycloneDX v1.7 schema version.

=item C<:v1_6>

Select the CycloneDX v1.6 schema version.

=item C<:v1_5>

Select the CycloneDX v1.5 schema version.

=item C<:v1_4>

Select the CycloneDX v1.4 schema version.

=item C<:v1_3>

Select the CycloneDX v1.3 schema version.

=item C<:v1_2>

Select the CycloneDX v1.2 schema version.

=item C<:all>

Export all functions.

=back

=head2 EXPORTED FUNCTIONS

=head3 B<bom>

Return a L<SBOM::CycloneDX> object.

=head3 B<component>

Return a L<SBOM::CycloneDX::Component> object.

Component aliases:

=over

=item B<application_component>

=item B<framework_component>

=item B<library_component>

=item B<container_component>

=item B<platform_component>

=item B<operating_system_component>

=item B<device_component>

=item B<device_driver_component>

=item B<firmware_component>

=item B<file_component>

=item B<machine_learning_model_component>

=item B<data_component>

=item B<cryptographic_asset_component>

=back

=head3 B<license>

Return a L<SBOM::CycloneDX::License> object.

=head3 B<external_reference>

Return a L<SBOM::CycloneDX::ExternalReference> object.

=head3 B<property>

Return a L<SBOM::CycloneDX::Property> object.

=head3 B<organization>

Return a L<SBOM::CycloneDX::OrganizationalEntity> object.

=head3 B<contact>

Return a L<SBOM::CycloneDX::OrganizationalContact> object.

=head3 B<hash>

Return a L<SBOM::CycloneDX::Hash> object.


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
