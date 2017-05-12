#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'Params::Registry::Types' ) || print "Bail out!\n";
    use_ok( 'Params::Registry::Template' ) || print "Bail out!\n";
    use_ok( 'Params::Registry::Instance' ) || print "Bail out!\n";
    use_ok( 'Params::Registry' ) || print "Bail out!\n";
}

diag( "Testing Params::Registry $Params::Registry::VERSION, Perl $], $^X" );
