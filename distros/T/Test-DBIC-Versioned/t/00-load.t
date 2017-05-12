#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::DBIC::Versioned' ) || print "Bail out!\n";
}

diag( "Testing Test::DBIC::Versioned $Test::DBIC::Versioned::VERSION, Perl $], $^X" );
