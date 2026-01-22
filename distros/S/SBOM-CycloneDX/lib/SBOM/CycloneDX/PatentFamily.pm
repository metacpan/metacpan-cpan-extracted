package SBOM::CycloneDX::PatentFamily;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::List;

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

has family_id => (is => 'rw', isa => Str, required => 1);

has priority_application => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Patent::PriorityApplication']);

has members => (
    is      => 'rw',
    isa     => ArrayLike [Str | InstanceOf ['SBOM::CycloneDX::BomRef']],
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

    $json->{'bom-ref'}           = $self->bom_ref              if ($self->bom_ref);
    $json->{familyId}            = $self->family_id            if ($self->family_id);
    $json->{priorityApplication} = $self->priority_application if ($self->priority_application);
    $json->{members}             = $self->members              if (@{$self->members});
    $json->{externalReferences}  = $self->external_references  if (@{$self->external_references});

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::PatentFamily - Patent Family

=head1 SYNOPSIS

    SBOM::CycloneDX::PatentFamily->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::PatentFamily> A patent family is a group of related
patent applications or granted patents that cover the same or similar
invention. These patents are filed in multiple jurisdictions to protect the
invention across different regions or countries. A patent family typically
includes patents that share a common priority date, originating from the
same initial application, and may vary slightly in scope or claims to
comply with regional legal frameworks. Fields align with WIPO ST.96
standards where applicable.

=head2 METHODS

L<SBOM::CycloneDX::PatentFamily> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::PatentFamily->new( %PARAMS )

Properties:

=over

=item * C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every C<bom-ref> must be unique within the BOM. 

For a patent, it might be a good idea to use a patent number as the BOM
reference ID.

=item * C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item * C<family_id>, The unique identifier for the patent family, aligned
with the C<id> attribute in WIPO ST.96 v8.0's C<PatentFamilyType>. Refer to
L<PatentFamilyType in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/PatentFa
milyType.xsd>.

=item * C<members>, A collection of patents or applications that belong to
this family, each identified by a C<bom-ref> pointing to a patent object
defined elsewhere in the BOM.

=item * C<priority_application>, The "priority_application" contains the 
essential data necessary to identify and reference an earlier patent filing for 
priority rights. In line with WIPO ST.96 guidelines, it includes the 
jurisdiction (office code), application number, and filing date-the three key 
elements that uniquely specify the priority application in a global patent 
context.

See L<SBOM::CycloneDX::Patent::PriorityApplication>.

=back

=item $patent_family->bom_ref

=item $patent_family->external_references

=item $patent_family->family_id

=item $patent_family->members

=item $patent_family->priority_application

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
