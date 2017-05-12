package Salvation::TC::Type::ScalarRef;

use strict;
use warnings;

use base 'Salvation::TC::Type::Ref';

use Salvation::TC::Exception::WrongType ();
use Salvation::TC::Exception::WrongType::TC ();


sub Check {

    my ( $class, $value ) = @_;

    ( ref( $value ) eq 'SCALAR' )
    || ( ref( $value ) eq 'REF' )
    || Salvation::TC::Exception::WrongType -> throw( 'type' => 'ScalarRef', 'value' => $value );
}

1;

__END__
