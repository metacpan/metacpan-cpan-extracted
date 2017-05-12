use Test::More tests => 4;

BEGIN {
use_ok( 'Parallel::Workers' );
use_ok( 'Parallel::Workers::Backend' );
use_ok( 'Parallel::Workers::Backend::XMLRPC' );
use_ok( 'Parallel::Workers::Backend::SSH' );
}

diag( "Testing Parallel::Workers $Parallel::Workers::VERSION" );
