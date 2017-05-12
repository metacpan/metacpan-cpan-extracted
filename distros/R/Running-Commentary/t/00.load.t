use 5.014;
*STDOUT->autoflush(1);

use Test::More tests => 1;

BEGIN {
    use_ok( 'Running::Commentary' );
}

diag( "Testing Running::Commentary $Running::Commentary::VERSION" );
