package Net::UPS::Address;
$Net::UPS::Address::VERSION = '0.16';
{
  $Net::UPS::Address::DIST = 'Net-UPS';
}
use strict;
use warnings;
use Carp;
use XML::Simple;
use Class::Struct 0.58;

struct(
    quality             => '$',
    name                => '$',
    building_name       => '$',
    address             => '$',
    address2            => '$',
    address3            => '$',
    city                => '$',
    postal_code         => '$',
    postal_code_extended => '$',
    state               => '$',
    country_code        => '$',
    is_residential      => '$',
    is_commercial       => '$',
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
    my $shape = shift || 'AV';

    unless ( defined $self->postal_code ) {
        croak "as_string(): 'postal_code' is empty";
    }

    # internal validation; this should be in the constructor, but
    # we're stuck with Class::Struct for the time being...
    if ( defined $self->state && length($self->state) != 2 ) {
        croak "'state' has to be two letters long";
    }
    if ( defined $self->country_code && length($self->country_code) != 2 ) {
        croak "'country_code' has to be two letters long";
    }
    my $postal_code = $self->postal_code;
    if ($postal_code =~ /(\d+)-(\d+)/) {
        $self->postal_code($1);
        unless ($self->postal_code_extended) {
            $self->postal_code_extended($2);
        }
    }

    my %data;

    if ($shape eq 'AV') {
        %data = (
            Address => {
                CountryCode => $self->country_code || "US",
                PostalCode  => $self->postal_code,
            }
        );
        if ( defined $self->city ) {
            $data{Address}->{City} = $self->city();
        }
        if ( defined $self->state ) {
            $data{Address}->{StateProvinceCode} = $self->state;
        }
        if ( $self->is_residential ) {
            $data{Address}->{ResidentialAddressIndicator} = undef;
        }
    }
    elsif ($shape eq 'XAV') {
        %data = (
            AddressKeyFormat => {
                CountryCode => $self->country_code || "US",
                PostcodePrimaryLow  => $self->postal_code,
            }
        );

        if ( defined $self->name ) {
            $data{AddressKeyFormat}->{ConsigneeName} = $self->name();
        }

        if ( defined $self->building_name ) {
            $data{AddressKeyFormat}->{BuildingName} = $self->building_name();
        }

        $data{AddressKeyFormat}->{AddressLine} = [];

        if ( defined $self->address ) {
            push(@{ $data{AddressKeyFormat}->{AddressLine} }, $self->address());
        }

        if ( defined $self->address2 ) {
            push(@{ $data{AddressKeyFormat}->{AddressLine} }, $self->address2());
        }

        if ( defined $self->address3 ) {
            push(@{ $data{AddressKeyFormat}->{AddressLine} }, $self->address3());
        }

        if ( defined $self->city ) {
            $data{AddressKeyFormat}->{PoliticalDivision2} = $self->city();
        }

        if ( defined $self->state ) {
            $data{AddressKeyFormat}->{PoliticalDivision1} = $self->state();
        }

        if ( defined $self->postal_code_extended ) {
            $data{AddressKeyFormat}->{PostcodeExtendedLow} = $self->postal_code_extended;
        }
    }
    else {
        croak "parameter to as_hash should be AV or XAV, not $shape";
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

sub validate_street_level {
    my $self = shift;
    my $args = shift || {};

    require Net::UPS;
    my $ups = Net::UPS->instance();
    return $ups->validate_street_address($self, $args);
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
