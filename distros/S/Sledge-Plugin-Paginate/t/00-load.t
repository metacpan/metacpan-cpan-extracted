#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sledge::Plugin::Paginate' );
}

diag( "Testing Sledge::Plugin::Paginate $Sledge::Plugin::Paginate::VERSION, Perl $], $^X" );
