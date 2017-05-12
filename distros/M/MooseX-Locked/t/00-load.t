#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Locked' ) || print "Bail out!\n";
}

diag( "Testing MooseX::Locked $MooseX::Locked::VERSION, Perl $], $^X" );
