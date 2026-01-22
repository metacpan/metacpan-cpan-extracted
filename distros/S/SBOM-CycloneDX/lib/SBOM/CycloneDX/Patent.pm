package SBOM::CycloneDX::Patent;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::Enum;
use SBOM::CycloneDX::List;
use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str InstanceOf Enum);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

has bom_ref => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::BomRef'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::BomRef->new($_[0]) }
);

has patent_number => (is => 'rw', isa => Str, required => 1);

has application_number => (is => 'rw', isa => Str);

has jurisdiction => (is => 'rw', required => 1);

has priority_application => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Patent::PriorityApplication']);

has publication_number => (is => 'rw', isa => Str);

has title => (is => 'rw', isa => Str);

has abstract => (is => 'rw', isa => Str);

has filing_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has grant_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has patent_expiration_date => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has patent_legal_status =>
    (is => 'rw', isa => Enum [SBOM::CycloneDX::Enum->values('PATENT_LEGAL_STATUS')], required => 1);

has patent_assignee => (
    is  => 'rw',
    isa => ArrayLike [
        InstanceOf ['SBOM::CycloneDX::OrganizationalContact'] | InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']
    ],
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

    $json->{'bom-ref'}            = $self->bom_ref                if ($self->bom_ref);
    $json->{patentNumber}         = $self->patent_number          if ($self->patent_number);
    $json->{applicationNumber}    = $self->application_number     if ($self->application_number);
    $json->{jurisdiction}         = $self->jurisdiction           if ($self->jurisdiction);
    $json->{priorityApplication}  = $self->priority_application   if ($self->priority_application);
    $json->{publicationNumber}    = $self->publication_number     if ($self->publication_number);
    $json->{title}                = $self->title                  if ($self->title);
    $json->{abstract}             = $self->abstract               if ($self->abstract);
    $json->{filingDate}           = $self->filing_date            if ($self->filing_date);
    $json->{grantDate}            = $self->grant_date             if ($self->grant_date);
    $json->{patentExpirationDate} = $self->patent_expiration_date if ($self->patent_expiration_date);
    $json->{patentLegalStatus}    = $self->patent_legal_status    if ($self->patent_legal_status);
    $json->{patentAssignee}       = $self->patent_assignee        if (@{$self->patent_assignee});
    $json->{externalReferences}   = $self->external_references    if (@{$self->external_references});

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Patent - Patent

=head1 SYNOPSIS

    SBOM::CycloneDX::Patent->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Patent> A patent is a legal instrument, granted by an
authority, that confers certain rights over an invention for a specified
period, contingent on public disclosure and adherence to relevant legal
requirements. The summary information in this object is aligned with
L<WIPO ST.96|https://www.wipo.int/standards/en/st96/> principles where
applicable.

=head2 METHODS

L<SBOM::CycloneDX::Patent> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Patent->new( %PARAMS )

Properties:

=over

=item * C<abstract>, A brief summary of the invention described in the
patent. Aligned with C<Abstract> and C<P> in WIPO ST.96. Refer to
L<Abstract in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/Abstract.xsd)>.

=item * C<application_number>, The unique number assigned to a patent application 
when it is filed with a patent office. It is used to identify the specific 
application and track its progress through the examination process. Aligned 
with C<ApplicationNumber> in ST.96. Refer to L<ApplicationIdentificationType in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/ApplicationIdentificationType.xsd>.

=item * C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every C<bom-ref> must be unique within the BOM.

=item * C<external_references>, External references provide a way to document
systems, sites, and information that may be relevant but are not included
with the BOM. They may also establish specific relationships within or
external to the BOM.

=item * C<filing_date>, The date the patent application was filed with the
jurisdiction. Aligned with C<FilingDate> in WIPO ST.96. Refer to
L<FilingDate in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/FilingDate.xsd>.

=item * C<grant_date>, The date the patent was granted by the jurisdiction.
Aligned with C<GrantDate> in WIPO ST.96. Refer to
L<GrantDate in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/PatentNumber.xsd>.

=item * C<jurisdiction>, The jurisdiction or patent office where the priority 
application was filed, specified using WIPO ST.3 codes. Aligned with 
C<IPOfficeCode> in ST.96. Refer to L<WIPOfficeCode in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Common/IPOfficeCode.xsd>.

=item * C<patent_assignee>, A collection of organisations or individuals to
whom the patent rights are assigned. This supports joint ownership and
allows for flexible representation of both corporate entities and
individual inventors.

See L<SBOM::CycloneDX::OrganizationalEntity> and L<SBOM::CycloneDX::OrganizationalContact>.

=item * C<patent_expiration_date>, The date the patent expires. Derived from
grant or filing date according to jurisdiction-specific rules.

=item * C<patent_legal_status>, Indicates the current legal status of the
patent or patent application, based on the WIPO ST.27 standard. This status
reflects administrative, procedural, or legal events. Values include both
active and inactive states and are useful for determining enforceability,
procedural history, and maintenance status.

=item * C<patent_number>, The unique number assigned to the granted patent by
the issuing authority. Aligned with C<PatentNumber> in WIPO ST.96. Refer to
L<PatentNumber in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/PatentNumber.xsd>.

=item * C<priority_application>, The "priority_application" contains the 
essential data necessary to identify and reference an earlier patent filing for 
priority rights. In line with WIPO ST.96 guidelines, it includes the 
jurisdiction (office code), application number, and filing date-the three key 
elements that uniquely specify the priority application in a global patent 
context.

See L<SBOM::CycloneDX::Patent::PriorityApplication>.

=item * C<publication_number>, This is the number assigned to a patent
application once it is published. Patent applications are generally
published 18 months after filing (unless an applicant requests
non-publication). This number is distinct from the application number. 

Purpose: Identifies the publicly available version of the application. 

Format: Varies by jurisdiction, often similar to application numbers but
includes an additional suffix indicating publication. 

Example:

 - US: US20240000123A1 (indicates the first publication of application
US20240000123) 

 - Europe: EP23123456A1 (first publication of European application
EP23123456). 

WIPO ST.96 v8.0: 
 - Publication Number field: L<https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/PublicationNumber.xsd>

=item * C<title>, The title of the patent, summarising the invention it
protects. Aligned with C<InventionTitle> in WIPO ST.96. Refer to
L<InventionTitle in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/InventionTitle.xsd>.

=back

=item $patent->abstract

=item $patent->application_number

=item $patent->bom_ref

=item $patent->external_references

=item $patent->filing_date

=item $patent->grant_date

=item $patent->jurisdiction

=item $patent->patent_assignee

=item $patent->patent_expiration_date

=item $patent->patent_legal_status

=item $patent->patent_number

=item $patent->priority_application

=item $patent->publication_number

=item $patent->title

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
