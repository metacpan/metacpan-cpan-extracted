#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::DiffBot' ) || print "Bail out!\n";
}

diag( "Testing Net::DiffBot $Net::DiffBot::VERSION, Perl $], $^X" );
