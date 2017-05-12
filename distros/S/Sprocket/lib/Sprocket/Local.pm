package Sprocket::Local;

use warnings;
use strict;

use Sprocket qw( Local::Connection );
use Carp qw( croak );

use vars qw( $sprocket_local );

sub import {
    my ( $class, $args ) = @_;
    my $package = caller();

    croak "Sprocket::Local expects its arguments in a hash ref"
        if ( $args && ref( $args ) ne 'HASH' );

    unless ( delete $args->{no_auto_export} ) {
        {
            no strict 'refs';
            *{ $package . '::sprocket_local' } = \$sprocket_local;
        }
    }

    return if ( delete $args->{no_auto_bootstrap} );

    # bootstrap
    Sprocket::Local->new( %$args );
    
    return;
}

sub new {
    return $sprocket_local if ( $sprocket_local );
    my $class = shift;
    
    my $self = $sprocket_local = bless({
        @_,
        pak => { }, # hash of hashes, packages => ids => objects
    }, ref $class || $class );
    
    return $self;
}

sub new_connection {
    my ( $self, $obj, $id ) = @_;
    
    my $con = $self->{pak}->{$obj}->{$id} =
    Sprocket::Local::Connection->new(
#        parent_id => $self->{session_id},
        __parent_plugin => $obj,
        __id => $id,
    );

    return $con;
}

sub get_connection {
    my ( $self, $obj, $id ) = @_;
    my $pk = $self->{pak}->{ $obj };
    return ( $pk && $pk->{ $id } ) ? $pk->{ $id } : $self->new_connection( $obj, $id );
}

1;

