package Hashtable;

use strict;
use warnings;
use base qw(Object);
use Array;

sub new {
    my $pkg  = shift;
    my $hash = {@_};
    return bless $hash, $pkg;
}

sub put {
    my ( $self, $key, $val ) = @_;
    $self->{$key} = $val;
    return $self;
}

sub get {
    my ( $self, $key ) = @_;
    return $self->{$key};
}

sub keys {
    my ($self) = @_;
    return new Array( keys %$self );
}

sub values {
    my ($self) = @_;
    return new Array( values %$self );
}

sub remove {
    my ( $self, $key ) = @_;
    delete $self->{$key};
    return $self;
}

sub each {
    my ( $self, $sub ) = @_;
    $self->keys->each(
        sub {
            my ($key) = @_;
            $sub->( $key, $self->get($key) );
        }
    );
    return $self;
}

1;
