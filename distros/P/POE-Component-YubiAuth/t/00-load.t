#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'POE::Component::YubiAuth' );
}

diag( "Testing POE::Component::YubiAuth $POE::Component::YubiAuth::VERSION, Perl $], $^X" );
