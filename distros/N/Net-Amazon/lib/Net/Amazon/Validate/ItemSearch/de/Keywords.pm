# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::de::Keywords;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Books',
        %options,
    };

    push @{$self->{_options}}, 'Apparel';
    push @{$self->{_options}}, 'Automotive';
    push @{$self->{_options}}, 'Baby';
    push @{$self->{_options}}, 'Beauty';
    push @{$self->{_options}}, 'Blended';
    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'Classical';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'ForeignBooks';
    push @{$self->{_options}}, 'HealthPersonalCare';
    push @{$self->{_options}}, 'HomeGarden';
    push @{$self->{_options}}, 'Jewelry';
    push @{$self->{_options}}, 'Kitchen';
    push @{$self->{_options}}, 'MP3Downloads';
    push @{$self->{_options}}, 'Magazines';
    push @{$self->{_options}}, 'Music';
    push @{$self->{_options}}, 'MusicTracks';
    push @{$self->{_options}}, 'OfficeProducts';
    push @{$self->{_options}}, 'OutdoorLiving';
    push @{$self->{_options}}, 'PCHardware';
    push @{$self->{_options}}, 'Photo';
    push @{$self->{_options}}, 'Software';
    push @{$self->{_options}}, 'SoftwareVideoGames';
    push @{$self->{_options}}, 'SportingGoods';
    push @{$self->{_options}}, 'Tools';
    push @{$self->{_options}}, 'Toys';
    push @{$self->{_options}}, 'VHS';
    push @{$self->{_options}}, 'Video';
    push @{$self->{_options}}, 'VideoGames';
    push @{$self->{_options}}, 'Watches';

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
    die "$value is not a valid value for de::Keywords!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::de::Keywords - valid search indicies
for the de locale and the Keywords SearchIndex.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    Apparel
    Automotive
    Baby
    Beauty
    Blended
    Books
    Classical
    DVD
    Electronics
    ForeignBooks
    HealthPersonalCare
    HomeGarden
    Jewelry
    Kitchen
    MP3Downloads
    Magazines
    Music
    MusicTracks
    OfficeProducts
    OutdoorLiving
    PCHardware
    Photo
    Software
    SoftwareVideoGames
    SportingGoods
    Tools
    Toys
    VHS
    Video
    VideoGames
    Watches

=cut
