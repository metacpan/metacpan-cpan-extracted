package Net::RDAP::Object::Entity;
use base qw(Net::RDAP::Object);
use strict;
use warnings;

=pod

=head1 NAME

L<Net::RDAP::Object::Entity> - a module representing an entity (person or
organization).

=head1 DESCRIPTION

L<Net::RDAP::Object::Entity> represents persons or organizations in
RDAP responses. An entity is a L<jCard object|Net::RDAP::JCard> plus metadata.

L<Net::RDAP::Object::Entity> inherits from L<Net::RDAP::Object> so has access to
all that module's methods.

Other methods include:

    @roles = $object->roles;

Returns a (potentially empty) array listing this entity's roles. The possible
values is defined by an IANA registry, see:

=over

=item * L<https://www.iana.org/assignments/rdap-json-values/rdap-json-values.xhtml>

=back

=cut

sub roles { $_[0]->{'roles'} ? @{$_[0]->{'roles'}} : () }

=pod

    my $jcard = $entity->jcard;

Returns a L<Net::RDAP::JCard> object representing the C<vcardArray> property of
the entity.

=cut

sub jcard {
    my $self = shift;
    return $self->{'vcardArray'}->[1] ? Net::RDAP::JCard->new($self->{'vcardArray'}->[1]) : undef;
}

=pod

=head2 vCard support

Suport for the L<vCard> module (via the C<vcard()> method) was removed in v0.35.

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
