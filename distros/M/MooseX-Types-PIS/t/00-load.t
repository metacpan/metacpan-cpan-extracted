#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MooseX::Types::PIS' ) || print "Bail out!
";
}

diag( "Testing MooseX::Types::PIS $MooseX::Types::PIS::VERSION, Perl $], $^X" );
