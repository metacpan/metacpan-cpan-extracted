package Peco::Container::Clonable;

use strict;
use base qw/Peco::Container/;

sub clone {
    my ( $self, $deep ) = @_;
    my $copy = ref( $self )->new;
    $copy->{specs} = { %{ $self->specs } };
    return $copy unless $deep;
    $copy->{state} = { %{ $self->state } };
    return $copy;
}

1;
