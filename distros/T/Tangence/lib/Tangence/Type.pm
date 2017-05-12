#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2014 -- leonerd@leonerd.org.uk

package Tangence::Type;

use strict;
use warnings;

use base qw( Tangence::Meta::Type );

require Tangence::Type::Primitive;

=head1 NAME

C<Tangence::Type> - represent a C<Tangence> value type

=head1 DESCRIPTION

Objects in this class represent individual types that are sent over the wire
in L<Tangence> messages. This is a subclass of L<Tangence::Meta::Type> which
provides additional methods that may be useful in server or client
implementations.

=cut

=head1 CONSTRUCTOR

=head2 $type = Tangence::Type->new( $primitive_sig )

Returns an instance to represent a primitive type of the given signature.

=head2 $type = Tangence::Type->new( list => $member_type )

=head2 $type = Tangence::Type->new( dict => $member_type )

Returns an instance to represent a list or dict aggregation containing members
of the given type.

=cut

sub new
{
   # Subtle trickery is at work here
   # Invoke our own superclass constructor, but pretend to be some higher
   # subclass that's appropriate

   shift;
   if( @_ == 1 ) {
      my ( $type ) = @_;
      my $class = "Tangence::Type::Primitive::$type";
      $class->can( "new" ) or die "TODO: Need $class";

      return $class->SUPER::new( $type );
   }
   elsif( $_[0] eq "list" ) {
      shift;
      return Tangence::Type::List->SUPER::new( list => @_ );
   }
   elsif( $_[0] eq "dict" ) {
      shift;
      return Tangence::Type::Dict->SUPER::new( dict => @_ );
   }
   else {
      die "TODO: Not sure how to make a Tangence::Type->new( @_ )";
   }
}

=head1 METHODS

=head2 $value = $type->default_value

Returns a value suitable to use as an initial value for object properties.

=head2 $type->pack_value( $message, $value )

Appends a value of this type to the end of a L<Tangence::Message>.

=head2 $value = $type->unpack_value( $message )

Removes a value of this type from the start of a L<Tangence::Message>.

=cut

package
   Tangence::Type::List;
use base qw( Tangence::Type );
use Carp;
use Tangence::Constants;

sub default_value { [] }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   ref $value eq "ARRAY" or croak "Cannot pack a list from non-ARRAY reference";

   $message->_pack_leader( DATA_LIST, scalar @$value );

   my $member_type = $self->member_type;
   $member_type->pack_value( $message, $_ ) for @$value;
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

   my ( $type, $num ) = $message->_unpack_leader();
   $type == DATA_LIST or croak "Expected to unpack a list but did not find one";

   my $member_type = $self->member_type;
   my @values;
   foreach ( 1 .. $num ) {
      push @values, $member_type->unpack_value( $message );
   }

   return \@values;
}

package
   Tangence::Type::Dict;
use base qw( Tangence::Type );
use Carp;
use Tangence::Constants;

sub default_value { {} }

sub pack_value
{
   my $self = shift;
   my ( $message, $value ) = @_;

   ref $value eq "HASH" or croak "Cannot pack a dict from non-HASH reference";

   my @keys = keys %$value;
   @keys = sort @keys if $Tangence::Message::SORT_HASH_KEYS;

   $message->_pack_leader( DATA_DICT, scalar @keys );

   my $member_type = $self->member_type;
   $message->pack_str( $_ ), $member_type->pack_value( $message, $value->{$_} ) for @keys;
}

sub unpack_value
{
   my $self = shift;
   my ( $message ) = @_;

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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
