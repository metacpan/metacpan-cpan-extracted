package Net::RDAP::JCard::Property;
use List::Util qw(any);
use strict;
use warnings;

my @URI_TYPES = qw(source logo member related sound uid uri caladruri caluri contact-uri socialprofile impp url email);

=pod

=head1 NAME

L<Net::RDAP::JCard::Property> - a module representing a property of a
L<Net::RDAP::JCard> object.

=head1 SYNOPSIS

    #
    # get a property by calling the properties() method on a Net::RDAP::JCard
    # object
    #
    $prop = [ $jcard->properties('tel') ]->[0];

    say $prop->param('type');
    say $prop->value;

=head1 DESCRIPTION

The data in a jCard (L<RFC 7095|https://www.rfc-editor.org/rfc/rfc7095.html>)
object is stored in a set of I<properties>, which this module represents.

Properties have exactly four elements, specifically:

=over

=item 1. the I<type>, which is a string such as C<fn> (full name) or C<email>
(email address);

=item 2. I<parameters>, which are represented as a hashref;

=item 3. a I<value type>, which is a string such as C<text> or C<URI>;

=item 4. the I<value>, which can be a string or arrayref.

=back

L<Net::RDAP::JCard::Property> provides an ergonomic way to access these
elements.

=head1 CONSTRUCTOR

    $prop = Net::RDAP::JCard::Property->new($ref);

You probably don't need to instantiate these objects yourself, but if you do,
you just need to pass an arrayref containing the type, parameters, value type
and value.

=cut

sub new {
    my ($package, $arrayref) = @_;

    my $self = {
        type        => $arrayref->[0],
        params      => $arrayref->[1],
        value_type  => $arrayref->[2],
        value       => $arrayref->[3],
    };

    return bless($self, $package);
}

=pod

=head1 NOTE ON CASE SENSITIVITY

In general, most values in vCard objects are case-insensitive, however, the
L<jCard RFC|https://datatracker.ietf.org/doc/html/rfc7095> requires that
property and value types be lowercase.

L<Net::RDAP::JCard::Property> will internally preserve the case of property and
value types so that JSON serialization via the C<TO_JSON()> method will return
the original data structure.

Please see the documentation for each of the methods listed below to see how
case is handled for those methods.

=head1 METHODS

=head2 PROPERTY TYPE

    $type = $prop->type;

Returns a string containing the property type. See the L<vCard
Properties|https://www.iana.org/assignments/vcard-elements/vcard-elements.xhtml#properties>
IANA registry for a list of possible values.

This method will always return the property type in lowercase.

=head2 PROPERTY PARAMETERS

    $params = $prop->params;

Returns a hashref containing the property parameters. See the C<vCard
Parameters|https://www.iana.org/assignments/vcard-elements/vcard-elements.xhtml#parameters>
IANA registry for a list of possible parameter names.

The keys of this hashref will always be in lowercase as per L<Section 3.4 of
RFC 7095|https://datatracker.ietf.org/doc/html/rfc7095#section-3.4>.

    $param = $prop->param($name);

Returns the value of the C<$name> parameter or C<undef>. C<$name> will be matched
case-insensitively against the keys in the hashref.

=head2 PROPERTY VALUE TYPE

    $value_type = $prop->value_type;

Returns a string containing the property value type. See the L<vCard Value Data
Types|https://www.iana.org/assignments/vcard-elements/vcard-elements.xhtml#value-data-types>
IANA registry for a list of possible values.

This method will always return the value type in lowercase.

=head2 URIness

Some properties may be URIs, depending on the property type and value type. The
C<may_be_uri()> method will return a true value if the property value may be a
URI (either because of the specification of its type, or the value of its
C<value_type()>.

=head2 PROPERTY VALUE

    $value = $prop->value;

Returns the property value.

=cut

sub type { lc($_[0]->{type}) }

sub params {
    my $self = shift;
    my $params = {};

    foreach my $k (keys(%{$self->{params}})) {
        $params->{lc($k)} = $self->{params}->{$k};
    }

    return $params;
}

sub param       { $_[0]->params->{lc($_[1])} }
sub value_type  { lc($_[0]->{value_type}) }
sub value       { $_[0]->{value} }

sub TO_JSON {
    my $self = shift;

    return [
        $self->type,
        $self->params,
        $self->value_type,
        $self->value,
    ];
}

sub may_be_uri {
    my $self = shift;
    if (q{uri} eq $self->value_type) {
        return 1;

    } elsif (any { $_ eq $self->type } @URI_TYPES) {
        return 1;

    }

    return undef;
}

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
