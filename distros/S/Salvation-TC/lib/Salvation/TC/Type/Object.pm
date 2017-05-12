package Salvation::TC::Type::Object;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Scalar::Util 'blessed';
use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    blessed( $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Object', 'value' => $value );
}

1;

__END__
