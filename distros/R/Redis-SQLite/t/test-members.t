#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 26;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# WHich means this set is empty
is( $redis->scard("numbers"), 0, "The 'numbers' set is empty" );

# Now create a new set, add the members and delete a couple.
foreach my $item (qw! 1 2 3 4 5 6 7 8 9 10 !)
{
    $redis->sadd( "numbers", $item );
}

# We should now have a single key
is( scalar $redis->keys(),    1,  "We've created some set-members" );
is( $redis->scard("numbers"), 10, "We have ten numbers" );

# The set should contain 1 - 10
foreach my $item (qw! 1 2 3 4 5 6 7 8 9 10 !)
{
    is( $redis->sismember( "numbers", $item ),
        1, "membership test succeeded: $item" );
}

# Not 11-20
foreach my $item (qw! 1 2 3 4 5 6 7 8 9 10 !)
{
    my $n = $item + 10;

    is( $redis->sismember( "numbers", $n ), 0,
        "membership test succeeded: $n" );
}
