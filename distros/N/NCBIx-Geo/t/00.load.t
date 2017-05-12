use Test::More tests => 4;

BEGIN {
use_ok( 'NCBIx::Geo' );
use_ok( 'NCBIx::Geo::Sample' );
use_ok( 'NCBIx::Geo::Item' );
use_ok( 'NCBIx::Geo::Base' );
}

diag( "Testing NCBIx::Geo $NCBIx::Geo::VERSION" );
