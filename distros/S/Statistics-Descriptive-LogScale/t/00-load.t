#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Descriptive::LogScale' ) || print "Bail out!\n";
}

diag( "Testing Statistics::Descriptive::LogScale $Statistics::Descriptive::LogScale::VERSION, Perl $], $^X" );
