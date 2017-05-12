#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Nexmo::SMS' );
}

diag( "Testing Nexmo::SMS $Nexmo::SMS::VERSION, Perl $], $^X" );
