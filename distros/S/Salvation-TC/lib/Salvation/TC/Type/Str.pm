package Salvation::TC::Type::Str;

use strict;
use warnings;

use base 'Salvation::TC::Type::Text';

use Salvation::TC::Exception::WrongType ();


sub Check {

    my ( $class, $value ) = @_;

    ( defined $value && ! ref $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Str', 'value' => $value );
}


1;

__END__
