package Salvation::TC::Type::Text::English;

use strict;
use warnings;

use base 'Salvation::TC::Type::Text';

use Salvation::TC::Exception::WrongType ();

my $re = qr{^[a-z0-9_\-\"\'\,\.\s\/\(\)\@\+\*\:\;\!\#\$\%\^\&\?\[\]\{\}\\]+$}i;

sub Check {

    my ( $class, $value ) = @_;

    defined( $value ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'EnglishText', 'value' => 'UNDEFINED' );
    ( $value =~ $re ) || Salvation::TC::Exception::WrongType -> throw( 'type' => 'EnglishText', 'value' => $value );
}

1
__END__
