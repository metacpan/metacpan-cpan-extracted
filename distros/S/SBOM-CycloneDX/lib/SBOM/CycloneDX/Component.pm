package SBOM::CycloneDX::Component;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Enum;

use Types::Standard qw(Str StrMatch Bool Enum InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);
use URI::PackageURL;

use Moo;
use namespace::autoclean;

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    return {type => $args[0]} if @args == 1 && !ref $args[0];
    return $class->$orig(@args);
};

extends 'SBOM::CycloneDX::Base';

has type => (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->COMPONENT_TYPES()], required => 1);
has mime_type => (is => 'rw', isa => StrMatch [qr{^[-+a-z0-9.]+/[-+a-z0-9.]+$}]);

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has supplier     => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has manufacturer => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);

has authors => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::OrganizationalContact']],
    default => sub { SBOM::CycloneDX::List->new }
);

has author      => (is => 'rw', isa => Str);                                      # Deprecated in 1.6
has publisher   => (is => 'rw', isa => Str);
has group       => (is => 'rw', isa => Str);
has name        => (is => 'rw', isa => Str, required => 1);
has version     => (is => 'rw', isa => Str);                                      # Required in 1.2 and 1.3
has description => (is => 'rw', isa => Str);
has scope       => (is => 'rw', isa => Enum [qw(required optional excluded)]);    # Default required

has hashes => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Hash']],
    default => sub { SBOM::CycloneDX::List->new }
);

has licenses => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::License']],
    default => sub { SBOM::CycloneDX::List->new }
);

has copyright  => (is => 'rw', isa => Str);
has cpe        => (is => 'rw', isa => Str);
has purl       => (is => 'rw', isa => InstanceOf ['URI::PackageURL'], coerce => sub { _purl_parse($_[0]) });
has omnibor_id => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has swhid      => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });
has swid       => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::SWID']);
has modified   => (is => 'rw', isa => Bool);                                                  # Deprecated in 1.4
has pedigree   => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::Pedigree']);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

has components => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has evidence          => (is => 'rw', isa => Str);                                                               # TODO
has release_notes     => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::ReleaseNotes']);
has model_card        => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component::ModelCard']);
has data              => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });    # TODO
has crypto_properties => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::CryptoProperties']);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

has tags => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has signature => (is => 'rw', isa => HashRef);                                                                   # TODO


sub _purl_parse {

    my $purl = shift;

    return $purl if (ref $purl eq 'URI::PackageURL');
    return URI::PackageURL->from_string($purl);

}

sub TO_JSON {

    my $self = shift;

    my $json = {type => $self->type, name => $self->name};


    $json->{'mime-type'}        = $self->mime_type           if $self->mime_type;
    $json->{'bom-ref'}          = $self->bom_ref             if $self->bom_ref;
    $json->{supplier}           = $self->supplier            if $self->supplier;
    $json->{manufacturer}       = $self->manufacturer        if $self->manufacturer;
    $json->{authors}            = $self->authors             if @{$self->authors};
    $json->{author}             = $self->author              if $self->author;
    $json->{publisher}          = $self->publisher           if $self->publisher;
    $json->{group}              = $self->group               if $self->group;
    $json->{version}            = $self->version             if $self->version;
    $json->{description}        = $self->description         if $self->description;
    $json->{scope}              = $self->scope               if $self->scope;
    $json->{hashes}             = $self->hashes              if @{$self->hashes};
    $json->{licenses}           = $self->licenses            if @{$self->licenses};
    $json->{copyright}          = $self->copyright           if $self->copyright;
    $json->{cpe}                = $self->cpe                 if $self->cpe;
    $json->{purl}               = $self->purl->to_string     if $self->purl;
    $json->{omniborId}          = $self->omnibor_id          if @{$self->omnibor_id};
    $json->{swhid}              = $self->swhid               if @{$self->swhid};
    $json->{swid}               = $self->swid                if $self->swid;
    $json->{modified}           = $self->modified            if $self->modified;
    $json->{pedigree}           = $self->pedigree            if $self->pedigree;
    $json->{externalReferences} = $self->external_references if @{$self->external_references};
    $json->{components}         = $self->components          if @{$self->components};
    $json->{evidence}           = $self->evidence            if $self->evidence;
    $json->{releaseNotes}       = $self->release_notes       if $self->release_notes;
    $json->{modelCard}          = $self->model_card          if $self->model_card;
    $json->{data}               = $self->data                if @{$self->data};
    $json->{cryptoProperties}   = $self->crypto_properties   if $self->crypto_properties;
    $json->{properties}         = $self->properties          if @{$self->properties};
    $json->{tags}               = $self->tags                if @{$self->tags};
    $json->{signature}          = $self->signature           if $self->signature;

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Component - Component

=head1 SYNOPSIS

    SBOM::CycloneDX::Component->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Component> 

=head2 METHODS

L<SBOM::CycloneDX::Component> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Component->new( %PARAMS )

Properties:

=over

=item C<author>, [Deprecated] This will be removed in a future version. Use
"authors" or "manufacturer" methods instead.
The person(s) or organization(s) that authored the component

=item C<authors>, The person(s) who created the component.
Authors are common in components created through manual processes.
Components created through automated means may have "manufacturer" method
instead.

=item C<bom_ref>, An optional identifier which can be used to reference the
component elsewhere in the BOM. Every bom-ref must be unique within the
BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<components>, A list of software and hardware components included in
the parent component. This is not a dependency tree. It provides a way to
specify a hierarchical representation of component assemblies, similar to
system → subsystem → parts assembly in physical supply chains.

=item C<copyright>, A copyright notice informing users of the underlying
claims to copyright ownership in a published work.

=item C<cpe>, Asserts the identity of the component using CPE. The CPE must
conform to the CPE 2.2 or 2.3 specification. See L<https://nvd.nist.gov/products/cpe>.
Refer to "evidence->identity" method to optionally provide evidence that
substantiates the assertion of the component's identity.

=item C<crypto_properties>, Cryptographic Properties

=item C<data>, This object SHOULD be specified for any component of type
`data` and must not be specified for other component types.

=item C<description>, Specifies a description for the component

=item C<evidence>, Provides the ability to document evidence collected
through various forms of extraction or analysis.

=item C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item C<group>, The grouping name or identifier. This will often be a
shortened, single name of the company or project that produced the
component, or the source package or domain name. Whitespace and special
characters should be avoided. Examples include: apache, org.apache.commons,
and apache.org.

=item C<hashes>, The hashes of the component.

=item C<licenses>, Component License(s)

=item C<manufacturer>, The organization that created the component.
Manufacturer is common in components created through automated processes.
Components created through manual means may have `@.authors` instead.

=item C<mime_type>, The optional mime-type of the component. When used on
file components, the mime-type can provide additional context about the kind
of file being represented, such as an image, font, or executable. Some library
or framework components may also have an associated mime-type.

=item C<model_card>, AI/ML Model Card

=item C<modified>, [Deprecated] This will be removed in a future version.
Use the pedigree element instead to supply information on exactly how the
component was modified. A boolean value indicating if the component has
been modified from the original. A value of true indicates the component is
a derivative of the original. A value of false indicates the component has
not been modified from the original.

=item C<name>, The name of the component. This will often be a shortened,
single name of the component. Examples: commons-lang3 and jquery

=item C<omnibor_id>, Asserts the identity of the component using the
OmniBOR Artifact ID. The OmniBOR, if specified, must be valid and conform
to the specification defined at: L<https://www.iana.org/assignments/uri-schemes/prov/gitoid>.
Refer to "evidence->identity" method to optionally provide evidence that
substantiates the assertion of the component's identity.

=item C<pedigree>, Component pedigree is a way to document complex supply
chain scenarios where components are created, distributed, modified,
redistributed, combined with other components, etc. Pedigree supports
viewing this complex chain from the beginning, the end, or anywhere in the
middle. It also provides a way to document variants where the exact
relation may not be known.

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the CycloneDX
Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).
Formal registration is optional.

=item C<publisher>, The person(s) or organization(s) that published the
component

=item C<purl>, Asserts the identity of the component using package-url
(purl). The purl, if specified, must be valid and conform to the
specification defined at L<https://github.com/package-url/purl-spec>).
Refer to "evidence->identity" method to optionally provide evidence
that substantiates the assertion of the component's identity.

=item C<release_notes>, Specifies optional release notes.

=item C<scope>, Specifies the scope of the component. If scope is not
specified, 'required' scope SHOULD be assumed by the consumer of the BOM.

=item C<signature>, Enveloped signature in JSON Signature Format
(JSF) (L<https://cyberphone.github.io/doc/security/jsf.html>).

=item C<supplier>,  The organization that supplied the component. The
supplier may often be the manufacturer, but may also be a distributor or
repackager.

=item C<swhid>, Asserts the identity of the component using the Software
Heritage persistent identifier (SWHID). The SWHID, if specified, must be
valid and conform to the specification defined at:
L<https://docs.softwareheritage.org/devel/swh-model/persistent-identifiers.h
tml>]. Refer to "evidence->identity" method to optionally provide evidence
that substantiates the assertion of the component's identity.

=item C<swid>, Asserts the identity of the component using ISO-IEC 19770-2
Software Identification (SWID) Tags (L<https://www.iso.org/standard/65666.html>).
Refer to "evidence->identity" method to optionally provide evidence that substantiates
the assertion of the component's identity.

=item C<tags>, Tags

=item C<type>, Specifies the type of component. For software components,
classify as application if no more specific appropriate classification is
available or cannot be determined for the component.

=item C<version>, The component version. The version should ideally comply
with semantic versioning but is not enforced.

=back

=item $component->author

=item $component->authors

=item $component->bom_ref

=item $component->components

=item $component->copyright

=item $component->cpe

=item $component->crypto_properties

=item $component->data

=item $component->description

=item $component->evidence

=item $component->external_references

=item $component->group

=item $component->hashes

=item $component->licenses

=item $component->manufacturer

=item $component->mime_type

=item $component->model_card

=item $component->modified

=item $component->name

=item $component->omnibor_id

=item $component->pedigree

=item $component->properties

=item $component->publisher

=item $component->purl

=item $component->release_notes

=item $component->scope

=item $component->signature

=item $component->supplier

=item $component->swhid

=item $component->swid

=item $component->tags

=item $component->type

=item $component->version

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

This software is copyright (c) 2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
