package Salvation::TC::Type::Text;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();


sub Check {
    my ( $class, $value ) = @_;
    ( ! ref( $value ) && $value ne '' ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Text', 'value' => $value );
}

sub create_length_validator {

    my ( $class, $min, $max ) = @_;

    return sub {

        my $len = length( $_[ 0 ] );

        if( ( $len < $min ) || ( defined $max && ( $len > $max ) ) ) {

            Salvation::TC::Exception::WrongType -> throw(
                'type' => sprintf( 'Text{%s,%s}', $min, ( $max // '' ) ),
                'value' => $_[ 0 ]
            );
        }

        1;
    };
}

1
__END__
