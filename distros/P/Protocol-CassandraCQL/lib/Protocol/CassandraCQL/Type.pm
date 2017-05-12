#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Protocol::CassandraCQL::Type;

use strict;
use warnings;

our $VERSION = '0.12';

use Carp;

use Encode ();

use Protocol::CassandraCQL qw( :types );
use Protocol::CassandraCQL::Frame; # collection types use it for encoding/decoding

use constant HAVE_INT64 => eval { pack( "q>", 1 ) eq "\0\0\0\0\0\0\0\1" };

=head1 NAME

C<Protocol::CassandraCQL::Type> - represents a Cassandra CQL data type

=head1 DESCRIPTION

Objects in this class represent distinct types that may be found in Cassandra
CQL3, either as columns in query result rows, or as bind parameters to
prepared statements. It is used by L<Protocol::CassandraCQL::ColumnMeta>.

=cut

=head1 CONSTRUCTOR

=head2 $type = Protocol::CassandraCQL::Type->from_frame( $frame )

Returns a new type object initialised by parsing the type information in the
given message frame.

=cut

sub from_frame
{
   shift; # ignore
   my ( $frame ) = @_;

   my $typeid = $frame->unpack_short;
   my $class = "Protocol::CassandraCQL::Type::" . Protocol::CassandraCQL::typename( $typeid );

   if( $class->can( "from_frame" ) != \&from_frame ) {
      return $class->from_frame( @_ );
   }
   elsif( $class->can( "new" ) ) {
      return $class->new;
   }

   die "TODO: Unrecognised typeid $typeid";
}

# Just for unit testing
# This and the LIST/MAP from_name methods form a simple incremental parser
sub from_name
{
   shift;

   $_[0] =~ s/^([^<,>]+)//;
   my $name = $1;
   my $class = "Protocol::CassandraCQL::Type::$name";

   if( $class->can( "from_name" ) != \&from_name ) {
      return $class->from_name( @_ );
   }
   elsif( $class->can( "new" ) ) {
      return $class->new;
   }

   die "Unrecognised type name '$name'";
}

sub new
{
   my $class = shift;
   return bless [], $class;
}

=head1 METHODS

=cut

=head2 $name = $type->name

Returns a string representation of the type name.

=cut

sub name
{
   my $self = shift;
   return +( ( ref $self ) =~ m/::([^:]+)$/ )[0];
}

=head2 $bytes = $type->encode( $v )

Encodes the given perl data into a bytestring.

=head2 $v = $type->decode( $bytes )

Decodes the given bytestring into perl data.

=cut

=head2 $message = $type->validate( $v )

Validates whether the given perl data is valid for this type. If so, returns
false. Otherwise, returns an error message explaining why.

=cut

#      if( $typeid == TYPE_CUSTOM ) {
#         push @col, $frame->unpack_string;
#      }

#   my ( $typeid, $custom ) = @{ $self->{columns}[$idx] }[4,5];
#   return $custom if $typeid == TYPE_CUSTOM;

# Now the codecs

package
   Protocol::CassandraCQL::Type::_numeric;
use base qw( Protocol::CassandraCQL::Type );
use Scalar::Util qw( looks_like_number );
sub validate { !looks_like_number($_[1]) ? "not a number" : undef }

package
   Protocol::CassandraCQL::Type::_integral;
use base qw( Protocol::CassandraCQL::Type::_numeric );
sub validate { $_[0]->SUPER::validate($_[1]) or
               $_[1] != int($_[1]) ? "not an integer" : undef }

# ASCII-only bytes
package Protocol::CassandraCQL::Type::ASCII;
use base qw( Protocol::CassandraCQL::Type );
sub validate { $_[1] =~ m/[^\x00-\x7f]/ ? "non-ASCII" : undef }
sub encode { $_[1] }
sub decode { $_[1] }

# 64-bit integer
package Protocol::CassandraCQL::Type::BIGINT;
use base qw( Protocol::CassandraCQL::Type::_integral );
if( Protocol::CassandraCQL::Type::HAVE_INT64 ) {
   *encode = sub { pack   "q>", $_[1] };
   *decode = sub { unpack "q>", $_[1] };
}
else {
   require Math::Int64;
   *encode = sub { Math::Int64::int64_to_net( $_[1] ) };
   *decode = sub { Math::Int64::net_to_int64( $_[1] ) };
}

# blob
package Protocol::CassandraCQL::Type::BLOB;
use base qw( Protocol::CassandraCQL::Type );
sub validate { undef }
sub encode { $_[1] }
sub decode { $_[1] }

# true/false byte
package Protocol::CassandraCQL::Type::BOOLEAN;
use base qw( Protocol::CassandraCQL::Type );
sub validate { undef }
sub encode { pack   "C", !!$_[1] }
sub decode { !!unpack "C", $_[1] }

# counter is a 64-bit integer
package Protocol::CassandraCQL::Type::COUNTER;
use base qw( Protocol::CassandraCQL::Type::BIGINT );

# Not clearly docmuented, but this appears to be an INT decimal shift followed
# by a VARINT
package Protocol::CassandraCQL::Type::DECIMAL;
use base qw( Protocol::CassandraCQL::Type::_numeric );
use Scalar::Util qw( blessed );
sub encode {
   require Math::BigFloat;
   my $shift = $_[1] =~ m/\.(\d*)$/ ? length $1 : 0;
   my $n = blessed $_[1] ? $_[1] : Math::BigFloat->new( $_[1] );
   return pack( "L>", $shift ) . Protocol::CassandraCQL::Type::VARINT->encode( $n->blsft($shift, 10) );
}
sub decode {
   require Math::BigFloat;
   my $shift = unpack "L>", $_[1];
   my $n = Protocol::CassandraCQL::Type::VARINT->decode( substr $_[1], 4 );
   return scalar Math::BigFloat->new($n)->brsft($shift, 10);
}

# IEEE double
package Protocol::CassandraCQL::Type::DOUBLE;
use base qw( Protocol::CassandraCQL::Type::_numeric );
sub encode { pack   "d>", $_[1] }
sub decode { unpack "d>", $_[1] }

# IEEE single
package Protocol::CassandraCQL::Type::FLOAT;
use base qw( Protocol::CassandraCQL::Type::_numeric );
sub encode { pack   "f>", $_[1] }
sub decode { unpack "f>", $_[1] }

# 32-bit integer
package Protocol::CassandraCQL::Type::INT;
use base qw( Protocol::CassandraCQL::Type::_integral );
sub encode { pack   "l>", $_[1] }
sub decode { unpack "l>", $_[1] }

# UTF-8 text
package Protocol::CassandraCQL::Type::VARCHAR;
use base qw( Protocol::CassandraCQL::Type );
sub validate { undef } # TODO: maybe we can check for invalid codepoints?
sub encode { Encode::encode_utf8 $_[1] }
sub decode { Encode::decode_utf8 $_[1] }

# 'text' seems to come back as 'varchar'
package Protocol::CassandraCQL::Type::TEXT;
use base qw( Protocol::CassandraCQL::Type::VARCHAR );

# miliseconds since UNIX epoch as 64bit uint
package Protocol::CassandraCQL::Type::TIMESTAMP;
use base qw( Protocol::CassandraCQL::Type::_integral );
if( Protocol::CassandraCQL::Type::HAVE_INT64 ) {
   *encode = sub {  pack   "Q>", ($_[1] * 1000) };
   *decode = sub { (unpack "Q>", $_[1]) / 1000  };
}
else {
   require Math::Int64;
   *encode = sub {  Math::Int64::uint64_to_net( $_[1] * 1000 ) };
   *decode = sub { (Math::Int64::net_to_uint64( $_[1] )) / 1000 };
}

# UUID is just a hex string - accept 32 hex digits, hypens optional
package Protocol::CassandraCQL::Type::UUID;
use base qw( Protocol::CassandraCQL::Type );
sub validate { ( my $hex = $_[1] ) =~ s/-//g;
               $hex !~ m/^[0-9A-F]{32}$/i ? "expected 32 hex digits" : undef }
sub encode { ( my $hex = $_[1] ) =~ s/-//g; pack "H32", $hex }
sub decode { join "-", unpack "H8 H4 H4 H4 H12", $_[1] }

package Protocol::CassandraCQL::Type::TIMEUUID;
use base qw( Protocol::CassandraCQL::Type::UUID );

# Arbitrary-precision 2s-complement signed integer
# Math::BigInt doesn't handle signed, but we can mangle it
package Protocol::CassandraCQL::Type::VARINT;
use base qw( Protocol::CassandraCQL::Type::_integral );
use Scalar::Util qw( blessed );
sub encode {
   require Math::BigInt;
   my $n = blessed $_[1] ? $_[1] : Math::BigInt->new($_[1]); # upgrade to a BigInt

   my $bytes;
   if( $n < 0 ) {
      my $hex = substr +(-$n-1)->as_hex, 2;
      $hex = "0$hex" if length($hex) % 2;
      $bytes = ~(pack "H*", $hex);
      # Sign-extend if required to avoid appearing positive
      $bytes = "\xff$bytes" if unpack( "C", $bytes ) < 0x80;
   }
   else {
      my $hex = substr $n->as_hex, 2; # trim 0x
      $hex = "0$hex" if length($hex) % 2;
      $bytes = pack "H*", $hex;
      # Zero-extend if required to avoid appearing negative
      $bytes = "\0$bytes" if unpack( "C", $bytes ) >= 0x80;
   }
   $bytes;
}
sub decode {
   require Math::BigInt;

   if( unpack( "C", $_[1] ) >= 0x80 ) {
      return -Math::BigInt->from_hex( "0x" . unpack "H*", ~$_[1] ) - 1;
   }
   else {
      return Math::BigInt->from_hex( "0x" . unpack "H*", $_[1] );
   }
}

# 4 (AF_INET) or 16 (AF_INET6) byte address
package Protocol::CassandraCQL::Type::INET;
use base qw( Protocol::CassandraCQL::Type );
sub validate { length($_[1]) ==  4 and return;
               length($_[1]) == 16 and return;
               "expected 4 bytes (AF_INET) or 16 bytes (AF_INET6)" }
sub encode { $_[1] }
sub decode { $_[1] }

=head1 COLLECTION TYPES

=head2 $etype = $type->element_type

Returns the type of the elements in the list or set, for C<LIST> and C<SET>
types.

=head2 $ktype = $type->key_type

=head2 $vtype = $type->value_type

Returns the type of the keys and values in the map, for C<MAP> types.

=cut

package Protocol::CassandraCQL::Type::LIST;
use base qw( Protocol::CassandraCQL::Type );
sub from_frame {
   my $class = shift;
   my $etype = Protocol::CassandraCQL::Type->from_frame( @_ );
   bless [ $etype ], $class;
}
sub from_name {
   my $class = shift;
   $_[0] =~ s/^<// or die "Expected '<' following collection name\n";
   my $etype = Protocol::CassandraCQL::Type->from_name( @_ );
   $_[0] =~ s/^>// or die "Expected '>' following collection element type\n";
   bless [ $etype ], $class;
}
sub element_type { $_[0][0] }
sub name { $_[0]->SUPER::name . "<" . $_[0][0]->name . ">" }
sub validate {
   my $l = $_[1];
   eval { @$l } or return "not an ARRAY";
   my $etype = $_[0][0];
   my $e; $e = $etype->validate( $l->[$_] ) and return "[$_]: $e" for 0 .. $#$l;
   undef;
}
sub encode {
   my $l = $_[1];
   my $etype = $_[0][0];
   my $f = Protocol::CassandraCQL::Frame->new
      ->pack_short( scalar @$l );
   foreach my $i ( 0 .. $#$l ) {
      $f->pack_short_bytes( $etype->encode( $l->[$i] ) );
   }
   $f->bytes
}
sub decode {
   local $_;
   my $etype = $_[0][0];
   my $f = Protocol::CassandraCQL::Frame->new( $_[1] );
   my $n = $f->unpack_short;
   return [ map { $etype->decode( $f->unpack_short_bytes ) } 1 .. $n ]
}

package Protocol::CassandraCQL::Type::MAP;
use base qw( Protocol::CassandraCQL::Type );
sub from_frame {
   my $class = shift;
   my $ktype = Protocol::CassandraCQL::Type->from_frame( @_ );
   my $vtype = Protocol::CassandraCQL::Type->from_frame( @_ );
   bless [ $ktype, $vtype ], $class;
}
sub from_name {
   my $class = shift;
   $_[0] =~ s/^<// or die "Expected '<' following collection name\n";
   my $ktype = Protocol::CassandraCQL::Type->from_name( @_ );
   $_[0] =~ s/^,// or die "Expected ',' following collection key type\n";
   my $vtype = Protocol::CassandraCQL::Type->from_name( @_ );
   $_[0] =~ s/^>// or die "Expected '>' following collection value type\n";
   bless [ $ktype, $vtype ], $class;
}
sub key_type   { $_[0][0] }
sub value_type { $_[0][1] }
sub name { $_[0]->SUPER::name . "<" . $_[0][0]->name . "," . $_[0][1]->name . ">" }
sub validate {
   my $m = $_[1];
   eval { %$m } or return "not a HASH";
   my $vtype = $_[0][1];
   my $e; $e = $vtype->validate( $m->{$_} ) and return "{$_}: $e" for keys %$m;
   undef;
}
sub encode {
   my $m = $_[1];
   my $ktype = $_[0][0];
   my $vtype = $_[0][1];
   my $f = Protocol::CassandraCQL::Frame->new
      ->pack_short( scalar keys %$m );
   foreach my $k ( keys %$m ) {
      $f->pack_short_bytes( $ktype->encode( $k ) );
      $f->pack_short_bytes( $vtype->encode( $m->{$k} ) );
   }
   $f->bytes
}
sub decode {
   local $_;
   my $ktype = $_[0][0];
   my $vtype = $_[0][1];
   my $f = Protocol::CassandraCQL::Frame->new( $_[1] );
   my $n = $f->unpack_short;
   return { map { $ktype->decode( $f->unpack_short_bytes ),
                  $vtype->decode( $f->unpack_short_bytes ) } 1 .. $n }
}

# We just represent a SET as a LIST - use an ARRAY of elements
package Protocol::CassandraCQL::Type::SET;
use base qw( Protocol::CassandraCQL::Type::LIST );

=head1 DATA ENCODINGS

The following encodings to and from perl data are supported:

=head2 ASCII

To or from a string scalar, which must contain only US-ASCII codepoints (i.e.
C<ord> <= 127).

=head2 BIGINT, BOOLEAN, COUNTER, DECIMAL, FLOAT, INT

To or from a numeric scalar.

=head2 BLOB

To or from an opaque string scalar of bytes.

=head2 DECIMAL

To or from an instance of L<Math::BigFloat>, or from a regular numeric scalar.

=head2 TIMESTAMP

To or from a numeric scalar, representing a UNIX epoch timestamp as a float to
the nearest milisecond.

=head2 UUID, TIMEUUID

To or from a string containing hex digits and hyphens, in the form
C<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>.

=head2 VARCHAR

To or from a string scalar containing Unicode characters.

=head2 VARINT

To or from an instance of L<Math::BigInt>, or from a regular numeric scalar.

=head2 LIST, SET

To or from an C<ARRAY> reference containing elements.

=head2 MAP

To or from a C<HASH> reference, where the keys used must be of some string
type.

=cut

=head1 SPONSORS

This code was paid for by

=over 2

=item *

Perceptyx L<http://www.perceptyx.com/>

=item *

Shadowcat Systems L<http://www.shadow.cat>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
