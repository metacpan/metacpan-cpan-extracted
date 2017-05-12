# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::us::Publisher;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Books',
        %options,
    };

    push @{$self->{_options}}, 'Books';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'DigitalMusic';
    push @{$self->{_options}}, 'Magazines';
    push @{$self->{_options}}, 'Merchants';
    push @{$self->{_options}}, 'SilverMerchants';
    push @{$self->{_options}}, 'UnboxVideo';
    push @{$self->{_options}}, 'VHS';
    push @{$self->{_options}}, 'Video';

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
    die "$value is not a valid value for us::Publisher!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::us::Publisher - valid search indices for the us locale and the Publisher operation.

=head1 DESCRIPTION

The default value is Books, unless mode is specified.

The list of available values are:

    Books
    DVD
    DigitalMusic
    Magazines
    Merchants
    SilverMerchants
    UnboxVideo
    VHS
    Video

=cut
