# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::it::Shoes;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Title',
        %options,
    };

    push @{$self->{_options}}, 'Availability';
    push @{$self->{_options}}, 'Brand';
    push @{$self->{_options}}, 'BrowseNode';
    push @{$self->{_options}}, 'Keywords';
    push @{$self->{_options}}, 'Manufacturer';
    push @{$self->{_options}}, 'MaximumPrice';
    push @{$self->{_options}}, 'MinimumPrice';
    push @{$self->{_options}}, 'Sort';
    push @{$self->{_options}}, 'Title';

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
    die "$value is not a valid value for it::Shoes!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::it::Shoes - valid search indicies
for the it locale and the Shoes SearchIndex.

=head1 DESCRIPTION

The default value is Title, unless mode is specified.

The list of available values are:

    Availability
    Brand
    BrowseNode
    Keywords
    Manufacturer
    MaximumPrice
    MinimumPrice
    Sort
    Title

=cut
