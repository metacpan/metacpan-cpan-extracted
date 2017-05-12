#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 12;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# Now we add two sets
$redis->sadd( "english", "Steve" );
$redis->sadd( "english", "Paul" );
$redis->sadd( "english", "Micheal" );
$redis->sadd( "english", "Pete" );

$redis->sadd( "finnish", "Kirsi" );
$redis->sadd( "finnish", "My" );
$redis->sadd( "finnish", "Steve" );
$redis->sadd( "finnish", "Jari" );

# The sets should have three values each.
is( $redis->scard("english"), 4, "The 'english' set has four members" );
is( $redis->scard("finnish"), 4, "The 'finnish' set has four members" );

# The intersection is just one name - Steve
my @combined = $redis->sinter( "english", "finnish" );
is( scalar @combined, 1,       "The union has the expected overlap members" );
is( $combined[0],     "Steve", "Which is what we expect" );


# Now we're going to test SINTERSTORE
$redis->sadd( "a", "1" );
$redis->sadd( "a", "2" );
$redis->sadd( "a", "3" );

$redis->sadd( "b", "2" );
$redis->sadd( "b", "3" );
$redis->sadd( "b", "4" );


# The intersection should have two entries: 2 + 3.
my @both = $redis->sinter( "a", "b" );
is( scalar @both, 2, "The union has the expected overlap members" );

# Now we count the keys and we should have four
is( scalar $redis->keys(), 4, "Before SINTERSTORE we have four keys" );

# Store the resulting intersection
$redis->sinterstore( "union", "a", "b" );

# ANd our keys should have increased.
is( scalar $redis->keys(), 5, "After SINTERSTORE we have five keys" );

# The value of the set should be : 2 + 3
my @res = $redis->smembers("union");
is( scalar @res, 2, "The union has the expected overlap members" );

# Delete them both
$redis->srem( "union", "2" );
$redis->srem( "union", "3" );
@res = $redis->smembers("union");
is( scalar @res, 0, "The emptied union has zero members" );
