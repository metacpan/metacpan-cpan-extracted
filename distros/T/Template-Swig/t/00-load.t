#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::Swig' ) || print "Bail out!\n";
}

diag( "Testing Template::Swig $Template::Swig::VERSION, Perl $], $^X" );
