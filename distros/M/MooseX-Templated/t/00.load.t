use Test::More tests => 5;

BEGIN {
use_ok( 'MooseX::Templated' );
use_ok( 'MooseX::Templated::Engine' );
use_ok( 'MooseX::Templated::View' );
use_ok( 'MooseX::Templated::View::TT' );
use_ok( 'MooseX::Templated::Util' );
}

diag( "Testing MooseX::Templated $MooseX::Templated::VERSION" );
