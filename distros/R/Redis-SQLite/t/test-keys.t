#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 20;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# Add some keys
foreach my $x (qw! foo bar baz bart bort bark !)
{
    is( $redis->exists($x), 0, "The key doesn't exist prior to creation" );
    $redis->set( $x, $x );
    is( $redis->exists($x), 1, "The key does exist post-creation" );
}

# Now we should have six keys
is( scalar $redis->keys(), 6, "We've created some keys" );

# We fetch the keys that match the pattern "ba*" and should have two
is( scalar $redis->keys("^ba"), 4, "We filtered them appropriately" );

# But we'll have only one "oo" match.
is( scalar $redis->keys("oo\$"), 1, "We filtered them appropriately, again" );

#
# Add a set to see if `exists` works on that.
#
is( $redis->exists("set.foo"),
    0, "The set-key doesn't exist prior to creation" );
$redis->sadd( "set.foo", "bar" );
is( $redis->exists("set.foo"), 1, "The set-key exists post-creation" );
