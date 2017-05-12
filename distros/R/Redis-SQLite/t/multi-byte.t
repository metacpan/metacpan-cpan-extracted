#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 5;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}


# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# Set a key
$redis->set( "extended", "❄" );

# The type should be a 'string'
is( $redis->type("extended"), "string", "The key has the correct type" );

# Which will result in a single key.
is( scalar $redis->keys(), 1, "There is now a single key" );

# Which has the correct content
is( $redis->get("extended"), "❄", "The multibyte character survived a round-trip" );
