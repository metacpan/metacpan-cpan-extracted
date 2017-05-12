use Test::More tests => 4;

BEGIN {
use_ok( 'Sub::Todo' );
}

diag( "Testing Sub::Todo $Sub::Todo::VERSION" );

ok(!Sub::Todo::todo(), 'returns false');

ok(!Sub::Todo::todo_carp(), 'carps ok');

ok($! == Sub::Todo::get_errno_func_not_impl, 'sets $! properly');


