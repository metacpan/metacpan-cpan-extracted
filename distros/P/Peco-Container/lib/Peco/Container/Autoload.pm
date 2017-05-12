package Peco::Container::Autoload;

use strict;
use warnings;

use Carp ();

use base qw/Peco::Container/;

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ( $name ) = ( $AUTOLOAD =~ /([^:]+)$/ );
    return if $name eq 'DESTROY';
    return $self->service( $name, @_ ) if $self->contains( $name );
    Carp::croak(
        qq{Can't locate object method "$name" via package "}.ref( $self ).'"'
    );
}


1;

