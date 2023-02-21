#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sys::GetRandom' );
}

diag( "Testing Sys::GetRandom $Sys::GetRandom::VERSION, Perl $], $^X" );
