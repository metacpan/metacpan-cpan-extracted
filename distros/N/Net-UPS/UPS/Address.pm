package Net::UPS::Address;

# $Id: Address.pm,v 1.5 2005/11/09 18:23:52 sherzodr Exp $


use strict;
use Carp;
use XML::Simple;
use Class::Struct;

struct(
    quality             => '$',
    city                => '$',
    postal_code         => '$',
    state               => '$',
    country_code        => '$',
    is_residential      => '$'
);




*is_exact_match = \&is_match;
sub is_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality == 1);
}


sub is_very_close_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.95);
}

sub is_close_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.90);
}

sub is_possible_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality >= 0.90);
}

sub is_poor_match {
    my $self = shift;
    return unless $self->quality();
    return ($self->quality <= 0.69);
}

sub as_hash {
    my $self = shift;
    unless ( defined $self->postal_code ) {
        croak "as_string(): 'postal_code' is empty";
    }
    my %data = (
        Address => {
            CountryCode => $self->country_code || "US",
            PostalCode  => $self->postal_code,
        }
    );
    if ( defined $self->city ) {
        $data{Address}->{City} = $self->city();
    }
    if ( defined $self->state ) {
        $data{Address}->{StateProvinceCode} = $self->state_province_code;
    }
    if ( $self->is_residential ) {
        $data{Address}->{ResidentialAddressIndicator} = undef;
    }
    return \%data;
}


sub as_XML {
    my $self = shift;
    return XMLout( $self->data, NoAttr=>1, KeepRoot=>1, SuppressEmpty=>1 )
}




sub cache_id { return $_[0]->postal_code }





sub validate {
    my $self = shift;
    my $args = shift || {};

    require Net::UPS;
    my $ups = Net::UPS->instance();
    return $ups->validate_address($self, $args);
}






1;

__END__;

=head1 NAME

Net::UPS::Address - Shipping address class

=head1 SYNOPSIS

    use Net::UPS::Address;
    $address = Net::UPS::Address->new();
    $address->city("Pittsburgh");
    $address->state("PA");
    $address->postal_code("15228");
    $address->country_code("US");
    $address->is_residential(1);

=head1 DESCRIPTION

Net::UPS::Address is a class representing a shipping address. Valid address attributes are C<city>, C<state>, C<postal_code>, C<country_code> and C<is_residential>.

If address was run through Address Validation Service, additional attribute C<quality> will be set to a floating point number between 0 and 1, inclusively, that represent the quality of match.

=head1 METHODS

In addition to accessor methods documented above, following convenience methods are provided.

=over 4

=item is_match()

=item is_very_close_match()

=item is_close_match()

=item is_possible_match()

=item is_poor_match()

When address is returned from Address Validation Service, above attributes can be consulted to find out the quality of the match. I<tolerance> threshold for the above attributes are I<0>, I<0.5>, I<0.10>, I<0.30> and I<1.0> respectively.

=item validate()

=item validate(\%args)

Validates the address by submitting itself to US Address Validation service. For this method to work Net::UPS singleton needs to be created first.

=back

=head1 AUTHOR AND LICENSING

For support and licensing information refer to L<Net::UPS|Net::UPS/"AUTHOR">

=cut
