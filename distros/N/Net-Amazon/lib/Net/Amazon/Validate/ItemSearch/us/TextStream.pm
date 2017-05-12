# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::us::TextStream;

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
    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'Electronics';
    push @{$self->{_options}}, 'GourmetFood';
    push @{$self->{_options}}, 'Jewelry';
    push @{$self->{_options}}, 'Merchants';
    push @{$self->{_options}}, 'Photo';
    push @{$self->{_options}}, 'SilverMerchants';
    push @{$self->{_options}}, 'Toys';
    push @{$self->{_options}}, 'UnboxVideo';
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
    die "$value is not a valid value for us::TextStream!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::us::TextStream - valid search indices for the us locale and the TextStream operation.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    Apparel
    Automotive
    Books
    Electronics
    GourmetFood
    Jewelry
    Merchants
    Photo
    SilverMerchants
    Toys
    UnboxVideo
    VideoGames

=cut
