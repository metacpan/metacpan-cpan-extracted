use strict; 
use Test::More tests => 1;

use PHP::Include;

include_php_vars( "t/test.php" );
ok( 1, 'include_php_vars() with double quoted filename' );
