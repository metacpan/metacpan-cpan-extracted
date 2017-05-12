#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pod::POM::View::Trac' ) || print "Bail out!\n";
}

diag( "Testing Pod::POM::View::Trac $Pod::POM::View::Trac::VERSION, Perl $], $^X" );
