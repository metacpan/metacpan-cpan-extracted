package Peco::Container::Chained;

use strict;

use base qw/Peco::Container/;

sub new {
    my ( $class, $parent ) = @_;
    my $self = $class->SUPER::new();

    $parent ||= Peco::Container->new;
    $self->{parent} = $parent;

    bless $self, $class;
    $self;
}

sub keys {
    my $self = shift;
    return ( $self->SUPER::keys, $self->parent->keys );
}

sub parent { shift->{parent} }

sub service {
    my ( $self, $key, %seen ) = @_;
    if ( $self->contains( $key ) ) {
        return $self->SUPER::service( $key, %seen );
    } else {
        return $self->{parent}->service( $key, %seen );
    }
}

1;
