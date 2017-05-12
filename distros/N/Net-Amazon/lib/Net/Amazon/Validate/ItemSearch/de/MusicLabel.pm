# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::de::MusicLabel;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'Music',
        %options,
    };

    push @{$self->{_options}}, 'Classical';
    push @{$self->{_options}}, 'DVD';
    push @{$self->{_options}}, 'Music';

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
    die "$value is not a valid value for de::MusicLabel!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::de::MusicLabel - valid search indices for the de locale and the MusicLabel operation.

=head1 DESCRIPTION

The default value is Music, unless mode is specified.

The list of available values are:

    Classical
    DVD
    Music

=cut
