package Net::RDAP::JCard;
use Carp;
use Net::RDAP::JCard::Property;
use Net::RDAP::JCard::Address;
use strict;
use warnings;

=head1 NAME

L<Net::RDAP::JCard> - a module representing an RDAP jCard object.

=head1 SYNOPSIS

    #
    # get an object by calling the jcard() method on a Net::RDAP::Object::Entity
    #
    my $jcard = $entity->jcard;

    my $fn = [ $jcard->properties('fn') ]->[0];

    say $fn->value;

=head1 DESCRIPTION

This module provides a representation of jCard properties, as described in
L<RFC 7095|https://www.rfc-editor.org/rfc/rfc7095.html>.

=head1 CONSTRUCTOR

    $jcard = Net::RDAP::JCard->new($ref);

You probably don't need to instantiate these objects yourself, but if you do,
you just need to pass an arrayref of properties (which are themelves arrayrefs).

=cut

sub new {
    my ($package, $arrayref) = @_;

    my $self = {
        properties => [map { Net::RDAP::JCard::Property->new($_) } @{$arrayref}],
    };

    return bless($self, $package);
}

=pod

=head1 METHODS

    @properties = $jcard->properties;

    @properties = $jcard->properties($type);

Returns a (potentially empty) array of L<Net::RDAP::JCard::Property> objects,
optionally filtered to just those that have the C<$type> type (matched
case-insensitively).

=cut

sub properties {
    my ($self, $type) = @_;
    return grep { !$type || uc($type) eq uc($_->type) } @{$self->{properties}};
}

=pod

    $property = $jcard->first('fn');

Returns the first property matching the provided type, or C<undef> if none was
found.

=cut

sub first {
    return [ shift->properties(@_) ]->[0];
}

=pod

    @addresses = $jcard->addresses;

Returns a (potentially empty) array of L<Net::RDAP::JCard::Address> objects,
representing the C<adr> properties of the jCard object.

    $address = $jcard->first_address;

Returns a L<Net::RDAP::JCard::Address> object representing the first address
found, or C<undef>.

=cut

sub addresses {
    return map { Net::RDAP::JCard::Address->new([$_->type, $_->params, $_->value_type, $_->value]) } shift->properties('adr');
}

sub first_address {
    my $self = shift;
    my $adr = $self->first('adr');

    return ($adr ? Net::RDAP::JCard::Address->new([$adr->type, $adr->params, $adr->value_type, $adr->value]) : undef);
}

sub TO_JSON { ['vcard', shift->{properties}] }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
