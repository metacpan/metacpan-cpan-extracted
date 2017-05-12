package Salvation::TC::Type::Ref;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ref( $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Ref', 'value' => $value );
}

1;

__END__
