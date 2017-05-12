package Bar;

use Test::Able;
use Test::More;

startup plan => 1, startup_ => sub { ok( 1 ); };
startup startup_bar2 => sub {};
startup plan => 2, startup_2_bar3 => sub { ok( 1 ) for 1 .. 2; };
startup startup_bar4 => sub {};

setup setup_bar1 => sub {};
setup plan => 3, setup_ => sub { ok( 1 ) for 1 .. 3; };
setup setup_bar3 => sub {};
setup plan => 11, setup_11_bar4 => sub { ok( 1 ) for 1 .. 11; };

test plan => 3, test_bar1 => sub { ok( 1 ) for 1 .. 3; };
test test_bar2 => sub {};
test test_4 => sub { ok( 1 ) for 1 .. 4; };
test test_bar4 => sub {};

teardown plan => 1, teardown_bar1 => sub { ok( 1 ); };
teardown teardown_bar2 => sub {};
teardown plan => 6, teardown_6_bar3 => sub { ok( 1 ) for 1 .. 6; };
teardown teardown_0 => sub {};

shutdown shutdown_ => sub {};
shutdown plan => 5, shutdown_bar2 => sub { ok( 1 ) for 1 .. 5; };
shutdown shutdown_bar3 => sub {};
shutdown plan => 15, shutdown_15_bar4 => sub { ok( 1 ) for 1 .. 15; };

sub other_bar1 {}
sub other {}

1;
