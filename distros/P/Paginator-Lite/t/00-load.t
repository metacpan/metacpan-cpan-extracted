#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Paginator::Lite' );
}

diag( "Testing Paginator::Lite $Paginator::Lite::VERSION, Perl $], $^X" );
