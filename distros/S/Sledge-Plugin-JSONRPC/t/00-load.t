#perl -T

use Test::More tests => 1;

sub register_hook {}

BEGIN {
	use_ok( 'Sledge::Plugin::JSONRPC' );
}

diag( "Testing Sledge::Plugin::JSONRPC $Sledge::Plugin::JSONRPC::VERSION, Perl $], $^X" );
