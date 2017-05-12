package Salvation::TC::Type::CodeRef;

use strict;
use warnings;

use base 'Salvation::TC::Type::Ref';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ( ref( $value ) eq 'CODE' ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'CodeRef', 'value' => $value );
}

1;

__END__
