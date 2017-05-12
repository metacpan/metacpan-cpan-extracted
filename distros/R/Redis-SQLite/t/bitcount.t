#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 8;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ":memory:" );
isa_ok( $redis, "Redis::SQLite", "Created Redis::SQLite object" );

# We should have zero keys.
is( scalar $redis->keys(), 0, "There are no keys by default" );


##
## Counting (Set) Bits
##

# The number of set-bits should be 26
$redis->set( "blah", "foobar" );
is( $redis->bitcount("blah"), 26, "We counted the correct number of set-bits" );

# Now try a simple pair of examples " " => 32, and "@" => 64.
$redis->set( "blah", ' ' );
is( $redis->bitcount("blah"), 1, "We counted the correct number of set-bits" );

$redis->set( "blah", '@' );
is( $redis->bitcount("blah"), 1, "We counted the correct number of set-bits" );

# All bits set.
$redis->set( "blah", chr(0xff) );
is( $redis->bitcount("blah"), 8, "We counted the correct number of set-bits" );

# Zero bits set
$redis->set( "blah", chr(0x00) );
is( $redis->bitcount("blah"), 0, "We counted the correct number of set-bits" );
