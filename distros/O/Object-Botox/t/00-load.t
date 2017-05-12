#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Object::Botox' ) || print "Bail out!\n";
}

diag( "Testing Object::Botox $Object::Botox::VERSION, Perl $], $^X" );
