#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 9;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ":memory:" );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );

# Now we add two sets
$redis->sadd( "english", "Steve" );
$redis->sadd( "english", "Paul" );
$redis->sadd( "english", "Micheal" );

$redis->sadd( "finnish", "Kirsi" );
$redis->sadd( "finnish", "My" );
$redis->sadd( "finnish", "Jari" );

# The sets should have three values each.
is( $redis->scard("english"), 3, "The 'english' set has three members" );
is( $redis->scard("finnish"), 3, "The 'finnish' set has three members" );

# The union should thus be six entries long
my @combined = $redis->sunion( "english", "finnish" );
is( scalar @combined, 6, "The union has six members" );

# Now we'll test the storing of that union.
is( scalar $redis->keys(), 2, "Before SUNIONSTORE we have two keys" );
$redis->sunionstore( "combined", "english", "finnish" );
is( scalar $redis->keys(), 3, "After SUNIONSTORE we have three keys" );

# The union-set should have the number of members we expect.
is( $redis->scard("combined"),
    6, "The combined set has the right number of members" );
