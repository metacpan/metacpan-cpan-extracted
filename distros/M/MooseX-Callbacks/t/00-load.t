#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Callbacks' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Callbacks $MooseX::Callbacks::VERSION, Perl $], $^X" );
