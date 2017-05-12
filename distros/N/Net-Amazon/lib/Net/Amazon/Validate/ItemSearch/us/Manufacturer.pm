# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::us::Manufacturer;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Software',
        %options,
    };

    push @{$self->{_options}}, 'Apparel';
    push @{$self->{_options}}, 'Automotive';
    push @{$self->{_options}}, 'Baby';
    push @{$self->{_options}}, 'Beauty';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'HealthPersonalCare';
    push @{$self->{_options}}, 'HomeGarden';
    push @{$self->{_options}}, 'Industrial';
    push @{$self->{_options}}, 'Kitchen';
    push @{$self->{_options}}, 'Merchants';
    push @{$self->{_options}}, 'MusicalInstruments';
    push @{$self->{_options}}, 'OfficeProducts';
    push @{$self->{_options}}, 'OutdoorLiving';
    push @{$self->{_options}}, 'PCHardware';
    push @{$self->{_options}}, 'PetSupplies';
    push @{$self->{_options}}, 'Photo';
    push @{$self->{_options}}, 'SilverMerchants';
    push @{$self->{_options}}, 'Software';
    push @{$self->{_options}}, 'SportingGoods';
    push @{$self->{_options}}, 'Tools';
    push @{$self->{_options}}, 'VideoGames';

    bless $self, $class;
}

sub user_or_default {
    my ($self, $user) = @_;
    if (defined $user && length($user) > 0) {    
        return $self->find_match($user);
    } 
    return $self->default();
}

sub default {
    my ($self) = @_;
    return $self->{_default};
}

sub find_match {
    my ($self, $value) = @_;
    for (@{$self->{_options}}) {
        return $_ if lc($_) eq lc($value);
    }
    die "$value is not a valid value for us::Manufacturer!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::us::Manufacturer - valid search indices for the us locale and the Manufacturer operation.

=head1 DESCRIPTION

The default value is Software, unless mode is specified.

The list of available values are:

    Apparel
    Automotive
    Baby
    Beauty
    Electronics
    HealthPersonalCare
    HomeGarden
    Industrial
    Kitchen
    Merchants
    MusicalInstruments
    OfficeProducts
    OutdoorLiving
    PCHardware
    PetSupplies
    Photo
    SilverMerchants
    Software
    SportingGoods
    Tools
    VideoGames

=cut
