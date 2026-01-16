package SBOM::CycloneDX::Service;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str Bool InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has provider         => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has group            => (is => 'rw', isa => Str);
has name             => (is => 'rw', isa => Str, required => 1);
has version          => (is => 'rw', isa => Str);
has description      => (is => 'rw', isa => Str);
has endpoints        => (is => 'rw', isa => Str);
has authenticated    => (is => 'rw', isa => Bool);
has x_trust_boundary => (is => 'rw', isa => Bool);
has trust_zone       => (is => 'rw', isa => Str);
has data             => (is => 'rw', isa => ArrayLike [Str]);

has licenses => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::License']],
    default => sub { SBOM::CycloneDX::List->new }
);

has patent_assertions => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::PatentAssertions']],
    default => sub { SBOM::CycloneDX::List->new }
);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

has services => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Service']],
    default => sub { SBOM::CycloneDX::List->new }
);

has release_notes => (is => 'rw', isa => Str);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

has tags      => (is => 'rw', isa => ArrayLike [Str]);
has signature => (is => 'rw', isa => ArrayLike [HashRef]);


sub TO_JSON {

    my $self = shift;

    my $json = {name => $self->name};

    $json->{'bom-ref'}          = $self->bom_ref             if $self->bom_ref;
    $json->{provider}           = $self->provider            if $self->provider;
    $json->{group}              = $self->group               if $self->group;
    $json->{version}            = $self->version             if $self->version;
    $json->{description}        = $self->description         if $self->description;
    $json->{endpoints}          = $self->endpoints           if @{$self->endpoints};
    $json->{authenticated}      = $self->authenticated       if $self->authenticated;
    $json->{'x-trust-boundary'} = $self->x_trust_boundary    if $self->x_trust_boundary;
    $json->{trustZone}          = $self->trust_zone          if $self->trust_zone;
    $json->{data}               = $self->data                if @{$self->data};
    $json->{patentAssertions}   = $self->patent_assertions   if @{$self->patent_assertions};
    $json->{licenses}           = $self->licenses            if @{$self->licenses};
    $json->{externalReferences} = $self->external_references if @{$self->external_references};
    $json->{services}           = $self->services            if @{$self->services};
    $json->{releaseNotes}       = $self->release_notes       if $self->release_notes;
    $json->{properties}         = $self->properties          if @{$self->properties};
    $json->{tags}               = $self->tags                if @{$self->tags};
    $json->{signature}          = $self->signature           if @{$self->signature};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Service - Service

=head1 SYNOPSIS

    SBOM::CycloneDX::Service->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Service> provides a list of services included or deployed
behind the parent service. This is not a dependency tree. It provides a way to
specify a hierarchical representation of service assemblies.

=head2 METHODS

L<SBOM::CycloneDX::Service> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Service->new( %PARAMS )

Properties:

=over

=item C<authenticated>, A boolean value indicating if the service requires
authentication. A value of true indicates the service requires
authentication prior to use. A value of false indicates the service does
not require authentication.

=item C<bom_ref>, An identifier which can be used to reference the
service elsewhere in the BOM. Every bom-ref must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<data>, Specifies information about the data including the
directional flow of data and the data classification.

=item C<description>, Specifies a description for the service

=item C<endpoints>, The endpoint URIs of the service. Multiple endpoints
are allowed.

=item C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item C<group>, The grouping name, namespace, or identifier. This will
often be a shortened, single name of the company or project that produced
the service or domain name. Whitespace and special characters should be
avoided.

=item C<licenses>, Service License(s).

=item C<name>, The name of the service. This will often be a shortened,
single name of the service.

=item C<patent_assertions>, Service Patent(s).

Patent Assertions. A list of assertions made regarding patents associated
with this component or service. Assertions distinguish between ownership,
licensing, and other relevant interactions with patents.

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the CycloneDX
Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).
Formal registration is optional.

=item C<provider>, The organization that provides the service.

=item C<release_notes>, Specifies release notes.

=item C<services>, A list of services included or deployed behind the
parent service. This is not a dependency tree. It provides a way to specify
a hierarchical representation of service assemblies.

=item C<signature>, Enveloped signature in JSON Signature Format
(JSF) (L<https://cyberphone.github.io/doc/security/jsf.html>).

=item C<tags>, 

=item C<trust_zone>, The name of the trust zone the service resides in.

=item C<version>, The service version.

=item C<x_trust_boundary>, A boolean value indicating if use of the service
crosses a trust zone or boundary. A value of true indicates that by using
the service, a trust boundary is crossed. A value of false indicates that by
using the service, a trust boundary is not crossed.

=back

=item $service->authenticated

=item $service->bom_ref

=item $service->data

=item $service->description

=item $service->endpoints

=item $service->external_references

=item $service->group

=item $service->licenses

=item $service->name

=item $service->patent_assertions

=item $service->properties

=item $service->provider

=item $service->release_notes

=item $service->services

=item $service->signature

=item $service->tags

=item $service->trust_zone

=item $service->version

=item $service->x_trust_boundary

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
