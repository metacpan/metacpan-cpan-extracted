
use t::locale_hack;
use strict;
use Test;
use Statistics::Basic;

plan tests => 5;

PART1: {
    my  $stddev = new Statistics::Basic::StdDev([0, 2, 3, 4]);

    ok( $stddev->query == sqrt( 35/16 ) );

        $stddev->insert(7);
    ok( $stddev->query == sqrt( 14/4 ) );

        $stddev->set_vector([2, 3]);
    ok( $stddev->query == sqrt( 1/4 ) );

        $stddev->ginsert( 7 );
    ok( $stddev->query == sqrt( 14/3 ) );
}


PART2: {
    my  $stddev = new Statistics::Basic::StdDev;
        $stddev->set_vector([2, 3]);
    ok( $stddev->query == sqrt( 1/4 ) );
}
