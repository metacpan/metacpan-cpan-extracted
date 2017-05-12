#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 21;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# The type should of an empty key should be undef.
is( $redis->type("fruits"), undef, "A missing key has no type" );

# Create a set
foreach my $item (qw! apple bananna orange pineapple pear !)
{
    $redis->sadd( "fruits", $item );
}

# We should now have a single key
is( scalar $redis->keys(), 1, "We've created some set-members" );

# The type should be a 'set'
is( $redis->type("fruits"), "set", "The key has the correct type" );


# The count should match
is( $redis->scard("fruits"), 5, "We got the correct number of items" );

# Delete the set
$redis->del("fruits");

# The keys should be empty.
is( scalar $redis->keys(),   0, "Deleting the set worked" );
is( $redis->scard("fruits"), 0, "And the set is empty" );

# Now create a new set, add the members and delete a couple.
foreach my $item (qw! 1 2 3 4 5 6 7 8 9 10 !)
{
    $redis->sadd( "numbers", $item );
}

# We should now have a single key
is( scalar $redis->keys(),    1,  "We've created some set-members" );
is( $redis->scard("numbers"), 10, "We have ten numbers" );

# Delete some numbers
$redis->srem( "numbers", "9" );
$redis->srem( "numbers", "10" );

is( $redis->scard("numbers"), 8, "We have removed items from the set" );

# And the numbers should be all OK
foreach my $num ( $redis->smembers("numbers") )
{
    ok( $num < 9, "Set-member is one we expect: $num" );
}

# Even when done randomly
ok( $redis->srandmember("numbers") < 9, "Random set-member is one we expect." );
