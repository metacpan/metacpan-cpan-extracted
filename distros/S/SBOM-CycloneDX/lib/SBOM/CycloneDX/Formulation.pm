package SBOM::CycloneDX::Formulation;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

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

has workflows => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Workflow']],
    default => sub { SBOM::CycloneDX::List->new }
);

has properties => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Property']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'}  = $self->bom_ref    if $self->bom_ref;
    $json->{components} = $self->components if @{$self->components};
    $json->{services}   = $self->services   if @{$self->services};
    $json->{workflows}  = $self->workflows  if @{$self->workflows};
    $json->{properties} = $self->properties if @{$self->properties};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Formulation - Formula

=head1 SYNOPSIS

    SBOM::CycloneDX::Formulation->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Formulation> describes the formulation of any referencable 
object within the BOM, including components, services, metadata, declarations, 
or the BOM itself. This may encompass how the object was created, assembled, 
deployed, tested, certified, or otherwise brought into its present form. Common 
examples include software build pipelines, deployment processes, AI/ML model 
training, cryptographic key generation or certification, and third-party 
audits. Processes are modeled using declared and observed formulas, composed of 
workflows, tasks, and individual steps.

=head2 METHODS

L<SBOM::CycloneDX::Formulation> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Formulation->new( %PARAMS )

Properties:

=over

=item C<bom_ref>, An identifier which can be used to reference the
formula elsewhere in the BOM. Every bom-ref must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<components>, Transient components that are used in tasks that
constitute one or more of this formula's workflows

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the CycloneDX
Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).
Formal registration is optional.

=item C<services>, Transient services that are used in tasks that
constitute one or more of this formula's workflows

=item C<workflows>, List of workflows that can be declared to accomplish
specific orchestrated goals and independently triggered.

=back

=item $formulation->bom_ref

=item $formulation->components

=item $formulation->properties

=item $formulation->services

=item $formulation->workflows

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
