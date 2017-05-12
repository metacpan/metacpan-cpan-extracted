# $Id: 000-load.t 2676 2007-10-03 17:38:27Z andy $
use Test::More tests => 1;

BEGIN {
    use_ok( 'Parallel::Iterator' );
}

diag( "Testing Parallel::Iterator $Parallel::Iterator::VERSION" );
