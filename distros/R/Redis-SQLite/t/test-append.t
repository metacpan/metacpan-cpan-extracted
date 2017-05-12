#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 8;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}


# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# The type should be a 'string'
is( $redis->type("greet"), undef, "A missing key has no type" );

# Now we set a greeting.
$redis->set( "greet", "Hello" );

# The type should be a 'string'
is( $redis->type("greet"), "string", "The key has the correct type" );

# Which will result in a single key.
is( scalar $redis->keys(), 1, "There is now a single key" );

# Now we append
$redis->append( "greet", ", world" );
is( scalar $redis->keys(), 1, "There is still only a single key" );

# Fetching the value should result in 'Hello, world'
is( $redis->get("greet"), "Hello, world", "Appending worked" );
