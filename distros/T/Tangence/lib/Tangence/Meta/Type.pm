#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Tangence::Meta::Type 0.33;
class Tangence::Meta::Type :strict(params);

use Carp;

=head1 NAME

C<Tangence::Meta::Type> - structure representing one C<Tangence> value type

=head1 DESCRIPTION

This data structure object represents information about a type, such as a
method or event argument, a method return value, or a property element type.

Due to their simple contents and immutable nature, these objects may be
implemented as singletons. Repeated calls to the constructor method for the
same type name will yield the same instance.

=cut

=head1 CONSTRUCTOR

=cut

=head2 make

   $type = Tangence::Meta::Type->make( $primitive )

Returns an instance to represent the given primitive type signature.

   $type = Tangence::Meta::Type->make( $aggregate => $member_type )

Returns an instance to represent the given aggregation of the given type
instance.

=cut

our %PRIMITIVES;
our %LISTS;
our %DICTS;

sub make
{
   my $class = shift;

   if( @_ == 1 ) {
      my ( $sig ) = @_;
      return $PRIMITIVES{$sig} //=
         $class->new( member_type => $sig );
   }
   elsif( @_ == 2 and $_[0] eq "list" ) {
      my ( undef, $membertype ) = @_;
      return $LISTS{$membertype->sig} //=
         $class->new( aggregate => "list", member_type => $membertype );
   }
   elsif( @_ == 2 and $_[0] eq "dict" ) {
      my ( undef, $membertype ) = @_;
      return $DICTS{$membertype->sig} //=
         $class->new( aggregate => "dict", member_type => $membertype );
   }

   die "TODO: @_";
}

=head2 make _from_sig

   $type = Tangence::Meta::Type->make_from_sig( $sig )

Parses the given full Tangence type signature and returns an instance to
represent it.

=cut

sub make_from_sig ( $class, $sig )
{
   $sig =~ m/^list\((.*)\)$/ and
      return $class->make( list => $class->make_from_sig( $1 ) );

   $sig =~ m/^dict\((.*)\)$/ and
      return $class->make( dict => $class->make_from_sig( $1 ) );

   return $class->make( $sig );
}

field $aggregate   :param :reader = "prim";
field $member_type :param;

=head1 ACCESSORS

=cut

=head2 aggregate

   $agg = $type->aggregate

Returns C<"prim"> for primitive types, or the aggregation name for list and
dict aggregate types.

=cut

=head2 member_type

   $member_type = $type->member_type

Returns the member type for aggregation types. Throws an exception for
primitive types.

=cut

method member_type
{
   die "Cannot return the member type for primitive types" if $aggregate eq "prim";
   return $member_type;
}

=head2 sig

   $sig = $type->sig

Returns the Tangence type signature for the type.

=cut

method sig
{
   return $self->${\"_sig_for_$aggregate"}();
}

method _sig_for_prim
{
   return $member_type;
}

method _sig_for_list
{
   return "list(" . $member_type->sig . ")";
}

method _sig_for_dict
{
   return "dict(" . $member_type->sig . ")";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
