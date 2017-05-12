#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 11;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# Now we add some members a pair of sets.
$redis->sadd( "girls", "Kerry" );
$redis->sadd( "girls", "Sherry" );
$redis->sadd( "girls", "Terri" );
$redis->sadd( "girls", "Robin" );

$redis->sadd( "boys", "Steve" );
$redis->sadd( "boys", "Paul" );

# We should have 4 + 2 members, respectively.
is( $redis->scard("girls"), 4, "The girl-set has the right number of members" );
is( $redis->scard("boys"),  2, "The boy-set has the right number of members" );

# Now we move `Robin` as it is a boy's name too.  Ooops.
my $ret = $redis->smove( "girls", "boys", "Robin" );
is( $ret, 1, "The move succeeded" );

# So the numbers should change.
is( $redis->scard("girls"), 3, "The girl-set has the right number of members" );
is( $redis->scard("boys"),  3, "The boy-set has the right number of members" );

# And to confirm we should find the membership test works
ok( $redis->sismember( "boys", "Robin" ),
    "The moved member is in the destination" );
ok( !$redis->sismember( "girls", "Robin" ),
    "The moved member is not in the source" );

# Finally we try to move a value that doesn't exist.
$ret = $redis->smove( "girls", "boys", "Jo" );
is( $ret, 0, "Moving a missing element won't" );
