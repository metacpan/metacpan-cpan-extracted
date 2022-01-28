#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.41;

package Tangence::Type 0.28;
class Tangence::Type isa Tangence::Meta::Type;

=head1 NAME

C<Tangence::Type> - represent a C<Tangence> value type

=head1 DESCRIPTION

Objects in this class represent individual types that are sent over the wire
in L<Tangence> messages. This is a subclass of L<Tangence::Meta::Type> which
provides additional methods that may be useful in server or client
implementations.

=cut

=head1 CONSTRUCTOR

=head2 make

   $type = Tangence::Type->make( $primitive_sig )

Returns an instance to represent a primitive type of the given signature.

   $type = Tangence::Type->make( list => $member_type )

   $type = Tangence::Type->make( dict => $member_type )

Returns an instance to represent a list or dict aggregation containing members
of the given type.

=cut

sub make
{
   # Subtle trickery is at work here
   # Invoke our own superclass constructor, but pretend to be some higher
   # subclass that's appropriate

   shift;
   if( @_ == 1 ) {
      my ( $type ) = @_;
      my $class = "Tangence::Type::Primitive::$type";
      $class->can( "make" ) or die "TODO: Need $class";

      return $class->SUPER::make( $type );
   }
   elsif( $_[0] eq "list" ) {
      shift;
      return Tangence::Type::List->SUPER::make( list => @_ );
   }
   elsif( $_[0] eq "dict" ) {
      shift;
      return Tangence::Type::Dict->SUPER::make( dict => @_ );
   }
   else {
      die "TODO: Not sure how to make a Tangence::Type->make( @_ )";
   }
}

=head1 METHODS

=head2 default_value

   $value = $type->default_value

Returns a value suitable to use as an initial value for object properties.

=head2 pack_value

   $type->pack_value( $message, $value )

Appends a value of this type to the end of a L<Tangence::Message>.

=head2 unpack_value

   $value = $type->unpack_value( $message )

Removes a value of this type from the start of a L<Tangence::Message>.

=cut

class Tangence::Type::List isa Tangence::Type
{
   use Carp;
   use Tangence::Constants;

   method default_value { [] }

   method pack_value ( $message, $value )
   {
      ref $value eq "ARRAY" or croak "Cannot pack a list from non-ARRAY reference";

      $message->_pack_leader( DATA_LIST, scalar @$value );

      my $member_type = $self->member_type;
      $member_type->pack_value( $message, $_ ) for @$value;
   }

   method unpack_value ( $message )
   {
      my ( $type, $num ) = $message->_unpack_leader();
      $type == DATA_LIST or croak "Expected to unpack a list but did not find one";

      my $member_type = $self->member_type;
      my @values;
      foreach ( 1 .. $num ) {
         push @values, $member_type->unpack_value( $message );
      }

      return \@values;
   }
}

class Tangence::Type::Dict isa Tangence::Type
{
   use Carp;
   use Tangence::Constants;

   method default_value { {} }

   method pack_value ( $message, $value )
   {
      ref $value eq "HASH" or croak "Cannot pack a dict from non-HASH reference";

      my @keys = keys %$value;
      @keys = sort @keys if $Tangence::Message::SORT_HASH_KEYS;

      $message->_pack_leader( DATA_DICT, scalar @keys );

      my $member_type = $self->member_type;
      $message->pack_str( $_ ), $member_type->pack_value( $message, $value->{$_} ) for @keys;
   }

   method unpack_value ( $message )
   {
      my ( $type, $num ) = $message->_unpack_leader();
      $type == DATA_DICT or croak "Expected to unpack a dict but did not find one";

      my $member_type = $self->member_type;
      my %values;
      foreach ( 1 .. $num ) {
         my $key = $message->unpack_str();
         $values{$key} = $member_type->unpack_value( $message );
      }

      return \%values;
   }
}

class Tangence::Type::Primitive::bool isa Tangence::Type
{
   use Carp;
   use Tangence::Constants;

   method default_value { "" }

   method pack_value ( $message, $value )
   {
      $message->_pack_leader( DATA_NUMBER, $value ? DATANUM_BOOLTRUE : DATANUM_BOOLFALSE );
   }

   method unpack_value ( $message )
   {
      my ( $type, $num ) = $message->_unpack_leader();

      $type == DATA_NUMBER or croak "Expected to unpack a number(bool) but did not find one";
      $num == DATANUM_BOOLFALSE and return !!0;
      $num == DATANUM_BOOLTRUE  and return !!1;
      croak "Expected to find a DATANUM_BOOL subtype but got $num";
   }
}

class Tangence::Type::Primitive::_integral isa Tangence::Type
{
   use Carp;
   use Tangence::Constants;

   use constant SUBTYPE => undef;

   method default_value { 0 }

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

   sub _best_int_type_for ( $n )
   {
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

   method pack_value ( $message, $value )
   {
      defined $value or croak "cannot pack_int(undef)";
      ref $value and croak "$value is not a number";
      $value == $value or croak "cannot pack_int(NaN)";
      $value == "+Inf" || $value == "-Inf" and croak "cannot pack_int(Inf)";

      my $subtype = $self->SUBTYPE || _best_int_type_for( $value );
      $message->_pack_leader( DATA_NUMBER, $subtype );

      $message->_pack( pack( $format{$subtype}[0], $value ) );
   }

   method unpack_value ( $message )
   {
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

class Tangence::Type::Primitive::u8 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_UINT8;
}

class Tangence::Type::Primitive::s8 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_SINT8;
}

class Tangence::Type::Primitive::u16 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_UINT16;
}

class Tangence::Type::Primitive::s16 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_SINT16;
}

class Tangence::Type::Primitive::u32 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_UINT32;
}

class Tangence::Type::Primitive::s32 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_SINT32;
}

class Tangence::Type::Primitive::u64 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_UINT64;
}

class Tangence::Type::Primitive::s64 isa Tangence::Type::Primitive::_integral
{
   use constant SUBTYPE => Tangence::Constants::DATANUM_SINT64;
}

class Tangence::Type::Primitive::int isa Tangence::Type::Primitive::_integral
{
   # empty
}

class Tangence::Type::Primitive::float isa Tangence::Type
{
   use Carp;
   use Tangence::Constants;

   my $TYPE_FLOAT16 = Tangence::Type->make( 'float16' );

   use constant SUBTYPE => undef;

   method default_value { 0.0 }

   my %format = (
                     #   pack, bytes, NaN
      DATANUM_FLOAT32, [ "f>", 4,     "\x7f\xc0\x00\x00" ],
      DATANUM_FLOAT64, [ "d>", 8,     "\x7f\xf8\x00\x00\x00\x00\x00\x00" ],
   );

   sub _best_type_for ( $value )
   {
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

   method pack_value ( $message, $value )
   {
      defined $value or croak "cannot pack undef as float";
      ref $value and croak "$value is not a number";

      my $subtype = $self->SUBTYPE || _best_type_for( $value );

      return $TYPE_FLOAT16->pack_value( $message, $value ) if $subtype == DATANUM_FLOAT16;

      $message->_pack_leader( DATA_NUMBER, $subtype );
      $message->_pack( $value == $value ?
         pack( $format{$subtype}[0], $value ) : $format{$subtype}[2]
      );
   }

   method unpack_value ( $message )
   {
      my ( $type, $num ) = $message->_unpack_leader( "peek" );

      $type == DATA_NUMBER or croak "Expected to unpack a number but did not find one";
      exists $format{$num} or $num == DATANUM_FLOAT16 or
         croak "Expected a float subtype but got $num";

      if( my $subtype = $self->SUBTYPE ) {
         $subtype == $num or croak "Expected float subtype $subtype, got $num";
      }

      return $TYPE_FLOAT16->unpack_value( $message ) if $num == DATANUM_FLOAT16;

      $message->_unpack_leader; # no-peek

      my ( $n ) = unpack( $format{$num}[0], $message->_unpack( $format{$num}[1] ) );

      return $n;
   }
}

class Tangence::Type::Primitive::float16 isa Tangence::Type::Primitive::float
{
   use Carp;
   use Tangence::Constants;

   use constant SUBTYPE => DATANUM_FLOAT16;

   # TODO: This code doesn't correctly cope with Inf, -Inf or NaN

   method pack_value ( $message, $value )
   {
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

   method unpack_value ( $message )
   {
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
}

class Tangence::Type::Primitive::float32 isa Tangence::Type::Primitive::float
{
   use Tangence::Constants;

   use constant SUBTYPE => DATANUM_FLOAT32;
}

class Tangence::Type::Primitive::float64 isa Tangence::Type::Primitive::float
{
   use Tangence::Constants;

   use constant SUBTYPE => DATANUM_FLOAT64;
}

class Tangence::Type::Primitive::str isa Tangence::Type
{
   use Carp;
   use Encode qw( encode_utf8 decode_utf8 );
   use Tangence::Constants;

   method default_value { "" }

   method pack_value ( $message, $value )
   {
      defined $value or croak "cannot pack_str(undef)";
      ref $value and croak "$value is not a string";
      my $octets = encode_utf8( $value );
      $message->_pack_leader( DATA_STRING, length($octets) );
      $message->_pack( $octets );
   }

   method unpack_value ( $message )
   {
      my ( $type, $num ) = $message->_unpack_leader();

      $type == DATA_STRING or croak "Expected to unpack a string but did not find one";
      my $octets = $message->_unpack( $num );
      return decode_utf8( $octets );
   }
}

class Tangence::Type::Primitive::obj isa Tangence::Type
{
   use Carp;
   use Scalar::Util qw( blessed );
   use Tangence::Constants;

   method default_value { undef }

   method pack_value ( $message, $value )
   {
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

   method unpack_value ( $message )
   {
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
}

class Tangence::Type::Primitive::any isa Tangence::Type
{
   use Carp;
   use Scalar::Util qw( blessed );
   use Tangence::Constants;

   use Syntax::Keyword::Match;

   no if $] >= 5.035008, warnings => "experimental::builtin";
   use constant HAVE_ISBOOL => defined &builtin::isbool;

   my $TYPE_BOOL  = Tangence::Type->make( 'bool' );
   my $TYPE_INT   = Tangence::Type->make( 'int' );
   my $TYPE_FLOAT = Tangence::Type->make( 'float' );
   my $TYPE_STR   = Tangence::Type->make( 'str' );
   my $TYPE_OBJ   = Tangence::Type->make( 'obj' );
   my $TYPE_ANY   = Tangence::Type->make( 'any' );

   my $TYPE_LIST_ANY = Tangence::Type->make( list => $TYPE_ANY );
   my $TYPE_DICT_ANY = Tangence::Type->make( dict => $TYPE_ANY );

   method default_value { undef }

   method pack_value ( $message, $value )
   {
      if( !defined $value ) {
         $TYPE_OBJ->pack_value( $message, undef );
      }
      elsif( !ref $value ) {
         no warnings 'numeric';

         my $is_numeric = do {
            my $tmp = $value;

            # use  X^X  operator to distinguish actual numbers from strings
            # If $tmp contains any non-ASCII bytes the it's definitely not a
            # decimal representation of a number
            $tmp =~ m/^[[:ascii:]]+$/ and ( $value ^ $value ) eq "0"
         };

         if( HAVE_ISBOOL && builtin::isbool($value) ) {
            $TYPE_BOOL->pack_value( $message, $value );
         }
         # test for integers, but exclude NaN
         elsif( int($value) eq $value and $value == $value ) {
            $TYPE_INT->pack_value( $message, $value );
         }
         elsif( $message->stream->_ver_can_num_float and $is_numeric ) {
            $TYPE_FLOAT->pack_value( $message, $value );
         }
         else {
            $TYPE_STR->pack_value( $message, $value );
         }
      }
      elsif( blessed $value and $value->isa( "Tangence::Object" ) || $value->isa( "Tangence::ObjectProxy" ) ) {
         $TYPE_OBJ->pack_value( $message, $value );
      }
      elsif( my $struct = eval { Tangence::Struct->for_perlname( ref $value ) } ) {
         $message->pack_record( $value, $struct );
      }
      elsif( ref $value eq "ARRAY" ) {
         $TYPE_LIST_ANY->pack_value( $message, $value );
      }
      elsif( ref $value eq "HASH" ) {
         $TYPE_DICT_ANY->pack_value( $message, $value );
      }
      else {
         croak "Do not know how to pack a " . ref($value);
      }
   }

   method unpack_value ( $message )
   {
      my $type = $message->_peek_leader_type();

      match( $type : == ) {
         case( DATA_NUMBER ) {
            my ( undef, $num ) = $message->_unpack_leader( "peek" );
            if( $num >= DATANUM_BOOLFALSE and $num <= DATANUM_BOOLTRUE ) {
               return $TYPE_BOOL->unpack_value( $message );
            }
            elsif( $num >= DATANUM_UINT8 and $num <= DATANUM_SINT64 ) {
               return $TYPE_INT->unpack_value( $message );
            }
            elsif( $num >= DATANUM_FLOAT16 and $num <= DATANUM_FLOAT64 ) {
               return $TYPE_FLOAT->unpack_value( $message );
            }
            else {
               croak "Do not know how to unpack DATA_NUMBER subtype $num";
            }
         }
         case( DATA_STRING ) {
            return $TYPE_STR->unpack_value( $message );
         }
         case( DATA_OBJECT ) {
            return $TYPE_OBJ->unpack_value( $message );
         }
         case( DATA_LIST ) {
            return $TYPE_LIST_ANY->unpack_value( $message );
         }
         case( DATA_DICT ) {
            return $TYPE_DICT_ANY->unpack_value( $message );
         }
         case( DATA_RECORD ) {
            return $message->unpack_record( undef );
         }
         default {
            croak "Do not know how to unpack record of type $type";
         }
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
