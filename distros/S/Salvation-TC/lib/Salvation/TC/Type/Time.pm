package Salvation::TC::Type::Time;

use strict;
use warnings;

use base 'Salvation::TC::Type';

my $re = qr/^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$/;

sub Check {

    my ( $class, $time ) = @_;

    eval {

        die 'Wrong time format.' if ( ! defined( $time ) || $time !~ $re );

        my ( $hours, $minutes, $seconds ) = ( $1, $2, $3 );

        $seconds ||= '00';

        die "Hours must be bettween 0 and 23. Current value is $hours."     unless int( $hours )   >= 0 && int( $hours )   <= 23;
        die "Minutes must be bettween 0 and 23. Current value is $minutes." unless int( $minutes ) >= 0 && int( $minutes ) <= 59;
        die "Seconds must be bettween 0 and 23. Current value is $seconds." unless int( $seconds ) >= 0 && int( $seconds ) <= 59;
    };

    if( $@ ) {

        Salvation::TC::Exception::WrongType -> throw( type => 'Time', value => $time );
    };
}

1;
__END__
