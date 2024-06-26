package Net::RDAP::JCard;
use Net::RDAP::JCard::Property;
use Net::RDAP::JCard::Address;
use strict;

=head1 NAME

L<Net::RDAP::JCard> - an object representing an RDAP jCard object.

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

Historically, the only way to access the contents of the C<vcardArray> property
of L<Net::RDAP::Object::Entity> objects was to call the C<vcard()> method and
get a L<vCard> object back, but the conversion was lossy. This module provides a
lossless and ergonomic alternative to using L<vCard>.

=head1 CONSTRUCTOR

    $jcard = Net::RDAP::JCard->new($ref);

You probably don't need to instantiate these objects yourself, but if you do,
you just need to pass an arrayref of properties.

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

Before v0.26, this method was called C<nodes()>. This name still works but is
deprecated and will be removed in the future.

=cut

sub properties {
    my ($self, $type) = @_;

    return grep { !$type || uc($type) eq uc($_->type) } @{$self->{properties}};
}

sub nodes { shift->properties(@_) }

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

Copyright 2024 Gavin Brown. All rights reserved.

=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the name of the author not be used
in advertising or publicity pertaining to distribution of the software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

1;
