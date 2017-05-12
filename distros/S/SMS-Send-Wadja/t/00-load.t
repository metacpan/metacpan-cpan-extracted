#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::Wadja' );
}

diag( "Testing SMS::Send::Wadja $SMS::Send::Wadja::VERSION, Perl $], $^X" );
