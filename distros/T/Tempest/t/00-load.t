#!perl -w

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tempest' );
}

diag( "Testing Tempest $Tempest::VERSION, Perl $], $^X" );
