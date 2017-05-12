# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Stack-Presistent.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
BEGIN { use_ok('Stack::Persistent') };

#########################

ok( $stack = Stack::Persistent->new(-filename => 't/test.cache',
                                    -pages => '1',
                                    -size => '256k') );
ok( $stack->push('default', 'test1') );
ok( $stack->push('default', 'test2') );
ok( $stack->push('default', 'test3') );
ok( $stack->push('default', 'test4') );
is( $stack->items('default'), 4 );
is( $stack->peek('default'), 'test4' );
$stack->dump('default');
is( $stack->pop('default'), 'test4' );
is( $stack->pop('default'), 'test3' );
is( $stack->items('default'), 2 );
ok( $stack->clear('default') );
is( $stack->items('default'), 0 );

