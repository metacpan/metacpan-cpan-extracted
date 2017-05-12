#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'OAuth::Simple' ) || print "Bail out!\n";
}

diag( "Testing OAuth::Simple $OAuth::Simple::VERSION, Perl $], $^X" );
