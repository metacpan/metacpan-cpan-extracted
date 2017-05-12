#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 61;


BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $o = Redis::SQLite->new( path => ':memory:' );
isa_ok( $o, "Redis::SQLite", "Created Redis::SQLite object" );

## Commands operating on string values

ok( $o->set( foo => 'bar' ), 'set foo => bar' );

ok( !$o->setnx( foo => 'bar' ), 'setnx foo => bar fails' );

cmp_ok( $o->get('foo'), 'eq', 'bar', 'get foo = bar' );

ok( $o->set( foo => '' ), 'set foo => ""' );

cmp_ok( $o->get('foo'), 'eq', '', 'get foo = ""' );

ok( $o->set( foo => 'baz' ), 'set foo => baz' );

cmp_ok( $o->get('foo'), 'eq', 'baz', 'get foo = baz' );


ok( $o->set( 'test-undef' => 42 ), 'set test-undef' );
ok( $o->exists('test-undef'), 'exists undef' );

# Big sized keys
for my $size ( 10_000, 100_000, 500_000, 1_000_000, 2_500_000 )
{
    my $v = 'a' x $size;
    ok( $o->set( 'big_key', $v ), "set with value size $size ok" );
    is( $o->get('big_key'), $v, "... and get was ok to" );
}

$o->del('non-existant');
ok( !$o->exists('non-existant'),      'exists non-existant' );
ok( !defined $o->get('non-existant'), 'get non-existant' );

my $key_next = 3;
ok( $o->set( 'key-next' => 0 ),         'key-next = 0' );
ok( $o->set( 'key-left' => $key_next ), 'key-left' );

my @keys;
foreach my $id ( 0 .. $key_next )
{
    my $key = 'key-' . $id;
    push @keys, $key;
    ok( $o->set( $key => $id ), "set $key -> $id" );
    ok( $o->exists($key), "exists $key" );
    is( $o->get($key), $id, "get $key" );
    cmp_ok( $o->incr('key-next'), '==', $id + 1,             'incr' );
    cmp_ok( $o->decr('key-left'), '==', $key_next - $id - 1, 'decr' );
}
is( $o->get('key-next'), $key_next + 1, 'key-next' );

ok( $o->set( 'test-incrby', 0 ), 'test-incrby' );
ok( $o->set( 'test-decrby', 0 ), 'test-decry' );
foreach ( 1 .. 3 )
{
    is( $o->incrby( 'test-incrby', 3 ), $_ * 3, 'incrby 3' );
    is( $o->decrby( 'test-decrby', 7 ), -( $_ * 7 ), 'decrby 7' );
}

ok( $o->del($_), "del $_" ) foreach map {"key-$_"} ( 'next', 'left' );
ok( !$o->del('non-existing'), 'del non-existing' );

cmp_ok( $o->type('foo'), 'eq', 'string', 'type' );

is( $o->keys('key-.*'), $key_next + 1, 'key-*' );
is_deeply( [sort $o->keys('key-.*')], [sort @keys], 'keys' );

ok( my $key = $o->randomkey, 'randomkey' );


## All done
done_testing();
