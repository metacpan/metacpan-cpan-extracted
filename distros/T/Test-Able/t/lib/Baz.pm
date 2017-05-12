package Baz;

use Test::Able;
use Test::More;

extends qw( Foo );

startup plan => 7, startup_ => sub { ok( 1 ) for 1 .. 7; };

setup plan => 1, setup_ => sub { ok( 1 ); };

test plan => 9, test_9 => sub { ok( 1 ) for 1 .. 9; };

teardown plan => 2, teardown_2 => sub { ok( 1 ) for 1 .. 2; };

shutdown plan => 'no_plan', shutdown_ => sub {};

sub other {}

1;
