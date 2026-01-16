package SBOM::CycloneDX::Standard::Requirement;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

use Types::Standard qw(InstanceOf Str StrMatch);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has identifier => (is => 'rw', isa => Str);
has title      => (is => 'rw', isa => Str);
has text       => (is => 'rw', isa => Str);

has descriptions => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has open_cre => (
    is      => 'rw',
    isa     => ArrayLike [StrMatch [qr{^CRE:[0-9]+-[0-9]+$}]],
    default => sub { SBOM::CycloneDX::List->new }
);

has parent => (is => 'rw', isa => Str);    # Like bom-ref

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

has external_references => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::ExternalReference']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}          = $self->bom_ref             if $self->bom_ref;
    $json->{identifier}         = $self->identifier          if $self->identifier;
    $json->{title}              = $self->title               if $self->title;
    $json->{text}               = $self->text                if $self->text;
    $json->{descriptions}       = $self->descriptions        if $self->descriptions;
    $json->{openCre}            = $self->open_cre            if $self->open_cre;
    $json->{parent}             = $self->parent              if $self->parent;
    $json->{properties}         = $self->properties          if $self->properties;
    $json->{externalReferences} = $self->external_references if @{$self->external_references};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Standard::Requirement - Requirement

=head1 SYNOPSIS

    SBOM::CycloneDX::Standard::Requirement->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Standard::Requirement> provides the requirement comprising the standard.

=head2 METHODS

L<SBOM::CycloneDX::Standard::Requirement> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Standard::Requirement->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An identifier which can be used to reference the
object elsewhere in the BOM. Every bom-ref must be unique within the BOM.

=item C<descriptions>, The supplemental text that provides additional
guidance or context to the requirement, but is not directly part of the
requirement.

=item C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant, but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item C<identifier>, The unique identifier used in the standard to identify
a specific requirement. This should match what is in the standard and
should not be the requirements bom-ref.

=item C<open_cre>, The Common Requirements Enumeration (CRE) identifier(s).
CRE is a structured and standardized framework for uniting security
standards and guidelines. CRE links each section of a resource to a shared
topic identifier (a Common Requirement). Through this shared topic link,
all resources map to each other. Use of CRE promotes clear and unambiguous
communication among stakeholders.

=item C<parent>, The optional `bom-ref` to a parent requirement. This
establishes a hierarchy of requirements. Top-level requirements must not
define a parent. Only child requirements should define parents.

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the [CycloneDX
Property
Taxonomy](https://github.com/CycloneDX/cyclonedx-property-taxonomy). Formal
registration is optional.

=item C<text>, The textual content of the requirement.

=item C<title>, The title of the requirement.

=back

=item $requirement->bom_ref

=item $requirement->descriptions

=item $requirement->external_references

=item $requirement->identifier

=item $requirement->open_cre

=item $requirement->parent

=item $requirement->properties

=item $requirement->text

=item $requirement->title

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
