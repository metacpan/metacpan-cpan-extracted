#! /usr/bin/env perl

use Test::More 0.88;

use Class::C3;
use MRO::Compat;

BEGIN {
        use_ok( 'Tapper::Reports::DPath' );
        use_ok( 'Tapper::Reports::DPath::Mason' );
        use_ok( 'Tapper::Reports::DPath::TT' );
}

# there were some eval problems
is(Tapper::Reports::DPath::_dummy_needed_for_tests(), 12345, 'eval works');

done_testing;
