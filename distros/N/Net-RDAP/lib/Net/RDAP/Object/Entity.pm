package Net::RDAP::Object::Entity;
use base qw(Net::RDAP::Object);
use vCard;
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

    $vcard = $entity->vcard;

Returns a L<vCard> object for the entity. Only the C<fn>, C<org>, C<email>,
C<tel> and C<adr> property types (structured addresses only) are supported. This
method is B<DEPRECATED>.

=cut

sub vcard {
    my $self = shift;

    return undef unless ($self->{'vcardArray'});

    my @emails;
    my @phones;
    my @addresses;

    my $card = vCard->new;

    foreach my $nref (@{$self->{'vcardArray'}->[1]}) {
        my ($type, $params, $vtype, $value) = @{$nref};

        if ('fn' eq $type) {
            $card->full_name($value);

        } elsif ('org' eq $type) {
            $card->organization($value);

        } elsif ('email' eq $type) {
            push(@emails, $value);

        } elsif ('tel' eq $type) {
            push(@phones, {
                'type'      => [$params->{'type'}],
                'number'    => $value
            });

        } elsif ('adr' eq $type) {
            $value->[6] = $value->[6] || $params->{'cc'},

            push(@addresses, {
                'type'      => [$params->{'type'}],
                'address'   => $value
            });
        }
    }

    $card->email_addresses([ map { { 'address' => $_ } } @emails ]);
    $card->phones(\@phones);
    $card->addresses(\@addresses);

    return $card;
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
