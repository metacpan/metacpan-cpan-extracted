#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::HexString;
use Math::BigInt;

use Protocol::CassandraCQL::Type;

sub encode
{
   my ( $typename, $v ) = @_;
   Protocol::CassandraCQL::Type->from_name( $typename )->encode( $v );
}

sub decode
{
   my ( $typename, $b ) = @_;
   Protocol::CassandraCQL::Type->from_name( $typename )->decode( $b );
}

sub validate
{
   my ( $typename, $v ) = @_;
   Protocol::CassandraCQL::Type->from_name( $typename )->validate( $v );
}

{
   my $type = Protocol::CassandraCQL::Type->from_name( do { my $tmp = "VARCHAR" } );
   is( $type->name, "VARCHAR", '$type->name' );
}

is_hexstr( encode( ASCII => "hello" ), "hello", 'encode ASCII' );
is       ( decode( ASCII => "hello" ), "hello", 'decode ASCII' );
ok(  !validate( ASCII => "hello" ), 'validate ASCII OK' );
like( validate( ASCII => "créme" ), qr/non-ASCII/, 'validate ASCII fail' );

is_hexstr( encode( BIGINT => 1234567890123 ), "\x00\x00\x01\x1f\x71\xfb\x04\xcb", 'encode BIGINT' );
is       ( decode( BIGINT => "\x00\x00\x01\x1f\x71\xfb\x04\xcb" ), 1234567890123, 'decode BIGINT' );
ok(  !validate( BIGINT => 1 ), 'validate BIGINT OK' );
like( validate( BIGINT => "abc" ), qr/not a number/, 'validate BIGINT fail' );
like( validate( BIGINT => 15.5 ), qr/not an integer/, 'validate BIGINT not-int' );

is_hexstr( encode( BLOB => "\x01\x23" ), "\x01\x23", 'encode BLOB' );
is_hexstr( decode( BLOB => "\x01\x23" ), "\x01\x23", 'decode BLOB' );
# All values valid

is_hexstr( encode( BOOLEAN => 1 == 1 ), "\x01", 'encode BOOLEAN true' );
is_hexstr( encode( BOOLEAN => 1 == 2 ), "\x00", 'encode BOOLEAN false' );
ok(        decode( BOOLEAN => "\x01" ),         'decode BOOLEAN true' );
ok(       !decode( BOOLEAN => "\x00" ),         'decode BOOLEAN false' );
# All values valid

is_hexstr( encode( DOUBLE => 12.3456 ), "\x40\x28\xb0\xf2\x7b\xb2\xfe\xc5", 'encode DOUBLE' );
# DOUBLE decode might not be exact
ok(   abs( decode( DOUBLE => "\x40\x28\xb0\xf2\x7b\xb2\xfe\xc5" ) - 12.3456 ) < 0.00001, 'decode DOUBLE' );
ok(  !validate( DOUBLE => 9.87 ), 'validate DOUBLE OK' );
like( validate( DOUBLE => "doughnut" ), qr/not a number/, 'validate DOUBLE fail' );

is_hexstr( encode( FLOAT => 1.234 ), "\x3f\x9d\xf3\xb6", 'encode FLOAT' );
# FLOAT decode might not be exact
ok(   abs( decode( FLOAT => "\x3f\x9d\xf3\xb6" ) - 1.234 ) < 0.001, 'decode FLOAT' );
# test inherited from _numeric

is_hexstr( encode( INT => 12345678 ), "\x00\xbc\x61\x4e", 'encode INT' );
is       ( decode( INT => "\x00\xbc\x61\x4e" ), 12345678, 'decode INT' );
# test inherited from _integral

# UNIX epoch timestamps 1377686281 == 2013/08/28 11:38:01
is_hexstr( encode( TIMESTAMP => 1377686281 ), "\x00\x00\x01\x40\xc4\x80\x5b\x28", 'encode TIMESTAMP' );
is       ( decode( TIMESTAMP => "\x00\x00\x01\x40\xc4\x80\x5b\x28" ), 1377686281, 'decode TIMESTAMP' );
# test inherited from _integral

is_hexstr( encode( UUID => "01234567-0123-0123-0123-0123456789ab" ),
           "\x01\x23\x45\x67\x01\x23\x01\x23\x01\x23\x01\x23\x45\x67\x89\xab", 'encode UUID' );
is       ( decode( UUID => "\x01\x23\x45\x67\x01\x23\x01\x23\x01\x23\x01\x23\x45\x67\x89\xab" ),
           "01234567-0123-0123-0123-0123456789ab", 'decode UUID' );
ok(  !validate( UUID => "89abcdef-3210-3210-3210-ba9876543210" ), 'validate UUID OK' );
like( validate( UUID => "non hex digits" ), qr/expected 32 hex digits/, 'validate UUID fail' );

is_hexstr( encode( VARCHAR => "café" ), "caf\xc3\xa9", 'encode VARCHAR' );
is       ( decode( VARCHAR => "caf\xc3\xa9" ), "café", 'decode VARCHAR' );
# All values valid

is_hexstr( encode( VARINT => 123456 ), "\x01\xe2\x40", 'encode VARINT +ve small' );
is       ( decode( VARINT => "\x01\xe2\x40" ), 123456, 'decode VARINT +ve small' );
is_hexstr( encode( VARINT => -123 ), "\x85", 'encode VARINT -ve' );
is       ( decode( VARINT => "\x85" ), -123, 'decode VARINT -ve' );

is_hexstr( encode( VARINT => Math::BigInt->new("1234567890987654321") ), "\x11\x22\x10\xf4\xb1\x6c\x1c\xb1", 'encode VARCHAR +ve large' );
is       ( decode( VARINT => "\x11\x22\x10\xf4\xb1\x6c\x1c\xb1" ), "1234567890987654321", 'decode VARCHAR +ve large' );
# test inherited from _integral

# boundary cases of VARINT encoding
{
   sub test_VARINT {
      my $n = shift;
      is( decode( VARINT => encode( VARINT => $n ) ), $n, "encode/decode VARINT $n" );
   }

   test_VARINT( 0 );
   test_VARINT( 1 );
   test_VARINT( -1 );
   test_VARINT( 0xff ); # test zero-extension in the +ve case
   test_VARINT( -0xff ); # test sign-extension in the -ve case
}

# DECIMAL depends on VARINT so do it afterwards
is_hexstr( encode( DECIMAL => 0 ), "\0\0\0\0\x00", 'encode DECIMAL zero' );
is       ( decode( DECIMAL => "\0\0\0\0\x00" ), 0, 'decode DECIMAL zero' );
is_hexstr( encode( DECIMAL => 100 ), "\0\0\0\0\x64", 'encode DECIMAL 100' );
is       ( decode( DECIMAL => "\0\0\0\0\x64" ), 100, 'decode DECIMAL 100' );
is_hexstr( encode( DECIMAL => 0.25 ), "\0\0\0\2\x19", 'encode DECIMAL 0.25' );
is       ( decode( DECIMAL => "\0\0\0\2\x19" ), 0.25, 'decode DECIMAL 0.25' );
# test inherited from _numeric

# Now the collections

is_hexstr( encode( "LIST<INT>" => [1,2,3] ),
           "\0\3\0\4\x00\x00\x00\x01\0\4\x00\x00\x00\x02\0\4\x00\x00\x00\x03",
           'encode LIST<INT>' );
is_deeply( decode( "LIST<INT>" => "\0\3\0\4\x00\x00\x00\x01\0\4\x00\x00\x00\x02\0\4\x00\x00\x00\x03" ),
           [1,2,3],
           'decode LIST<INT>' );
ok(  !validate( "LIST<INT>" => [4,5,6] ), 'validate LIST OK' );
like( validate( "LIST<INT>" => "not a list" ), qr/not an ARRAY/, 'validate LIST fail' );
like( validate( "LIST<INT>" => ["string"] ), qr/not a number/, 'validate LIST fail' );

# Don't want to rely on ordering
is_hexstr( encode( "MAP<VARCHAR,INT>" => { one => 1 } ),
           "\0\1\0\3one\0\4\x00\x00\x00\x01",
           'encode MAP<VARCHAR,INT> 1' );
is_deeply( decode( "MAP<VARCHAR,INT>" => "\0\1\0\3one\0\4\x00\x00\x00\x01" ),
           { one => 1 },
           'encode MAP<VARCHAR,INT> 1' );
is_deeply( decode( "MAP<VARCHAR,INT>", encode( "MAP<VARCHAR,INT>", { one => 1, two => 2, three => 3 } ) ),
           { one => 1, two => 2, three => 3 },
           'encode/decode MAP<VARCHAR,INT>' );
ok(  !validate( "MAP<VARCHAR,INT>" => { zero => 0 } ), 'validate MAP OK' );
like( validate( "MAP<VARCHAR,INT>" => "string" ), qr/not a HASH/, 'validate MAP fail' );
like( validate( "MAP<VARCHAR,INT>" => { half => "0.5" } ), qr/not an integer/, 'validate MAP fail' );

is_hexstr( encode( "SET<VARCHAR>" => [qw( red green blue )] ),
           "\0\3\0\3red\0\5green\0\4blue",
           'encode SET<VARCHAR>' );
is_deeply( decode( "SET<VARCHAR>" => "\0\3\0\3red\0\5green\0\4blue" ),
           [qw( red green blue )],
           'decode SET<VARCHAR>' );
# test inherited from LIST

done_testing;
