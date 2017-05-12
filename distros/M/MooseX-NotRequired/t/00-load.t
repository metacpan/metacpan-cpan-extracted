#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::NotRequired' ) || print "Bail out!\n";
}

diag( "Testing MooseX::NotRequired $MooseX::NotRequired::VERSION, Perl $], $^X" );
