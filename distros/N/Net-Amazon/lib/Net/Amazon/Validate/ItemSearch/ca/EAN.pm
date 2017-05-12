# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::ca::EAN;

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
    push @{$self->{_options}}, 'Artist';
    push @{$self->{_options}}, 'AudienceRating';
    push @{$self->{_options}}, 'Author';
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
    push @{$self->{_options}}, 'Director';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'ForeignBooks';
    push @{$self->{_options}}, 'ItemPage';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'Manufacturer';
    push @{$self->{_options}}, 'MaximumPrice';
    push @{$self->{_options}}, 'MerchantId';
    push @{$self->{_options}}, 'MinimumPrice';
    push @{$self->{_options}}, 'Music';
    push @{$self->{_options}}, 'MusicLabel';
    push @{$self->{_options}}, 'Power';
    push @{$self->{_options}}, 'Publisher';
    push @{$self->{_options}}, 'ReleaseDate';
    push @{$self->{_options}}, 'Software';
    push @{$self->{_options}}, 'SoftwareVideoGames';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'Title';
    push @{$self->{_options}}, 'VHS';
    push @{$self->{_options}}, 'Video';
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
    die "$value is not a valid value for ca::EAN!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::ca::EAN - valid search indicies
for the ca locale and the EAN SearchIndex.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    Actor
    Artist
    AudienceRating
    Author
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
    Director
    Electronics
    ForeignBooks
    ItemPage
    Keywords
    Manufacturer
    MaximumPrice
    MerchantId
    MinimumPrice
    Music
    MusicLabel
    Power
    Publisher
    ReleaseDate
    Software
    SoftwareVideoGames
    Sort
    Title
    VHS
    Video
    VideoGames

=cut
