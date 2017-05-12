#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Regexp::Keywords' );
}

diag( "Testing Regexp::Keywords $Regexp::Keywords::VERSION, Perl $], $^X" );
