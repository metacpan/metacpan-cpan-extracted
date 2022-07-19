use warnings; use strict;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parallel::Iterator' );
}

diag( "Testing Parallel::Iterator $Parallel::Iterator::VERSION" );
