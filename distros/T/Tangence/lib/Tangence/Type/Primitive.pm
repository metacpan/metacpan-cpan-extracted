#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package Tangence::Type::Primitive;

use strict;
use warnings;

use base qw( Tangence::Type );

package
   Tangence::Type::Primitive::bool;
use base qw( Tangence::Type::Primitive );
use Carp;
use Tangence::Constants;

sub default_value { "" }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   $message->_pack_leader( DATA_NUMBER, $value ? DATANUM_BOOLTRUE : DATANUM_BOOLFALSE );
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my ( $type, $num ) = $message->_unpack_leader();

   $type == DATA_NUMBER or croak "Expected to unpack a number(bool) but did not find one";
   $num == DATANUM_BOOLFALSE and return 0;
   $num == DATANUM_BOOLTRUE  and return 1;
   croak "Expected to find a DATANUM_BOOL subtype but got $num";
}

package
   Tangence::Type::Primitive::_integral;
use base qw( Tangence::Type::Primitive );
use Carp;
use Tangence::Constants;

use constant SUBTYPE => undef;

sub default_value { 0 }

{
   my %format = (
      DATANUM_UINT8,  [ "C",  1 ],
      DATANUM_SINT8,  [ "c",  1 ],
      DATANUM_UINT16, [ "S>", 2 ],
      DATANUM_SINT16, [ "s>", 2 ],
      DATANUM_UINT32, [ "L>", 4 ],
      DATANUM_SINT32, [ "l>", 4 ],
      DATANUM_UINT64, [ "Q>", 8 ],
      DATANUM_SINT64, [ "q>", 8 ],
   );

   sub _best_int_type_for
   {
      my ( $n ) = @_;

      if( $n < 0 ) {
         return DATANUM_SINT8  if $n >= -0x80;
         return DATANUM_SINT16 if $n >= -0x8000;
         return DATANUM_SINT32 if $n >= -0x80000000;
         return DATANUM_SINT64;
      }

      return DATANUM_UINT8  if $n <= 0xff;
      return DATANUM_UINT16 if $n <= 0xffff;
      return DATANUM_UINT32 if $n <= 0xffffffff;
      return DATANUM_UINT64;
   }

   sub pack_value
   {
      my $self = shift;
      my ( $message, $value ) = @_;

      defined $value or croak "cannot pack_int(undef)";
      ref $value and croak "$value is not a number";
      $value == $value or croak "cannot pack_int(NaN)";
      $value == "+Inf" || $value == "-Inf" and croak "cannot pack_int(Inf)";

      my $subtype = $self->SUBTYPE || _best_int_type_for( $value );
      $message->_pack_leader( DATA_NUMBER, $subtype );

      $message->_pack( pack( $format{$subtype}[0], $value ) );
   }

   sub unpack_value
   {
      my $self = shift;
      my ( $message ) = @_;

      my ( $type, $num ) = $message->_unpack_leader();

      $type == DATA_NUMBER or croak "Expected to unpack a number but did not find one";
      exists $format{$num} or croak "Expected an integer subtype but got $num";

      if( my $subtype = $self->SUBTYPE ) {
         $subtype == $num or croak "Expected integer subtype $subtype, got $num";
      }

      my ( $n ) = unpack( $format{$num}[0], $message->_unpack( $format{$num}[1] ) );

      return $n;
   }
}

package
   Tangence::Type::Primitive::u8;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_UINT8;

package
   Tangence::Type::Primitive::s8;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_SINT8;

package
   Tangence::Type::Primitive::u16;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_UINT16;

package
   Tangence::Type::Primitive::s16;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_SINT16;

package
   Tangence::Type::Primitive::u32;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_UINT32;

package
   Tangence::Type::Primitive::s32;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_SINT32;

package
   Tangence::Type::Primitive::u64;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_UINT64;

package
   Tangence::Type::Primitive::s64;
use base qw( Tangence::Type::Primitive::_integral );
use constant SUBTYPE => Tangence::Constants::DATANUM_SINT64;

package
   Tangence::Type::Primitive::int;
use base qw( Tangence::Type::Primitive::_integral );

package
   Tangence::Type::Primitive::float;
use base qw( Tangence::Type::Primitive );
use Carp;
use Tangence::Constants;

use constant SUBTYPE => undef;

sub default_value { 0.0 }

{
   my %format = (
                     #   pack, bytes, NaN
      DATANUM_FLOAT32, [ "f>", 4,     "\x7f\xc0\x00\x00" ],
      DATANUM_FLOAT64, [ "d>", 8,     "\x7f\xf8\x00\x00\x00\x00\x00\x00" ],
   );

   sub _best_type_for
   {
      my ( $value ) = @_;

      # Unpack as 64bit float and see if it's within limits
      my $float64BIN = pack "d>", $value;

      # float64 == 1 / 11 / 52
      my $exp64 = ( unpack "L>", $float64BIN & "\x7f\xf0\x00\x00" ) >> (52-32);

      # Zero is smallest
      return DATANUM_FLOAT16 if $exp64 == 0;

      # De-bias
      $exp64 -= 1023;

      # Special values might as well be float16
      return DATANUM_FLOAT16 if $exp64 == 1024;

      # Smaller types are OK if the exponent will fit and there's no loss of
      # mantissa precision

      return DATANUM_FLOAT16 if abs($exp64) < 15  &&
         ($float64BIN & "\x00\x00\x03\xff\xff\xff\xff\xff") eq "\x00"x8;

      return DATANUM_FLOAT32 if abs($exp64) < 127 &&
         ($float64BIN & "\x00\x00\x00\x00\x1f\xff\xff\xff") eq "\x00"x8;

      return DATANUM_FLOAT64;
   }

   sub pack_value
   {
      my $self = shift;
      my ( $message, $value ) = @_;

      defined $value or croak "cannot pack undef as float";
      ref $value and croak "$value is not a number";

      my $subtype = $self->SUBTYPE || _best_type_for( $value );

      return Tangence::Type::Primitive::float16->pack_value( $message, $value ) if $subtype == DATANUM_FLOAT16;

      $message->_pack_leader( DATA_NUMBER, $subtype );
      $message->_pack( $value == $value ?
         pack( $format{$subtype}[0], $value ) : $format{$subtype}[2]
      );
   }

   sub unpack_value
   {
      my $self = shift;
      my ( $message ) = @_;

      my ( $type, $num ) = $message->_unpack_leader( "peek" );

      $type == DATA_NUMBER or croak "Expected to unpack a number but did not find one";
      exists $format{$num} or $num == DATANUM_FLOAT16 or
         croak "Expected a float subtype but got $num";

      if( my $subtype = $self->SUBTYPE ) {
         $subtype == $num or croak "Expected float subtype $subtype, got $num";
      }

      return Tangence::Type::Primitive::float16->unpack_value( $message ) if $num == DATANUM_FLOAT16;

      $message->_unpack_leader; # no-peek

      my ( $n ) = unpack( $format{$num}[0], $message->_unpack( $format{$num}[1] ) );

      return $n;
   }
}

package
   Tangence::Type::Primitive::float16;
use base qw( Tangence::Type::Primitive::float );
use Carp;
use Tangence::Constants;

use constant SUBTYPE => DATANUM_FLOAT16;

# TODO: This code doesn't correctly cope with Inf, -Inf or NaN

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   defined $value or croak "cannot pack undef as float";
   ref $value and croak "$value is not a number";

   my $float32 = unpack( "N", pack "f>", $value );

   # float32 == 1 / 8 / 23
   my $sign   =   ( $float32 & 0x80000000 ) >> 31;
   my $exp    = ( ( $float32 & 0x7f800000 ) >> 23 ) - 127;
   my $mant32 =   ( $float32 & 0x007fffff );

   # float16 == 1 / 5 / 10
   my $mant16;

   if( $exp == 128 ) {
      # special value - Inf or NaN
      $exp = 16;
      $mant16 = $mant32 ? (1 << 9) : 0;
      $sign = 0 if $mant16;
   }
   elsif( $exp > 15 ) {
      # Too large - become Inf
      $exp = 16;
      $mant16 = 0;
   }
   elsif( $exp > -15 ) {
      $mant16 = $mant32 >> 13;
   }
   else {
      # zero or subnormal - become zero
      $exp = -15;
      $mant16 = 0;
   }

   my $float16 =   $sign       << 15 |
                 ( $exp + 15 ) << 10 |
                   $mant16;

   $message->_pack_leader( DATA_NUMBER, DATANUM_FLOAT16 );
   $message->_pack( pack "n", $float16 );
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my ( $type, $num ) = $message->_unpack_leader;

   $type == DATA_NUMBER or croak "Expected to unpack a number but did not find one";
   $num == DATANUM_FLOAT16 or croak "Expected to unpack a float16 but found $num";

   my $float16 = unpack "n", $message->_unpack( 2 );

   # float16 == 1 / 5 / 10
   my $sign   =   ( $float16 & 0x8000 ) >> 15;
   my $exp    = ( ( $float16 & 0x7c00 ) >> 10 ) - 15;
   my $mant16 =   ( $float16 & 0x03ff );

   # float32 == 1 / 8 / 23
   my $mant32;

   if( $exp == 16 ) {
      # special value - Inf or NaN
      $exp = 128;
      $mant32 = $mant16 ? (1 << 22) : 0;
   }
   elsif( $exp > -15 ) {
      $mant32 = $mant16 << 13;
   }
   else {
      # zero
      $exp = -127;
      $mant32 = 0;
   }

   my $float32 =   $sign        << 31 |
                 ( $exp + 127 ) << 23 |
                   $mant32;

   return unpack( "f>", pack "N", $float32 );
}

package
   Tangence::Type::Primitive::float32;
use base qw( Tangence::Type::Primitive::float );
use Tangence::Constants;

use constant SUBTYPE => DATANUM_FLOAT32;

package
   Tangence::Type::Primitive::float64;
use base qw( Tangence::Type::Primitive::float );
use Tangence::Constants;

use constant SUBTYPE => DATANUM_FLOAT64;

package
   Tangence::Type::Primitive::str;
use base qw( Tangence::Type::Primitive );
use Carp;
use Encode qw( encode_utf8 decode_utf8 );
use Tangence::Constants;

sub default_value { "" }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   defined $value or croak "cannot pack_str(undef)";
   ref $value and croak "$value is not a string";
   my $octets = encode_utf8( $value );
   $message->_pack_leader( DATA_STRING, length($octets) );
   $message->_pack( $octets );
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my ( $type, $num ) = $message->_unpack_leader();

   $type == DATA_STRING or croak "Expected to unpack a string but did not find one";
   my $octets = $message->_unpack( $num );
   return decode_utf8( $octets );
}

package
   Tangence::Type::Primitive::obj;
use base qw( Tangence::Type::Primitive );
use Carp;
use Scalar::Util qw( blessed );
use Tangence::Constants;

sub default_value { undef }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   my $stream = $message->stream;

   if( !defined $value ) {
      $message->_pack_leader( DATA_OBJECT, 0 );
   }
   elsif( blessed $value and $value->isa( "Tangence::Object" ) ) {
      my $id = $value->id;
      my $preamble = "";

      $value->{destroyed} and croak "Cannot pack destroyed object $value";

      $message->packmeta_construct( $value ) unless $stream->peer_hasobj->{$id};

      $message->_pack_leader( DATA_OBJECT, 4 );
      $message->_pack( pack( "N", $id ) );
   }
   elsif( blessed $value and $value->isa( "Tangence::ObjectProxy" ) ) {
      $message->_pack_leader( DATA_OBJECT, 4 );
      $message->_pack( pack( "N", $value->id ) );
   }
   else {
      croak "Do not know how to pack a " . ref($value);
   }
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my ( $type, $num ) = $message->_unpack_leader();

   my $stream = $message->stream;

   $type == DATA_OBJECT or croak "Expected to unpack an object but did not find one";
   return undef unless $num;
   if( $num == 4 ) {
      my ( $id ) = unpack( "N", $message->_unpack( 4 ) );
      return $stream->get_by_id( $id );
   }
   else {
      croak "Unexpected number of bits to encode an OBJECT";
   }
}

package
   Tangence::Type::Primitive::any;
use base qw( Tangence::Type::Primitive );
use Carp;
use Scalar::Util qw( blessed );
use Tangence::Constants;

# We can't use Tangence::Types here without a dependency cycle
# However, it's OK to create even TYPE_ANY right here, because the 'any' class
# now exists.
use constant TYPE_BOOL  => Tangence::Type->new( 'bool' );
use constant TYPE_INT   => Tangence::Type->new( 'int' );
use constant TYPE_FLOAT => Tangence::Type->new( 'float' );
use constant TYPE_STR   => Tangence::Type->new( 'str' );
use constant TYPE_OBJ   => Tangence::Type->new( 'obj' );
use constant TYPE_ANY   => Tangence::Type->new( 'any' );

use constant TYPE_LIST_ANY => Tangence::Type->new( list => TYPE_ANY );
use constant TYPE_DICT_ANY => Tangence::Type->new( dict => TYPE_ANY );

sub default_value { undef }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   if( !defined $value ) {
      TYPE_OBJ->pack_value( $message, undef );
   }
   elsif( !ref $value ) {
      no warnings 'numeric';

      # use  X^X  operator to distinguish actual numbers from strings
      my $is_numeric = ( $value ^ $value ) eq "0";

      # test for integers, but exclude NaN
      if( int($value) eq $value and $value == $value ) {
         TYPE_INT->pack_value( $message, $value );
      }
      elsif( $message->stream->_ver_can_num_float and $is_numeric ) {
         TYPE_FLOAT->pack_value( $message, $value );
      }
      else {
         TYPE_STR->pack_value( $message, $value );
      }
   }
   elsif( blessed $value and $value->isa( "Tangence::Object" ) || $value->isa( "Tangence::ObjectProxy" ) ) {
      TYPE_OBJ->pack_value( $message, $value );
   }
   elsif( my $struct = eval { Tangence::Struct->for_perlname( ref $value ) } ) {
      $message->pack_record( $value, $struct );
   }
   elsif( ref $value eq "ARRAY" ) {
      TYPE_LIST_ANY->pack_value( $message, $value );
   }
   elsif( ref $value eq "HASH" ) {
      TYPE_DICT_ANY->pack_value( $message, $value );
   }
   else {
      croak "Do not know how to pack a " . ref($value);
   }
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my $type = $message->_peek_leader_type();

   if( $type == DATA_NUMBER ) {
      my ( undef, $num ) = $message->_unpack_leader( "peek" );
      if( $num >= DATANUM_BOOLFALSE and $num <= DATANUM_BOOLTRUE ) {
         return TYPE_BOOL->unpack_value( $message );
      }
      elsif( $num >= DATANUM_UINT8 and $num <= DATANUM_SINT64 ) {
         return TYPE_INT->unpack_value( $message );
      }
      elsif( $num >= DATANUM_FLOAT16 and $num <= DATANUM_FLOAT64 ) {
         return TYPE_FLOAT->unpack_value( $message );
      }
      else {
         croak "Do not know how to unpack DATA_NUMBER subtype $num";
      }
   }
   if( $type == DATA_STRING ) {
      return TYPE_STR->unpack_value( $message );
   }
   elsif( $type == DATA_OBJECT ) {
      return TYPE_OBJ->unpack_value( $message );
   }
   elsif( $type == DATA_LIST ) {
      return TYPE_LIST_ANY->unpack_value( $message );
   }
   elsif( $type == DATA_DICT ) {
      return TYPE_DICT_ANY->unpack_value( $message );
   }
   elsif( $type == DATA_RECORD ) {
      return $message->unpack_record( undef );
   }
   else {
      croak "Do not know how to unpack record of type $type";
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
