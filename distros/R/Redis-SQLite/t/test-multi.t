#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 19;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# Set a pair of keys
$redis->set( "key1", "Steve" );
$redis->set( "key3", "Kemp" );

# Attempt a mult-get
my @out = $redis->mget( "key1", "key3" );
ok( @out, "We found some values" );
is( scalar(@out), 2,       "We found the right number of values" );
is( $out[0],      "Steve", "The first is correct" );
is( $out[1],      "Kemp",  "The last is correct" );

# Now with a missing key in the middle.
@out = $redis->mget( "key1", "key2", "key3" );
ok( @out, "We found some values" );
is( scalar(@out), 3,       "We found the right number of values" );
is( $out[0],      "Steve", "The first is correct" );
is( $out[1],      undef,   "The middle is correct" );
is( $out[2],      "Kemp",  "The last is correct" );

# Update the keys
$redis->mset( "key1", "I like cake", "key2", "I like bacon" );
is( $redis->get("key1"), "I like cake",  "Multi-set worked" );
is( $redis->get("key2"), "I like bacon", "Multi-set worked" );

# Now again.
$redis->mset( "key1", "I like cake", "key2", "I like bacon",
              "key3", "I like you" );
is( $redis->get("key3"), "I like you", "Multi-set worked" );


# Setting those values with msetnx will fail, as they exist
is( $redis->msetnx( "key1", "Fail1" ), 0, "msetnx fails as expected" );
is( $redis->msetnx( "key_1", "ok_1", "key_2", "ok_2" ),
    1, "msetnx works as expected" );

is( $redis->get("key_1"), "ok_1", "Retrieving the value set works" );
is( $redis->get("key_2"), "ok_2", "Retrieving the value set works" );
