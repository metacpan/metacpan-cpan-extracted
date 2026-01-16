package SBOM::CycloneDX::OrganizationalEntity;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::BomRef;
use SBOM::CycloneDX::PostalAddress;
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

has name => (is => 'rw', isa => Str);

has address => (
    is      => 'rw',
    isa     => InstanceOf ['SBOM::CycloneDX::PostalAddress'],
    default => sub { SBOM::CycloneDX::PostalAddress->new }
);

has url => (is => 'rw', isa => ArrayLike [Str], default => sub { SBOM::CycloneDX::List->new });

has contact => (
    is      => 'rw',
    isa     => ArrayLike [InstanceOf ['SBOM::CycloneDX::OrganizationalContact']],
    default => sub { SBOM::CycloneDX::List->new }
);

sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{'bom-ref'} = $self->bom_ref if $self->bom_ref;
    $json->{name}      = $self->name    if $self->name;
    $json->{address}   = $self->address if %{$self->address->TO_JSON};
    $json->{url}       = $self->url     if @{$self->url};
    $json->{contact}   = $self->contact if @{$self->contact};

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::OrganizationalEntity - Organizational Entity

=head1 SYNOPSIS

    SBOM::CycloneDX::OrganizationalEntity->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::OrganizationalEntity> provides the organization entity object.

=head2 METHODS

L<SBOM::CycloneDX::OrganizationalEntity> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::OrganizationalEntity->new( %PARAMS )

Properties:

=over

=item C<address>, The physical address (location) of the organization

=item C<bom_ref>, An identifier which can be used to reference the object
elsewhere in the BOM. Every bom-ref must be unique within the BOM.
Value SHOULD not start with the BOM-Link intro 'urn:cdx:' to avoid
conflicts with BOM-Links.

=item C<contact>, A contact at the organization. Multiple contacts are
allowed.

=item C<name>, The name of the organization

=item C<url>, The URL of the organization. Multiple URLs are allowed.

=back

=item $organizational_entity->address

=item $organizational_entity->bom_ref

=item $organizational_entity->contact

=item $organizational_entity->name

=item $organizational_entity->url

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
