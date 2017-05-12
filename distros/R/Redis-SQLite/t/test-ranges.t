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

# Set a key.
$redis->set( "key1", "Hello World" );

# Now change it
my $new_size = $redis->setrange( "key1", 6, "Redis" );
is( $redis->get("key1"), "Hello Redis", "Changing a string in-place worked" );
is( $redis->strlen("key1"), $new_size, "The sizes match" );

# Change an empty string
my $out = $redis->setrange( "key2", 6, "Redis" );

my $expected = "";
for ( my $i = 0 ; $i < 6 ; $i++ )
{
    $expected .= chr(0x00);
}
$expected .= "Redis";
my $size = length($expected);

is( $redis->get("key2"),    $expected, "Changing a string in-place worked" );
is( $redis->strlen("key2"), $size,     "And has the right size" );
is( $out,                   $size,     "The return value was the right size" );

# Now test the fetching of ranges
$redis->set( "mykey", "This is a string" );
is( $redis->getrange( "mykey", 0, 3 ), "This", "Fetching a range worked" );
is( $redis->getrange( "mykey", -3, -1 ),
    "ing", "Fetching a negative range worked" );
is( $redis->getrange( "mykey", 0, -1 ),
    "This is a string",
    "Fetching a complete range worked"
  );
is( $redis->getrange( "mykey", 10, 100 ),
    "string", "Fetching an over-sized range worked" );
