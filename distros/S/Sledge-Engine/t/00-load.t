#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sledge::Engine' );
}

diag( "Testing Sledge::Engine $Sledge::Engine::VERSION, Perl $], $^X" );
