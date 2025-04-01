package SBOM::CycloneDX::Metadata;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;

use SBOM::CycloneDX::Timestamp;
use SBOM::CycloneDX::List;

use Types::Standard qw(Str InstanceOf);
use Types::TypeTiny qw(ArrayLike);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';

sub BUILD {
    my ($self, $args) = @_;
    Carp::carp '"manufacture" is deprecated from CycloneDX v1.6. '
        . 'Use the SBOM::CycloneDX::Component->manufacturer instead'
        if exists $args->{manufacture};
}


has timestamp => (
    is     => 'rw',
    isa    => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) }
);

has lifecycles => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Metadata::Lifecyle']],
    default => sub { SBOM::CycloneDX::List->new }
);

has tools => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::Tool']] | InstanceOf ['SBOM::CycloneDX::Tools'],
    default => sub { SBOM::CycloneDX::List->new }
);

has manufacturer => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);

has authors => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::OrganizationalContact']],
    default => sub { SBOM::CycloneDX::List->new }
);

has component   => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::Component']);
has manufacture => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);
has supplier    => (is => 'rw', isa => InstanceOf ['SBOM::CycloneDX::OrganizationalEntity']);

has licenses => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::License']],
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

    $json->{timestamp}   = $self->timestamp   if $self->timestamp;
    $json->{lifecycles}  = $self->lifecycles  if @{$self->lifecycles};
    $json->{tools}       = $self->tools       if @{$self->tools};
    $json->{authors}     = $self->authors     if @{$self->authors};
    $json->{component}   = $self->component   if $self->component;
    $json->{manufacture} = $self->manufacture if $self->manufacture;
    $json->{supplier}    = $self->supplier    if $self->supplier;
    $json->{licenses}    = $self->licenses    if @{$self->licenses};
    $json->{properties}  = $self->properties  if @{$self->properties};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Metadata - BOM Metadata

=head1 SYNOPSIS

    SBOM::CycloneDX::Metadata->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Metadata> provides additional information about a BOM.

=head2 METHODS

L<SBOM::CycloneDX::Metadata> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Metadata->new( %PARAMS )

Properties:

=over

=item C<BUILD>, 

=item C<authors>, The person(s) who created the BOM.
Authors are common in BOMs created through manual processes. BOMs created
through automated means may have "manufacturer" instead.

=item C<component>, The component that the BOM describes.

=item C<licenses>, The license information for the BOM document.
This may be different from the license(s) of the component(s) that the BOM
describes.

=item C<lifecycles>, Lifecycles communicate the stage(s) in which data in
the BOM was captured. Different types of data may be available at various
phases of a lifecycle, such as the Software Development Lifecycle (SDLC),
IT Asset Management (ITAM), and Software Asset Management (SAM). Thus, a
BOM may include data specific to or only obtainable in a given lifecycle.

=item C<manufacture>, [Deprecated in 1.6] This will be removed in a future
version. Use the "manufacturer" method in L<SBOM::CycloneDX::Component> instead.
The organization that manufactured the component that the BOM describes.

=item C<manufacturer>, The organization that created the BOM.
Manufacturer is common in BOMs created through automated processes. BOMs
created through manual means may have `@.authors` instead.

=item C<properties>, Provides the ability to document properties in a
name-value store. This provides flexibility to include data not officially
supported in the standard without having to use additional namespaces or
create extensions. Unlike key-value stores, properties support duplicate
names, each potentially having different values. Property names of interest
to the general public are encouraged to be registered in the CycloneDX
Property Taxonomy (L<https://github.com/CycloneDX/cyclonedx-property-taxonomy>).
Formal registration is optional.

=item C<supplier>,  The organization that supplied the component that the
BOM describes. The supplier may often be the manufacturer, but may also be
a distributor or repackager.

=item C<timestamp>, The date and time (timestamp) when the BOM was created.

=item C<tools>, The tool(s) used in the creation, enrichment, and
validation of the BOM.

=back

=item $metadata->BUILD

=item $metadata->authors

=item $metadata->component

=item $metadata->licenses

=item $metadata->lifecycles

=item $metadata->manufacture

=item $metadata->manufacturer

=item $metadata->properties

=item $metadata->supplier

=item $metadata->timestamp

=item $metadata->tools

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
