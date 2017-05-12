package Salvation::TC::Type::Number::Integer;

use strict;
use warnings;

use base 'Salvation::TC::Type::Number';

use Salvation::TC::Exception::WrongType ();

my $re = qr/^[-+]?\d+$/;

sub Check {

    my ( $class, $value ) = @_;

    defined( $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Integer', 'value' => 'UNDEFINED' );
    ( $value =~ $re ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Number::Integer', 'value' => $value );
}

1;
__END__
