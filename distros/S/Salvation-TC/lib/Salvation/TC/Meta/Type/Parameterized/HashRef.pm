package Salvation::TC::Meta::Type::Parameterized::HashRef;

=head1 NAME

Salvation::TC::Meta::Type::Parameterized::HashRef - Класс для типа параметризованного HashRef.

=cut

use strict;
use warnings;
use boolean;

use Scalar::Util 'blessed';
use base 'Salvation::TC::Meta::Type::Parameterized';

=head1 METHODS

=cut

=head2 iterate( HashRef $value, CodeRef $code )

=cut

sub iterate {

    my ( $self, $value, $code ) = @_;
    my %clone = ();

    while( my ( $key, $item ) = each( %$value ) ) {

        eval { $code -> ( $item, $key, \$clone{ $key } ) };

        if( $@ ) {

            keys( %$value ); # сбрасываем итератор
            die( $@ );
        }
    }

    return \%clone;
}

=head2 signed_type_generator()

=cut

sub signed_type_generator {

    my ( $self ) = @_;

    return $self -> { 'signed_type_generator' } //= Salvation::TC -> get( 'HashRef' ) -> signed_type_generator();
}


1;

__END__
