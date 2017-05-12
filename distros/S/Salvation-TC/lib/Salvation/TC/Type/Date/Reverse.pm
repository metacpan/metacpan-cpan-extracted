package Salvation::TC::Type::Date::Reverse;

use strict;
use warnings;

use base 'Salvation::TC::Type::Date';

use Salvation::TC::Exception::WrongType ();

my $re = qr/^(\d{4})[\.\/\-](\d{1,2})[\.\/\-](\d{1,2})\s*(\d+:\d+(:\d+)*?)?$/;

sub Check {

    my ( $class, $date ) = @_;

    eval {

        die "Wrong date format. Expected year[.-/]month[./-]day time" if ( ! defined( $date ) || $date !~ $re );

        my ( $year, $month, $day, $time ) = ( $1, $2, $3, $4 );

        $class->SUPER::Check( "$day.$month.$year $time" );
    };

    if( $@ ) {

        Salvation::TC::Exception::WrongType -> throw( type => 'Date::Reverse', value => $date );
    };
}

1;
__END__
