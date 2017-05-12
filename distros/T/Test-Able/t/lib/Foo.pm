package Foo;

use Test::Able;
use Test::More;

extends qw( Bar );

startup plan => 1, startup_foo1 => sub { ok( 1 ); };

setup setup_foo1 => sub {};

test plan => 2, test_foo1 => sub { ok( 1 ) for 1 .. 2; };

teardown teardown_foo1 => sub {};

shutdown plan => 3, shutdown_foo1 => sub { ok( 1 ) for 1 .. 3; };

startup other_foo1 => sub {};

1;
