#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Descriptive' );
}

diag( "Testing Statistics::Descriptive $Statistics::Descriptive::VERSION, Perl $], $^X" );
