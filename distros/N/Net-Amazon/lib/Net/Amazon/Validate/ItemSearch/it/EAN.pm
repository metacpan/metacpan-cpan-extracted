# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::it::EAN;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Books',
        %options,
    };

    push @{$self->{_options}}, '';
    push @{$self->{_options}}, 'Actor';
    push @{$self->{_options}}, 'Artist';
    push @{$self->{_options}}, 'AudienceRating';
    push @{$self->{_options}}, 'Author';
    push @{$self->{_options}}, 'Availability';
    push @{$self->{_options}}, 'Baby';
    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'Brand';
    push @{$self->{_options}}, 'BrowseNode';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'DeliveryMethod';
    push @{$self->{_options}}, 'Director';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'ForeignBooks';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'KindleStore';
    push @{$self->{_options}}, 'Kitchen';
    push @{$self->{_options}}, 'Lighting';
    push @{$self->{_options}}, 'Manufacturer';
    push @{$self->{_options}}, 'MaximumPrice';
    push @{$self->{_options}}, 'MerchantId';
    push @{$self->{_options}}, 'MinimumPrice';
    push @{$self->{_options}}, 'Music';
    push @{$self->{_options}}, 'MusicLabel';
    push @{$self->{_options}}, 'Power';
    push @{$self->{_options}}, 'Publisher';
    push @{$self->{_options}}, 'Shoes';
    push @{$self->{_options}}, 'Software';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'Title';
    push @{$self->{_options}}, 'Toys';
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
    die "$value is not a valid value for it::EAN!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::it::EAN - valid search indicies
for the it locale and the EAN SearchIndex.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    
    Actor
    Artist
    AudienceRating
    Author
    Availability
    Baby
    Books
    Brand
    BrowseNode
    DVD
    DeliveryMethod
    Director
    Electronics
    ForeignBooks
    Keywords
    KindleStore
    Kitchen
    Lighting
    Manufacturer
    MaximumPrice
    MerchantId
    MinimumPrice
    Music
    MusicLabel
    Power
    Publisher
    Shoes
    Software
    Sort
    Title
    Toys
    VideoGames
    Watches

=cut
