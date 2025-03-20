package Net::RDAP::JCard::Address;
use List::Util qw(any);
use base qw(Net::RDAP::JCard::Property);
use strict;
use warnings;

=pod

=head1 NAME

Net::RDAP::JCard::Address - a module representing a postal address in a
L<Net::RDAP::JCard> object.

=head1 SYNOPSIS

    #
    # get an object by calling the jcard() method on a Net::RDAP::Object::Entity
    #
    my $jcard = $entity->jcard;

    #
    # get the first address. You can also uses $jcard->addresses() to get all
    # ADR properties.
    #
    my $adr = $jcard->first_address;

    if ($adr->structured) {
        #
        # This is a structured address so we can extract the individual components:
        #

        map { say "Street: ".$_ } @{$adr->street};
        say "Locality: ".$adr->locality;
        say "Region: ".$adr->region;
        say "Postal Code: ".$adr->code;
        say "Country: ".($adr->cc || $adr->country);

    } else {
        #
        # This is an unstructured address, so just print it:
        #
        say "Address:".$adr->address;

    }

=head1 DESCRIPTION

The L<vCard|https://www.rfc-editor.org/rfc/rfc6350.html#section-6.3.1> and
L<jCard|https://datatracker.ietf.org/doc/html/rfc7095#section-3.3.1.3>
representations of postal address data can be quite difficult to deal with, and
often cause difficulties.

L<Net::RDAP::JCard::Address> provides an ergonomic interface to C<ADR> properties
in jCard objects.

To get a L<Net::RDAP::JCard::Address>, use the C<first_address()> or C<addresses()>
methods of L<Net::RDAP::JCard> to get an array of address objects.

=head1 METHODS

L<Net::RDAP::JCard::Address> inherits from L<Net::RDAP::JCard::Property>, and
therefore inherits all that module's methods, in addition to the following:

=head2 ADDRESS TYPE

    $structured = $adr->structured;

Returns true if the address is "structured" (see L<Section 3.3.1.3 of RFC
7095|https://datatracker.ietf.org/doc/html/rfc7095#section-3.3.1.3>).

=cut

sub structured {
    my $self = shift;

    return ('ARRAY' eq ref($self->value) && any { length > 0 } @{$self->value});
}

=pod

=head2 FLAT ADDRESS

    say $adr->address;

Returns a multi-line text string containing the address. For "unstructured"
addresses, this is the only format available, and is therefore the simplest
way to display the address information.

=cut

sub address {
    my $self = shift;
    if ($self->structured) {
        return join("\n", grep { length > 0 } (
            $self->pobox,
            $self->extended,
            @{$self->street},
            $self->locality,
            $self->region,
            $self->code,
            $self->cc || $self->country
        ));

    } else {
        return $self->param('label');

    }
}

=pod

=head2 P.O. BOX NUMBER

    say $adr->pobox;

Returns the Post Office box number, or C<undef>.

=cut

sub pobox { shift->value->[0] }

=pod

=head2 EXTENDED ADDRESS

    say $adr->extended;

Returns the "extended" address component, such as the apartment or suite number, or C<undef>.

=cut

sub extended { shift->value->[1] }

=pod

=head2 STREET ADDRESS

    map { say $_ } @{$adr->street};

Some structured addresses have a single street address, but some have multiple
street addresses which are represented as an arrayref.

This method will always return an arrayref, which may contain zero, one, or
many values.

=cut

sub street {
    my $self = shift;
    my $street = $self->value->[2];

    return ('ARRAY' eq ref($street) ? $street : [$street]);
}

=pod

=head2 LOCALITY

    say $adr->locality;

Returns the locality, or C<undef>.

=cut

sub locality { shift->value->[3] }

=pod

=head2 REGION

    say $adr->region;

Returns the region, or C<undef>.

=cut

sub region { shift->value->[4] }

=pod

=head2 POSTAL CODE

    say $adr->code;

Returns the postal code, or C<undef>.

=cut

sub code { shift->value->[5] }

=pod

=head2 COUNTRY CODE

    say $adr->cc;

Returns the ISO-3166-alpha2 country code (see L<Section 3.1 of RFC
8605|https://www.rfc-editor.org/rfc/rfc8605.html#section-3.1>), or C<undef>.

=cut

sub cc { shift->param('cc') }

=pod

=head2 COUNTRY NAME

    say $adr->country;

Returns the country name, or C<undef>.

=cut

sub country { shift->value->[6] }

=pod

=head1 COPYRIGHT

Copyright 2018-2023 CentralNic Ltd, 2024-2025 Gavin Brown. For licensing information,
please see the C<LICENSE> file in the L<Net::RDAP> distribution.

=cut

1;
