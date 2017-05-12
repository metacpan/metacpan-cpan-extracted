package Salvation::TC::Type::Bool;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ( ! defined( $value ) || ( $value eq '' ) || ( $value eq '1' ) || ( $value eq '0' ) )
        || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Bool', 'value' => $value );
}


1;

__END__
