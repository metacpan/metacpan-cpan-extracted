#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Descriptive::Discrete' );
}

diag( "Testing Statistics::Descriptive::Discrete $Statistics::Descriptive::Discrete::VERSION, Perl $], $^X" );
