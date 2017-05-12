package Salvation::TC::Type::Number::Float;

use strict;
use base 'Salvation::TC::Type::Number';

use Salvation::TC::Exception::WrongType ();

my $re = qr/^[-+]?\d*\.?(\d+)?$/;

sub Check {

    my ( $class, $value ) = @_;

    defined( $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Float', 'value' => 'UNDEFINED' );
    $value =~ $re || Salvation::TC::Exception::WrongType -> throw( 'type' => 'Number::Float', 'value' => $value );
}

1
__END__
