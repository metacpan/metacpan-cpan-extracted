#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Miril' );
}

diag( "Testing Miril $Miril::VERSION, Perl $], $^X" );
