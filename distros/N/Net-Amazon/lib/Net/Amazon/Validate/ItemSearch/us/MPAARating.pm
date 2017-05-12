# -*- perl -*-
# !!! DO NOT EDIT !!!
# This file was automatically generated.
package Net::Amazon::Validate::ItemSearch::us::MPAARating;

use 5.006;
use strict;
use warnings;

sub new {
    my ($class , %options) = @_;
    my $self = {
        '_default' => 'UnboxVideo',
        %options,
    };

    push @{$self->{_options}}, 'UnboxVideo';

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
    die "$value is not a valid value for us::MPAARating!\n";
}

1;

__END__

=head1 NAME

Net::Amazon::Validate::ItemSearch::us::MPAARating - valid search indices for the us locale and the MPAARating operation.

=head1 DESCRIPTION

The default value is UnboxVideo, unless mode is specified.

The list of available values are:

    UnboxVideo

=cut
