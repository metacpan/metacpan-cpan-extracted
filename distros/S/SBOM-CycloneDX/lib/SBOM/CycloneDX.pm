package SBOM::CycloneDX;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Str StrMatch Int Num InstanceOf HashRef);
use Types::TypeTiny qw(ArrayLike);

use SBOM::CycloneDX::Declarations;
use SBOM::CycloneDX::Definitions;
use SBOM::CycloneDX::Dependency;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Metadata;
use SBOM::CycloneDX::Schema;
use SBOM::CycloneDX::Util qw(urn_uuid);

use List::Util qw(uniq);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

use constant JSON_SCHEMA_1_2 => 'http://cyclonedx.org/schema/bom-1.2b.schema.json';
use constant JSON_SCHEMA_1_3 => 'http://cyclonedx.org/schema/bom-1.3a.schema.json';
use constant JSON_SCHEMA_1_4 => 'http://cyclonedx.org/schema/bom-1.4.schema.json';
use constant JSON_SCHEMA_1_5 => 'http://cyclonedx.org/schema/bom-1.5.schema.json';
use constant JSON_SCHEMA_1_6 => 'http://cyclonedx.org/schema/bom-1.6.schema.json';

our $VERSION = 1.03;

our %JSON_SCHEMA = (
    '1.2' => JSON_SCHEMA_1_2,
    '1.3' => JSON_SCHEMA_1_3,
    '1.4' => JSON_SCHEMA_1_4,
    '1.5' => JSON_SCHEMA_1_5,
    '1.6' => JSON_SCHEMA_1_6,
);

has bom_format => (is => 'ro', isa => Str, required => 1, default => 'CycloneDX');
has spec_version => (is => 'rw', isa => Num->where(sub { defined $JSON_SCHEMA{$_} }), required => 1, default => 1.6);

has serial_number => (
    is      => 'rw',
    isa     => StrMatch [qr{^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$}],
    default => sub {urn_uuid}
);

has version => (is => 'rw', isa => Int, default => 1);

has metadata =>
    (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Metadata'], default => sub { SBOM::CycloneDX::Metadata->new });

has components => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Component']],
    default => sub { SBOM::CycloneDX::List->new }
);

has services => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Service']],
    default => sub { SBOM::CycloneDX::List->new }
);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

has dependencies => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Dependency']],
    default => sub { SBOM::CycloneDX::List->new }
);

has compositions => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Composition']],
    default => sub { SBOM::CycloneDX::List->new }
);

has vulnerabilities => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Vulnerability']],
    default => sub { SBOM::CycloneDX::List->new }
);

has annotations => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Annotations']],
    default => sub { SBOM::CycloneDX::List->new }
);

has formulation => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Formulation']],
    default => sub { SBOM::CycloneDX::List->new }
);

has declarations => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::Declarations'],
    default => sub { SBOM::CycloneDX::Declarations->new }
);

has definitions => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::Definitions'],
    default => sub { SBOM::CycloneDX::Definitions->new }
);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

# TODO  JSF (JSON Signature Format)
has signature => (is => 'rw', isa => HashRef, default => sub { {} });


sub validate { SBOM::CycloneDX::Schema->new(bom => shift)->validate }

sub add_dependency {

    my ($self, $target, $depends_on) = @_;

    my $target_ref      = $target->bom_ref;
    my @depends_on_refs = map { $_->bom_ref } @{$depends_on};

    my $exists = 0;

    foreach my $dependency ($self->dependencies->each) {

        next unless $dependency->ref eq $target_ref;

        $exists = 1;

        # TODO
        my @old_refs = @{$dependency->depends_on};
        push @old_refs, @depends_on_refs;
        my @new_refs = uniq(@old_refs);

        $dependency->depends_on(\@new_refs);

    }

    if (not $exists) {
        $self->dependencies->push(
            SBOM::CycloneDX::Dependency->new(ref => $target_ref, depends_on => \@depends_on_refs));
    }

    # Add empty dependency entry if not exists "ref"
    $self->add_dependency($_, []) for (@{$depends_on});

}

sub get_component_by_purl {

    my ($self, $purl) = @_;

    foreach my $component (@{$self->components}) {
        return $component if ($component->purl && $component->purl eq $purl);
    }

}

sub get_component_by_bom_ref {

    my ($self, $bom_ref) = @_;

    foreach my $component (@{$self->components}) {
        return $component if ($component->bom_ref && $component->bom_ref eq $bom_ref);
    }

}

sub get_vulnerabilities_for_bom_ref {

    my ($self, $bom_ref) = @_;

    my $list = SBOM::CycloneDX::List->new;

    foreach my $vulnerability (@{$self->vulnerabilities}) {
        foreach my $affect (@{$vulnerability->affects}) {
            $list->add($vulnerability) if $affect->ref eq $bom_ref;
        }
    }

    return $list;

}

sub get_affected_components_by_cve {

    my ($self, $cve_id) = @_;

    my $list = SBOM::CycloneDX::List->new;

    foreach my $vulnerability (@{$self->vulnerabilities}) {
        if ($vulnerability->id eq $cve_id) {
            foreach my $affect (@{$vulnerability->affects}) {
                $list->add($self->get_component_by_bom_ref($affect->ref));
            }
        }
    }

    return $list;

}

sub TO_JSON {

    my $self = shift;

    my $spec_version = $self->spec_version;
    my $schema       = $JSON_SCHEMA{$spec_version};

    my $json = {'$schema' => $schema, bomFormat => $self->bom_format, specVersion => "$spec_version"};

    $json->{serialNumber}       = $self->serial_number       if $self->serial_number;
    $json->{version}            = $self->version             if $self->version;
    $json->{metadata}           = $self->metadata            if %{$self->metadata->TO_JSON};
    $json->{components}         = $self->components          if @{$self->components};
    $json->{services}           = $self->services            if @{$self->services};
    $json->{externalReferences} = $self->external_references if @{$self->external_references};
    $json->{dependencies}       = $self->dependencies        if @{$self->dependencies};
    $json->{compositions}       = $self->compositions        if @{$self->compositions};
    $json->{vulnerabilities}    = $self->vulnerabilities     if @{$self->vulnerabilities};
    $json->{annotations}        = $self->annotations         if @{$self->annotations};
    $json->{formulation}        = $self->formulation         if @{$self->formulation};
    $json->{declarations}       = $self->declarations        if %{$self->declarations->TO_JSON};
    $json->{definitions}        = $self->definitions         if @{$self->definitions->standards};
    $json->{properties}         = $self->properties          if @{$self->properties};
    $json->{signature}          = $self->signature           if %{$self->signature};

    return $json;

}


1;

__END__

=encoding utf-8

=head1 NAME

SBOM::CycloneDX - CycloneDX Perl Library

=head1 SYNOPSIS

    my $bom = SBOM::CycloneDX->new;

    my $root_component = SBOM::CycloneDX::Component->new(
        type     => 'application',
        name     => 'MyApp',
        licenses => [SBOM::CycloneDX::License->new('Artistic-2.0')],
        bom_ref  => 'MyApp'
    );

    my $metadata = $bom->metadata;

    $metadata->tools->add(cyclonedx_tool);

    $metadata->component($root_component);

    my $component1 = SBOM::CycloneDX::Component->new(
        type     => 'library',
        name     => 'some-component',
        group    => 'acme',
        version  => '1.33.7-beta.1',
        licenses => [SBOM::CycloneDX::License->new(name => '(c) 2021 Acme inc.')],
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

    my $component2 = SBOM::CycloneDX::Component->new(
        type     => 'library',
        name     => 'some-library',
        licenses => [SBOM::CycloneDX::License->new(expression => 'GPL-3.0-only WITH Classpath-exception-2.0')],
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

L<SBOM::CycloneDX> is a library for generate valid CycloneDX BOM file.

CycloneDX is a modern standard for the software supply chain. At its core,
CycloneDX is a general-purpose Bill of Materials (BOM) standard capable of
representing software, hardware, services, and other types of inventory.
The CycloneDX standard began in 2017 in the Open Worldwide Application Security
Project (OWASP) community. CycloneDX is an OWASP flagship project, has a formal
standardization process and governance model, and is supported by the global
information security community.

CycloneDX far exceeds the L<Minimum Elements for Software Bill of Materials|https://www.ntia.gov/files/ntia/publications/sbom_minimum_elements_report.pdf>
as defined by the L<National Telecommunications and Information Administration (NTIA)|https://www.ntia.gov/>
in response to L<U.S. Executive Order 14028|https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/>.

CycloneDX provides advanced supply chain capabilities for cyber risk reduction. Among these capabilities are:

=over

=item Software Bill of Materials (SBOM)

=item Software-as-a-Service Bill of Materials (SaaSBOM)

=item Hardware Bill of Materials (HBOM)

=item Machine Learning Bill of Materials (ML-BOM)

=item Cryptography Bill of Materials (CBOM)

=item Operations Bill of Materials (OBOM)

=item Manufacturing Bill of Materials (MBOM)

=item Bill of Vulnerabilities (BOV)

=item Vulnerability Disclosure Report (VDR)

=item Vulnerability Exploitability eXchange (VEX)

=item CycloneDX Attestations (CDXA)

=item Common Release Notes Format

=back

L<https://www.cyclonedx.org>


=head2 MODELS

=over

=item L<SBOM::CycloneDX>

=item L<SBOM::CycloneDX::Advisory>

=item L<SBOM::CycloneDX::Annotation>

=over

=item L<SBOM::CycloneDX::Annotation::Annotator>

=back

=item L<SBOM::CycloneDX::Attachment>

=item L<SBOM::CycloneDX::Component>

=over

=item L<SBOM::CycloneDX::Component::Commit>

=item L<SBOM::CycloneDX::Component::ConfidenceInterval>

=item L<SBOM::CycloneDX::Component::Diff>

=item L<SBOM::CycloneDX::Component::Graphic>

=item L<SBOM::CycloneDX::Component::GraphicsCollection>

=item L<SBOM::CycloneDX::Component::ModelCard>

=item L<SBOM::CycloneDX::Component::Patch>

=item L<SBOM::CycloneDX::Component::Pedigree>

=item L<SBOM::CycloneDX::Component::PerformanceMetric>

=item L<SBOM::CycloneDX::Component::QuantitativeAnalysis>

=item L<SBOM::CycloneDX::Component::SWID>

=back

=item L<SBOM::CycloneDX::CryptoProperties>

=over

=item L<SBOM::CycloneDX::CryptoProperties::AlgorithmProperties>

=item L<SBOM::CycloneDX::CryptoProperties::CertificateProperties>

=item L<SBOM::CycloneDX::CryptoProperties::CipherSuite>

=item L<SBOM::CycloneDX::CryptoProperties::Ikev2TransformType>

=item L<SBOM::CycloneDX::CryptoProperties::ProtocolProperties>

=item L<SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties>

=item L<SBOM::CycloneDX::CryptoProperties::SecuredBy>

=back

=item L<SBOM::CycloneDX::DataGovernance>

=item L<SBOM::CycloneDX::DataGovernanceResponsibleParty>

=item L<SBOM::CycloneDX::Declarations>

=over

=item L<SBOM::CycloneDX::Declarations::Affirmation>

=item L<SBOM::CycloneDX::Declarations::Assessor>

=item L<SBOM::CycloneDX::Declarations::Attestation>

=item L<SBOM::CycloneDX::Declarations::Claim>

=item L<SBOM::CycloneDX::Declarations::Confidence>

=item L<SBOM::CycloneDX::Declarations::Conformance>

=item L<SBOM::CycloneDX::Declarations::Contents>

=item L<SBOM::CycloneDX::Declarations::Data>

=item L<SBOM::CycloneDX::Declarations::Evidence>

=item L<SBOM::CycloneDX::Declarations::Map>

=item L<SBOM::CycloneDX::Declarations::Signatory>

=item L<SBOM::CycloneDX::Declarations::Targets>

=back

=item L<SBOM::CycloneDX::Definitions>

=item L<SBOM::CycloneDX::Dependency>

=item L<SBOM::CycloneDX::ExternalReference>

=item L<SBOM::CycloneDX::Formulation>

=item L<SBOM::CycloneDX::Hash>

=item L<SBOM::CycloneDX::IdentifiableAction>

=item L<SBOM::CycloneDX::Issue>

=over

=item L<SBOM::CycloneDX::Issue::Source>

=back

=item L<SBOM::CycloneDX::License>

=over

=item L<SBOM::CycloneDX::License::Licensee>

=item L<SBOM::CycloneDX::License::Licensing>

=item L<SBOM::CycloneDX::License::Licensor>

=item L<SBOM::CycloneDX::License::Purchaser>

=back

=item L<SBOM::CycloneDX::Metadata>

=item L<SBOM::CycloneDX::Metadata::Lifecycle>

=item L<SBOM::CycloneDX::Note>

=item L<SBOM::CycloneDX::OrganizationalContact>

=item L<SBOM::CycloneDX::OrganizationalEntity>

=item L<SBOM::CycloneDX::PostalAddress>

=item L<SBOM::CycloneDX::Property>

=item L<SBOM::CycloneDX::ReleaseNotes>

=item L<SBOM::CycloneDX::Schema>

=item L<SBOM::CycloneDX::Service>

=item L<SBOM::CycloneDX::Standard>

=over

=item L<SBOM::CycloneDX::Standard::Level>

=item L<SBOM::CycloneDX::Standard::Requirement>

=back

=item L<SBOM::CycloneDX::Tool>

=item L<SBOM::CycloneDX::Tools>

=item L<SBOM::CycloneDX::Version>

=item L<SBOM::CycloneDX::Vulnerability>

=over

=item L<SBOM::CycloneDX::Vulnerability::Affect>

=item L<SBOM::CycloneDX::Vulnerability::Analysis>

=item L<SBOM::CycloneDX::Vulnerability::Credits>

=item L<SBOM::CycloneDX::Vulnerability::ProofOfConcept>

=item L<SBOM::CycloneDX::Vulnerability::Rating>

=item L<SBOM::CycloneDX::Vulnerability::Reference>

=item L<SBOM::CycloneDX::Vulnerability::Source>

=back

=back

=head3 HELPERS

=over

=item L<SBOM::CycloneDX::BomRef>

=item L<SBOM::CycloneDX::Enum>

=item L<SBOM::CycloneDX::List>

=item L<SBOM::CycloneDX::Timestamp>

=item L<SBOM::CycloneDX::Util>

=back

=head2 METHODS

L<SBOM::CycloneDX> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX->new( %PARAMS )

=item $bom->version

Whenever an existing BOM is modified, either manually or through
automated processes, the version of the BOM SHOULD be
incremented by 1. When a system is presented with multiple BOMs
with identical serial numbers, the system SHOULD use the most
recent version of the BOM. The default version is '1'.

=item $bom->metadata

Provides additional information about a BOM.

See L<SBOM::CycloneDX::Metadata>.

=item $bom->components

A list of software and hardware components.

    $bom->components->add($component);

See L<SBOM::CycloneDX::Component>.

=item $sbom->services

A list of services. This may include microservices, function-as-a-
service, and other types of network or intra-process services.

    $bom->services->add($service);

See L<SBOM::CycloneDX::Service>.

=item $bom->external_references

External references provide a way to document systems, sites, and
information that may be relevant but are not included with the BOM.
They may also establish specific relationships within or external to the
BOM.

    $bom->external_references->add($external_reference);

See L<SBOM::CycloneDX::ExternalReferences>.

=item $bom->dependencies

Provides the ability to document dependency relationships including
provided & implemented components.

    $bom->dependencies->add($dependency);

    # or

    $bom->add_dependency($parent_component, [$component1, component2])

See L<SBOM::CycloneDX::Dependency>.

=item $bom->compositions

Compositions describe constituent parts (including components,
services, and dependency relationships) and their completeness. The
completeness of vulnerabilities expressed in a BOM may also be
described.

    $bom->compositions->add($composition);

See L<SBOM::CycloneDX::Composition>.

=item $bom->vulnerabilities

Vulnerabilities identified in components or services.

    $bom->vulnerabilities->add($vulnerability);

See L<SBOM::CycloneDX::Vulnerability>.

=item $bom->annotations

Comments made by people, organizations, or tools about any object
with a bom-ref, such as components, services, vulnerabilities, or the
BOM itself. Unlike inventory information, annotations may contain
opinions or commentary from various stakeholders. Annotations may
be inline (with inventory) or externalized via BOM-Link and may
optionally be signed.

    $bom->annotations->add($annotation);

See L<SBOM::CycloneDX::Annotation>.

=item $bom->formulation

Describes how a component or service was manufactured or
deployed. This is achieved through the use of formulas, workflows,
tasks, and steps, which declare the precise steps to reproduce along
with the observed formulas describing the steps which transpired in the
manufacturing process.

    $bom->formulation->add($formulation);

See L<SBOM::CycloneDX::Formulation>.

=item $bom->declarations

The list of declarations which describe the conformance to standards.
Each declaration may include attestations, claims, and evidence.

See L<SBOM::CycloneDX::Declarations>.

=item $bom->definitions

A collection of reusable objects that are defined and may be used
elsewhere in the BOM.

    $bom->definitions->add($definition);

See L<SBOM::CycloneDX::Definition>.

=item $bom->properties

Provides the ability to document properties in a name-value store. This
provides flexibility to include data not officially supported in the
standard without having to use additional namespaces or create
extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of
interest to the general public are encouraged to be registered in the
CycloneDX Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).

Formal registration is optional.

    $bom->definitions->add($property);

See L<SBOM::CycloneDX::Property>.

=item $bom->signature

Enveloped signature in JSON Signature Format (JSF) L<https://cyberphone.github.io/doc/security/jsf.html>.

=back

=head2 HELPERS

=over

=item $bom->add_dependency($parent, [$components...])

Adds a relationship between one or more components.

    $bom->add_dependency($parent_component, [$component1]);
    $bom->add_dependency($parent_component, [$component1, component2]);

=item $bom->get_component_by_purl($purl)

Return the component with specific PURL string.

    if ($bom->get_component_by_purl($purl)) {
        say "Found component with $purl PURL";
    }

=item $bom->get_component_by_bom_ref($ref)

Return the component with specific BOM-Ref string.

    if ($bom->get_component_by_bom_ref($bom_ref)) {
        say "Found component with $bom_ref BOM-Ref";
    }

=item $bom->get_vulnerabilities_for_bom_ref($bom_ref)

Return L<SBOM::CycloneDX::List> with a list of vulnerabilities with the same C<bom_ref>.

=item $bom->get_affected_components_by_cve ($cve_id)

Return L<SBOM::CycloneDX::List> with a list of components affected with the same C<cve_id>.

    say $_->bom_ref for($bom->get_affected_components_by_cve('CVE-2025-1234')->list);

=item $bom->validate

Validates BOM file with the JSON Schema and return the L<JSON::Validator> errors.

    my @errors = $bom->validate;

    if (@errors) {
        say $_ for @errors;
        Carp::croak "Invalid BOM";
    }

See L<SBOM::CycloneDX::Schema>.

=item $bom->to_string

Encode in JSON.

    say $bom->to_string;

    # or

    say "$bom";

=item $bom->TO_JSON

Encode in JSON.

    say encode_json($bom);

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
