#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use Tangence::Message;
$Tangence::Message::SORT_HASH_KEYS = 1;

use Tangence::Type;
sub _make_type { Tangence::Type->new_from_sig( shift ) }

use lib ".";
use t::Colourable;

my $VERSION_MINOR = Tangence::Constants->VERSION_MINOR;

{
   # We need a testing stream that declares a version
   package TestStream;
   use base qw( Tangence::Stream );

   sub minor_version { $VERSION_MINOR }

   sub new { bless {}, shift }

   # Stub the methods we don't care about
   sub _install_watch { }
   sub make_proxy { }
   sub get_by_id { my ( $self, $id ) = @_; "OBJPROXY[id=$id]" }
}

Tangence::Struct->declare(
   "TestRecord",
   fields => [
      one => "int",
      two => "str",
   ],
);

sub test_specific
{
   my $name = shift;
   my %args = @_;

   my $m = Tangence::Message->new( TestStream->new );
   my $pack_method = "pack_$args{type}";
   is( $m->$pack_method( $args{data} ), $m, "$pack_method returns \$m for $name" );

   is_hexstr( $m->{record}, $args{stream}, "$pack_method $name" );

   my $unpack_method = "unpack_$args{type}";
   is_deeply( $m->$unpack_method(), exists $args{retdata} ? $args{retdata} : $args{data}, "$unpack_method $name" );
   is( length $m->{record}, 0, "eats all stream for $name" );
}

sub test_specific_dies
{
   my $name = shift;
   my %args = @_;

   ok( exception {
      my $m = Tangence::Message->new( TestStream->new );
      my $pack_method = "pack_$args{type}";

      $m->$pack_method( $args{data} );
   }, "pack $name dies" ) if exists $args{data};

   ok( exception {
      my $m = Tangence::Message->new( TestStream->new, undef, $args{stream} );
      my $unpack_method = "unpack_$args{type}";

      $m->$unpack_method()
   }, "unpack $name dies" ) if exists $args{stream};
}

use Tangence::Registry;
use t::Ball;

my $registry = Tangence::Registry->new(
   tanfile => "t/Ball.tan",
);

my $ball = $registry->construct(
   "t::Ball",
   colour => "red",
);
$ball->id == 1 or die "Expected ball->id to be 1";

test_specific "bool f",
   type   => "bool",
   data   => 0,
   stream => "\x00";

test_specific "bool t",
   type   => "bool",
   data   => 1,
   stream => "\x01";

# So many parts of code would provide undef == false, so we will serialise
# undef as false and not care about nullable
test_specific "bool undef",
   type   => "bool",
   data   => undef,
   stream => "\x00",
   retdata => 0;

test_specific_dies "bool from str",
   type   => "bool",
   stream => "\x20";

test_specific "int tiny",
   type   => "int",
   data   => 20,
   stream => "\x02\x14";

test_specific "int -ve tiny",
   type   => "int",
   data   => -30,
   stream => "\x03\xe2";

test_specific "int",
   type   => "int",
   data   => 0x01234567,
   stream => "\x06\x01\x23\x45\x67";

test_specific "int -ve",
   type   => "int",
   data   => -0x07654321,
   stream => "\x07\xf8\x9a\xbc\xdf";

test_specific_dies "int from str",
   type   => "int",
   stream => "\x20";

test_specific_dies "int from ARRAY",
   type   => "int",
   data   => [],
   stream => "\x40";

test_specific_dies "int from undef",
   type   => "int",
   data   => undef,
   stream => "\x80";

test_specific_dies "int from NaN",
   type   => "int",
   data   => "NaN";

test_specific_dies "int from +Inf",
   type   => "int",
   data   => "+Inf";

test_specific "string",
   type   => "str",
   data   => "hello",
   stream => "\x25hello";

test_specific "long string",
   type   => "str",
   data   => "ABC" x 20,
   stream => "\x3f\x3c" . ( "ABC" x 20 );

test_specific "marginal string",
   type   => "str",
   data   => "x" x 0x1f,
   stream => "\x3f\x1f" . ( "x" x 0x1f );

test_specific_dies "string from ARRAY",
   type   => "str",
   data   => [],
   stream => "\x40";

test_specific_dies "string from undef",
   type   => "str",
   data   => undef,
   stream => "\x80";

test_specific "record",
   type   => "record",
   data   => TestRecord->new( one => 1, two => 2 ),
             # DATAMETA_STRUCT
   stream => "\xe3" . "\x2aTestRecord" .
                      "\x02\1" .
                      "\x42" . "\x23one" . "\x23two" .
                      "\x42" . "\x23int" . "\x23str" .
             # DATA_RECORD
             "\xa2" . "\x02\1" .
                      "\x02\1" .
                      "\x212";

sub test_typed
{
   my $name = shift;
   my %args = @_;

   my $type = _make_type $args{sig};

   my $m = Tangence::Message->new( TestStream->new );
   $type->pack_value( $m, $args{data} );

   is_hexstr( $m->{record}, $args{stream}, "pack typed $name" );

   my $value = $type->unpack_value( $m );
   my $expect = exists $args{retdata} ? $args{retdata} : $args{data};

   if( defined $expect and !ref $expect and $expect =~ m/^-?\d+\.\d+/ ) {
      # Approximate comparison for floats
      $_ = sprintf "%.5f", $_ for $expect, $value;
   }
   elsif( defined $expect and $expect =~ m/^(?:[+-]inf|nan)$/i ) {
      # Canonicalise infinities
      $value  = 0+$value;
      $expect = 0+$expect;
   }

   is_deeply( $value, $expect, "\$type->unpack_value $name" );
   is( length $m->{record}, 0, "eats all stream for $name" );
}

sub test_typed_dies
{
   my $name = shift;
   my %args = @_;

   my $sig = $args{sig};
   my $type = _make_type $sig;

   ok( exception {
      my $m = Tangence::Message->new( TestStream->new );

      $type->pack_value( $m, $args{data} );
   }, "\$type->pack_value for ($sig) $name dies" ) if exists $args{data};

   ok( exception {
      my $m = Tangence::Message->new( TestStream->new, undef, $args{stream} );

      $type->unpack_value( $m )
   }, "\$type->unpack_value for ($sig) $name dies" ) if exists $args{stream};
}

test_typed "bool f",
   sig    => "bool",
   data   => 0,
   stream => "\x00";

test_typed "bool t",
   sig    => "bool",
   data   => 1,
   stream => "\x01";

test_typed_dies "bool from str",
   sig    => "bool",
   stream => "\x20";

test_typed "num u8",
   sig    => "u8",
   data   => 10,
   stream => "\x02\x0a";

test_typed "num s8",
   sig    => "s8",
   data   => 10,
   stream => "\x03\x0a";

test_typed "num s8 -ve",
   sig    => "s8",
   data   => -10,
   stream => "\x03\xf6";

test_typed "num s32",
   sig    => "s32",
   data   => 100,
   stream => "\x07\x00\x00\x00\x64";

test_typed "int tiny",
   sig    => "int",
   data   => 20,
   stream => "\x02\x14";

test_typed "int -ve tiny",
   sig    => "int",
   data   => -30,
   stream => "\x03\xe2";

test_typed "int",
   sig    => "int",
   data   => 0x01234567,
   stream => "\x06\x01\x23\x45\x67";

test_typed "int -ve",
   sig    => "int",
   data   => -0x07654321,
   stream => "\x07\xf8\x9a\xbc\xdf";

test_typed_dies "int from str",
   sig    => "int",
   stream => "\x20";

test_typed_dies "int from ARRAY",
   sig    => "int",
   data   => [],
   stream => "\x40";

test_typed_dies "int from NaN",
   sig    => "int",
   data   => "NaN";

test_typed_dies "int from +Inf",
   sig    => "int",
   data   => "+Inf";

test_typed "float16 zero",
   sig    => "float16",
   data   => 0,
   stream => "\x10\0\0";

test_typed "float16",
   sig    => "float16",
   data   => 1.25,
   stream => "\x10\x3d\x00";

test_typed "float16 NaN",
   sig    => "float16",
   data   => "NaN",
   stream => "\x10\x7e\x00";

test_typed "float16 +Inf",
   sig    => "float16",
   data   => "+Inf",
   stream => "\x10\x7c\x00";

test_typed "float16 undersize",
   sig    => "float16",
   data   => 1E-12,
   stream => "\x10\x00\x00",
   retdata => 0;

test_typed "float16 oversize",
   sig    => "float16",
   data   => 1E12,
   stream => "\x10\x7c\x00",
   retdata => "+Inf";

test_typed "float32 zero",
   sig    => "float32",
   data   => 0,
   stream => "\x11\0\0\0\0";

test_typed "float32",
   sig    => "float32",
   data   => 1.25,
   stream => "\x11\x3f\xa0\x00\x00";

test_typed "float32 NaN",
   sig    => "float32",
   data   => "NaN",
   stream => "\x11\x7f\xc0\x00\x00";

test_typed "float32 +Inf",
   sig    => "float32",
   data   => "+Inf",
   stream => "\x11\x7f\x80\x00\x00";

test_typed "float64 zero",
   sig    => "float64",
   data   => 0,
   stream => "\x12\0\0\0\0\0\0\0\0";

test_typed "float64",
   sig    => "float64",
   data   => 1588.625,
   stream => "\x12\x40\x98\xd2\x80\x00\x00\x00\x00";

test_typed "float64 NaN",
   sig    => "float64",
   data   => "NaN",
   stream => "\x12\x7f\xf8\x00\x00\x00\x00\x00\x00";

test_typed "float64 +Inf",
   sig    => "float64",
   data   => "+Inf",
   stream => "\x12\x7f\xf0\x00\x00\x00\x00\x00\x00";

test_typed "float one",
   sig    => "float",
   data   => 1,
   stream => "\x10\x3c\x00";

test_typed "float +100",
   sig    => "float",
   data   => 100,
   stream => "\x10\x56\x40";

test_typed "float +1E8",
   sig    => "float",
   data   => 1E8,
   stream => "\x11\x4c\xbe\xbc\x20";

test_typed "float +1E20",
   sig    => "float",
   data   => 1E20,
   stream => "\x12\x44\x15\xaf\x1d\x78\xb5\x8c\x40";

test_typed "float Inf",
   sig    => "float",
   data   => "+Inf",
   stream => "\x10\x7c\x00";

test_typed "string",
   sig    => "str",
   data   => "hello",
   stream => "\x25hello";

test_typed_dies "string from ARRAY",
   sig    => "str",
   data   => [],
   stream => "\x40";

test_typed "list(string)",
   sig    => 'list(str)',
   data   => [ "a", "b", "c" ],
   stream => "\x43\x21a\x21b\x21c";

test_typed_dies "list(string) from string",
   sig    => 'list(str)',
   data   => "hello",
   stream => "\x25hello";

test_typed_dies "list(string) from ARRAY(ARRAY)",
   sig    => 'list(str)',
   data   => [ [] ],
   stream => "\x41\x40";

test_typed "dict(string)",
   sig    => 'dict(str)',
   data   => { one => "one", },
   stream => "\x61\x23one\x23one";

test_typed_dies "dict(string) from string",
   sig    => 'dict(str)',
   data   => "hello",
   stream => "\x25hello";

test_typed_dies "dict(string) from HASH(ARRAY)",
   sig    => 'dict(str)',
   data   => { splot => [] },
   stream => "\x61\x65splot\x40";

test_typed "object",
   sig    => "obj",
   data   => $ball,
             # DATAMETA_CLASS
   stream => "\xe2" . "\x2ct.Colourable" .
                      "\x02\1" .
                      "\xa4" . "\x02\1" .
                               "\x60" .
                               "\x60" .
                               "\x61" . "\x26colour" . "\xa3" . "\x02\4" .
                                                                "\x02\1" .
                                                                "\x23str" .
                                                                "\x00" .
                               "\x40" .
                      "\x40" .
             # DATAMETA_CLASS
             "\xe2" . "\x26t.Ball" .
                      "\x02\2" .
                      "\xa4" . "\x02\1" .
                               "\x61" . "\x26bounce" . "\xa2" . "\x02\2" .
                                                                "\x41" . "\x23str" .
                                                                "\x23str" .
                               "\x61" . "\x27bounced" . "\xa1" . "\x02\3" .
                                                                 "\x41" . "\x23str" .
                               "\x61" . "\x24size" . "\xa3" . "\x02\4" .
                                                              "\x02\1" .
                                                              "\x23int" .
                                                              "\x01" .
                               "\x41" . "\x2ct.Colourable" .
                      "\x41" . "\x24size" .
             # DATAMETA_CONSTRUCT
             "\xe1" . "\x02\1" .
                      "\x02\2" .
                      "\x41" . "\x02\0" .
             # DATA_OBJ
             "\x84" . "\0\0\0\1",
   retdata => "OBJPROXY[id=1]";

test_typed "any (undef)",
   sig    => "any",
   data   => undef,
   stream => "\x80";

test_typed "any (int)",
   sig    => "any",
   data   => 0x1234,
   stream => "\x04\x12\x34";

test_typed "any (float)",
   sig    => "any",
   data   => 123.45,
   stream => "\x12\x40\x5e\xdc\xcc\xcc\xcc\xcc\xcd";

test_typed "any (NaN)",
   sig    => "any",
   data   => "NaN"+0,
   stream => "\x10\x7e\x00";

test_typed "any (string)",
   sig    => "any",
   data   => "hello",
   stream => "\x25hello";

test_typed "any (ARRAY empty)",
   sig    => "any",
   data   => [],
   stream => "\x40";

test_typed "any (ARRAY of string)",
   sig    => "any",
   data   => [qw( a b c )],
   stream => "\x43\x{21}a\x{21}b\x{21}c";

test_typed "any (ARRAY of 0x25 undefs)",
   sig    => "any",
   data   => [ (undef) x 0x25 ],
   stream => "\x5f\x25" . ( "\x80" x 0x25 );

test_typed "any (ARRAY of ARRAY)",
   sig    => "any",
   data   => [ [] ],
   stream => "\x41\x40";

test_typed "any (HASH empty)",
   sig    => "any",
   data   => {},
   stream => "\x60";

test_typed "any (HASH of string*1)",
   sig    => "any",
   data   => { key => "value" },
   stream => "\x61\x23key\x25value";

test_typed "any (HASH of string*2)",
   sig    => "any",
   data   => { a => "A", b => "B" },
   stream => "\x62\x21a\x{21}A\x21b\x{21}B";

test_typed "any (HASH of HASH)",
   sig    => "any",
   data   => { hash => {} },
   stream => "\x61\x24hash\x60";

test_typed "any (record)",
   sig    => "any",
   data   => TestRecord->new( one => 3, two => 4 ),
             # DATAMETA_STRUCT
   stream => "\xe3" . "\x2aTestRecord" .
                      "\x02\1" .
                      "\x42" . "\x23one" . "\x23two" .
                      "\x42" . "\x23int" . "\x23str" .
             # DATA_RECORD
             "\xa2" . "\x02\1" .
                      "\x02\3" .
                      "\x214";

my $m;

$m = Tangence::Message->new( 0 );
$m->pack_all_sametype( _make_type('int'), 10, 20, 30 );

is_hexstr( $m->{record}, "\x02\x0a\x02\x14\x02\x1e", 'pack_all_sametype' );

is_deeply( [ $m->unpack_all_sametype( _make_type('int') ) ], [ 10, 20, 30 ], 'unpack_all_sametype' );
is( length $m->{record}, 0, "eats all stream for all_sametype" );

done_testing;
