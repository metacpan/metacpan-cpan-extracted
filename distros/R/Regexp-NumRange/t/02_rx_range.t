#!perl -T

use strict;
use warnings;
use lib ();
use Test::More;

use Regexp::NumRange qw/rx_range/;

my @cases = (
    [ 0,    9 ],       # pass to rx_max
    [ 0,    255 ],     # pass to rx_max
    [ 51,   201 ],     # 1 digit diff
    [ 73,   523 ],     # 1 digit diff; 100-500 case
    [ 41,   1024 ],    # 2 digit; 1 end case middle
    [ 2,    5927 ],    # different end range
    [ 10,   9999 ],    # large end range; 2 diff
    [ 2,    9987 ],    # large end ranges; 3 diff
    [ 50,   101 ],     # 0 edge cases in middle; offset 1
    [ 50,   100 ],     # 0 edge cases in middle
    [ 27,   32 ],      # same number of digis; 1 first diff
    [ 17,   52 ],      # same number of digits; 1> first diff
    [ 22,   28 ],      # same number of digits; same first
    [ 15,   2 ],       # reverse the start and end
    [ 150,  2000 ],    # 3 digit start
    [ 1234, 4321 ],
    [ 9999, 9998 ]
);

foreach my $c (@cases) {
    my ( $s, $e ) = ( $c->[0], $c->[1] );

    my @tests = ( $s - 1, $s + 0, $s + 1, $e - 1, $e + 0, $e + 1 );
    push @tests, int( ( $s + $e ) / 2 );
    my $d = 10 * $e + 11;
    while ( $d > 1 ) {
        push @tests, $d;
        $d = int( $d / 10 );
    }

    my $rxs = rx_range( $s, $e );
    my $rx = qr/^$rxs$/;

    # correct order after submission to rx_range
    ( $s, $e ) = ( $e, $s ) if $e < $s;

    foreach my $t (@tests) {
        $t = int($t);
        next unless $t >= 0;
        my $match = $t =~ $rx;
        if ( $s <= $t && $t <= $e ) {
            like $t, $rx, "$s <= $t <= $e; $t should match: $rxs";
        }
        else {
            unlike $t, $rx, "$s <= $t <= $e; $t should not match: $rxs";
        }
    }
}

# TODO: Remove notes:

#rx_range( 0, 9 );       # [0-9]
#rx_range( 2, 5927 );    # 0?[2-9]|[1-9][0-9]{2}|[1-9][0-9]{2}
#rx_range(2,9987);  # 0?[2-9]|[1-9][0-9]{2}|[1-9][0-9]{2}
#rx_range( 41, 1024 );    # 4[1-9]|[5-9][0-9]|[1-9][0-9]{2}|10[0-1][0-9]|102[0-4]
#rx_range( 51, 201 );     # 5[1-9]|[6-9][0-9]|1[0-9]{2}|20[0-1]
#rx_range(50,100);  # 5[0-9]|[6-9][0-9]|100
#rx_range( 27, 32 );      # 2[7-9]|3[0-2]
#rx_range( 17, 52 );      # 1[7-9]|[2-4][0-9]|5[0-2]
#rx_range( 22, 28 );      # 2[2-8]
#rx_range( 15, 2 );       # 0?[2-9]|1[0-5]
#rx_range( 150, 2000 );

done_testing();

