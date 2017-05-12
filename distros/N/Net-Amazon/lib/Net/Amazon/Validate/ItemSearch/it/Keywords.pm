# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::it::Keywords;

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
    push @{$self->{_options}}, 'Baby';
    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'ForeignBooks';
    push @{$self->{_options}}, 'KindleStore';
    push @{$self->{_options}}, 'Kitchen';
    push @{$self->{_options}}, 'Lighting';
    push @{$self->{_options}}, 'Music';
    push @{$self->{_options}}, 'Shoes';
    push @{$self->{_options}}, 'Software';
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
    die "$value is not a valid value for it::Keywords!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::it::Keywords - valid search indicies
for the it locale and the Keywords SearchIndex.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    
    Baby
    Books
    DVD
    Electronics
    ForeignBooks
    KindleStore
    Kitchen
    Lighting
    Music
    Shoes
    Software
    Toys
    VideoGames
    Watches

=cut
