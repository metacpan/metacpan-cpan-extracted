#!/usr/bin/perl -I../lib/ -Ilib/

use strict;
use warnings;

use Test::More tests => 185;

BEGIN
{
    use_ok( "Redis::SQLite", "We could load the module" );
}

# Create a new object
my $redis = Redis::SQLite->new( path => ':memory:' );
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


##
## Getting bits.
##

# "@" => 64.
$redis->set( "foo", '@' );
is( $redis->getbit( "foo", 0 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 1 ), 1, "Found the correct bit" );
is( $redis->getbit( "foo", 2 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 3 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 4 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 4 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 6 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 7 ), 0, "Found the correct bit" );
is( $redis->get("foo"), '@', "And the value is what we expect: '\@'" );

#  " " => 32
$redis->set( "foo", ' ' );
is( $redis->getbit( "foo", 0 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 1 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 2 ), 1, "Found the correct bit" );
is( $redis->getbit( "foo", 3 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 4 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 5 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 6 ), 0, "Found the correct bit" );
is( $redis->getbit( "foo", 7 ), 0, "Found the correct bit" );
is( $redis->get("foo"), " ", "And the value is what we expect: ' '" );


#  "0x01" => 01
$redis->set( "foo", chr(0x01) );
is( $redis->getbit( "foo", 0 ), 0, "Found the correct bit: 0x01 0" );
is( $redis->getbit( "foo", 1 ), 0, "Found the correct bit: 0x01 1" );
is( $redis->getbit( "foo", 2 ), 0, "Found the correct bit: 0x01 2" );
is( $redis->getbit( "foo", 3 ), 0, "Found the correct bit: 0x01 3" );
is( $redis->getbit( "foo", 4 ), 0, "Found the correct bit: 0x01 4" );
is( $redis->getbit( "foo", 5 ), 0, "Found the correct bit: 0x01 5" );
is( $redis->getbit( "foo", 6 ), 0, "Found the correct bit: 0x01 6" );
is( $redis->getbit( "foo", 7 ), 1, "Found the correct bit: 0x01 7" );
is( $redis->get("foo"), chr(0x01), "And the value is what we expect: '0x01'" );

# All bits set
$redis->set( "foo", chr(0xff) );
for ( my $i = 0 ; $i < 8 ; $i++ )
{
    is( $redis->getbit( "foo", $i ),
        1, "Found the correct bit - 0xFF - $i -> 1" );
}

# Zero bits set
$redis->set( "foo", chr(0x00) );
for ( my $i = 0 ; $i < 8 ; $i++ )
{
    is( $redis->getbit( "foo", $i ),
        0, "Found the correct bit - 0x00 - $i -> 0" );
}


##
## Set some bits
##


# We expect 0x00000001 [decimal: 1]
$redis->del("foo");
$redis->setbit( "foo", 7, 1 );
is( $redis->get("foo"), chr(0x01), "Retrieving a value succeeded: 0x01" );


# We expect 0x00000011 [decimal: 3]
$redis->del("foo");
$redis->setbit( "foo", 7, 1 );
$redis->setbit( "foo", 6, 1 );
is( $redis->get("foo"), chr(0x03), "Retrieving a value succeeded: 0x03" );

# We expect 0x00000010 [decimal: 2]
$redis->del("foo");
$redis->setbit( "foo", 7, 0 );
$redis->setbit( "foo", 6, 1 );
is( $redis->get("foo"), chr(0x02), "Retrieving a value succeeded: 0x02" );

# We expect 0x00000000 [decimal: 0]
for ( my $i = 0 ; $i < 8 ; $i++ )
{
    $redis->setbit( "foo", $i, 0 );
}
is( $redis->get("foo"), chr(0x00), "Retrieving a value succeeded: 0x00" );

# We expect 0x11111111 [decimal: 255]
for ( my $i = 0 ; $i < 8 ; $i++ )
{
    $redis->setbit( "foo", $i, 1 );
}
is( $redis->get("foo"), chr(0xFF), "Retrieving a value succeeded: 0xFF" );

# We expect 0x00000111 [decimal: 7]
$redis->del("foo");
$redis->setbit( "foo", 7, 1 );
$redis->setbit( "foo", 6, 1 );
$redis->setbit( "foo", 5, 1 );
is( $redis->get("foo"), chr(0x07), "Retrieving a value succeeded: 0x07" );


# Test powers of two
my $c = 0;
for ( my $i = 1 ; $i < 2**64 ; $i *= 2 )
{
    $c += 1;
    $redis->del("foo");

    # Set a single bit - only one should be set.
    $redis->setbit( "foo", $c, 1 );
    is( $redis->bitcount("foo"), 1, "Only one bit is set: $i" );

    # Get the value, as a binary string.
    my $val = $redis->get("foo");
    my $bin = unpack( "B*", $val );

    #
    # Now we expect $c zeros then a 1.
    #
    # Since we know only one bit is set we can just look for the 1.
    #
    is( substr( $bin, $c, 1 ), "1", "Found a one in the correct location" );


}
