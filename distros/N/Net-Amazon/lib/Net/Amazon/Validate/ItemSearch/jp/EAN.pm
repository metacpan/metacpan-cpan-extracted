# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::jp::EAN;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Books',
        %options,
    };

    push @{$self->{_options}}, 'Actor';
    push @{$self->{_options}}, 'Apparel';
    push @{$self->{_options}}, 'Appliances';
    push @{$self->{_options}}, 'Artist';
    push @{$self->{_options}}, 'AudienceRating';
    push @{$self->{_options}}, 'Author';
    push @{$self->{_options}}, 'Automotive';
    push @{$self->{_options}}, 'Availability';
    push @{$self->{_options}}, 'Baby';
    push @{$self->{_options}}, 'Beauty';
    push @{$self->{_options}}, 'Blended';
    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'Brand';
    push @{$self->{_options}}, 'BrowseNode';
    push @{$self->{_options}}, 'Classical';
    push @{$self->{_options}}, 'Composer';
    push @{$self->{_options}}, 'Condition';
    push @{$self->{_options}}, 'Conductor';
    push @{$self->{_options}}, 'Count';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'DeliveryMode';
    push @{$self->{_options}}, 'Director';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'ForeignBooks';
    push @{$self->{_options}}, 'Format';
    push @{$self->{_options}}, 'Grocery';
    push @{$self->{_options}}, 'HealthPersonalCare';
    push @{$self->{_options}}, 'Hobbies';
    push @{$self->{_options}}, 'HomeImprovement';
    push @{$self->{_options}}, 'ItemPage';
    push @{$self->{_options}}, 'Jewelry';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'Kitchen';
    push @{$self->{_options}}, 'MP3Downloads';
    push @{$self->{_options}}, 'Magazines';
    push @{$self->{_options}}, 'Manufacturer';
    push @{$self->{_options}}, 'Marketplace';
    push @{$self->{_options}}, 'MaximumPrice';
    push @{$self->{_options}}, 'MerchantId';
    push @{$self->{_options}}, 'MinimumPrice';
    push @{$self->{_options}}, 'Music';
    push @{$self->{_options}}, 'MusicLabel';
    push @{$self->{_options}}, 'MusicTracks';
    push @{$self->{_options}}, 'MusicalInstruments';
    push @{$self->{_options}}, 'OfficeProducts';
    push @{$self->{_options}}, 'Orchestra';
    push @{$self->{_options}}, 'Performer';
    push @{$self->{_options}}, 'Power';
    push @{$self->{_options}}, 'Publisher';
    push @{$self->{_options}}, 'Shoes';
    push @{$self->{_options}}, 'Software';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'SportingGoods';
    push @{$self->{_options}}, 'Title';
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
    die "$value is not a valid value for jp::EAN!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::jp::EAN - valid search indicies
for the jp locale and the EAN SearchIndex.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    Actor
    Apparel
    Appliances
    Artist
    AudienceRating
    Author
    Automotive
    Availability
    Baby
    Beauty
    Blended
    Books
    Brand
    BrowseNode
    Classical
    Composer
    Condition
    Conductor
    Count
    DVD
    DeliveryMode
    Director
    Electronics
    ForeignBooks
    Format
    Grocery
    HealthPersonalCare
    Hobbies
    HomeImprovement
    ItemPage
    Jewelry
    Keywords
    Kitchen
    MP3Downloads
    Magazines
    Manufacturer
    Marketplace
    MaximumPrice
    MerchantId
    MinimumPrice
    Music
    MusicLabel
    MusicTracks
    MusicalInstruments
    OfficeProducts
    Orchestra
    Performer
    Power
    Publisher
    Shoes
    Software
    Sort
    SportingGoods
    Title
    Toys
    VHS
    Video
    VideoGames
    Watches

=cut
