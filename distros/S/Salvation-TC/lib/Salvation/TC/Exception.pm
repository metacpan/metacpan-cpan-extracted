package Salvation::TC::Exception;

use strict;
use warnings;

sub new {

    my ( $self, %args ) = @_;

    return bless( \%args, ( ref( $self ) || $self ) );
}

sub throw {

    my ( $self, @rest ) = @_;

    if( ref $self ) {

        die( $self );

    } else {

        die( $self -> new( @rest ) );
    }
}

1;

__END__
