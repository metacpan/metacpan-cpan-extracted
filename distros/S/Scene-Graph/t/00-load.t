#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Scene::Graph' );
}

diag( "Testing Scene::Graph $Scene::Graph::VERSION, Perl $], $^X" );
