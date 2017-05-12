#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Switch::Plain' ) || print "Bail out!\n";
}

diag( "Testing Switch::Plain $Switch::Plain::VERSION, Perl $], $^X" );
