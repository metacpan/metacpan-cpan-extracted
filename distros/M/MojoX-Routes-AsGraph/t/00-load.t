#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'MojoX::Routes::AsGraph' );
}

diag( "Testing MojoX::Routes::AsGraph $MojoX::Routes::AsGraph::VERSION, Perl $], $^X" );
