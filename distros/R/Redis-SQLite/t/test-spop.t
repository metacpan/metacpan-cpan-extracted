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

# Now we add some members to a set
$redis->sadd( "steve", "Steve" );
$redis->sadd( "steve", "Kemp" );
$redis->sadd( "steve", "Person" );
$redis->sadd( "steve", "Male" );
$redis->sadd( "steve", "Adult" );

# The union-set should have the number of members we expect.
is( $redis->scard("steve"), 5, "The set has the right number of members" );

# Remove an item.
$redis->spop("steve");
is( $redis->scard("steve"), 4, "The set has the right number of members" );

# Remove two items.
$redis->spop( "steve", 2 );
is( $redis->scard("steve"), 2, "The set has the right number of members" );

# Finally we remove the last two entries.
$redis->spop( "steve", 2 );
is( $redis->scard("steve"), 0, "The set has the right number of members" );

# At this point the set is empty - so popping should do nothing.
$redis->spop( "steve", 200 );
is( $redis->scard("steve"), 0, "The set has the right number of members" );
