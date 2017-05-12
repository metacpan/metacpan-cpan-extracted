#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Package::Butcher' ) || print "Bail out!
";
}

diag( "Testing Package::Butcher $Package::Butcher::VERSION, Perl $], $^X" );
