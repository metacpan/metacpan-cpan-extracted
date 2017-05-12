package Salvation::TC::Type::Defined;

use strict;
use warnings;

use base 'Salvation::TC::Type';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ( defined $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Defined', 'value' => $value );
}


1;

__END__
