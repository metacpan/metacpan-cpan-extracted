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

# Set a value.
$redis->set( "foo", "bar" );
is( $redis->get("foo"),    "bar", "Setting a value worked" );
is( scalar $redis->keys(), 1,     "A single key exists" );

# Rename.
is( $redis->rename( "foo", "renamed" ), 1, "Renaming worked" );

# We should still have a single key.
is( scalar $redis->keys(),     1,     "A single key still exists" );
is( $redis->get("renamed"),    "bar", "With the expected value." );
is( $redis->exists("renamed"), 1,     "The renamed target is valid" );
is( $redis->exists("foo"),     0,     "The original target is invalid" );


# Now try renaming with uniqueness
$redis->set( "moi", "kissa" );
is( scalar $redis->keys(), 2,       "We have two keys now" );
is( $redis->get("moi"),    "kissa", "With the expected value." );

is( $redis->renamenx( "moi", "renamed" ),
    0, "Renaming when the target exists will fail" );
is( $redis->exists("renamed"), 1, "The collision-target is valid" );
is( $redis->exists("moi"),     1, "The failed-rename key is valid" );

is( $redis->get("moi"),     "kissa", "We have the value we expect" );
is( $redis->get("renamed"), "bar",   "We have the value we expect" );


# Finally try renaming which will work.
is( $redis->renamenx( "moi", "koira" ),
    "OK", "Renaming works when no collision" );

is( $redis->exists("koira"), 1, "The target exists" );
is( $redis->exists("moi"),   0, "The source does not exist" );
