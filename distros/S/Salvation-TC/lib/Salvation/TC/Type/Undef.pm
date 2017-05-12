package Salvation::TC::Type::Undef;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ( ! defined $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Undef', 'value' => $value );
}


1;

__END__
