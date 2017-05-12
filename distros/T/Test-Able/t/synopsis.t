#!/usr/bin/perl

package MyTest;

use Test::Able;
use Test::More;

startup         some_startup  => sub {};
setup           some_setup    => sub {};
test plan => 1, foo           => sub { ok( 1 ); };
test            bar           => sub {
    my @runtime_list = 1 .. 42;
    $_[ 0 ]->meta->current_method->plan( scalar @runtime_list );
    ok( 1 ) for @runtime_list;
};
teardown        some_teardown => sub {};
shutdown        some_shutdown => sub {};

MyTest->run_tests;
