#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012-2017 -- leonerd@leonerd.org.uk

package Tangence::Meta::Type;

use strict;
use warnings;

use Carp;

our $VERSION = '0.25';

=head1 NAME

C<Tangence::Meta::Type> - structure representing one C<Tangence> value type

=head1 DESCRIPTION

This data structure object represents information about a type, such as a
method or event argument, a method return value, or a property element type.

Due to their simple contents and immutable nature, these objects may be
implemented as singletons.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $type = Tangence::Meta::Type->new( $primitive )

Returns an instance to represent the given primitive type signature.

   $type = Tangence::Meta::Type->new( $aggregate => $member_type )

Returns an instance to represent the given aggregation of the given type
instance.

=cut

our %PRIMITIVES;
our %LISTS;
our %DICTS;

sub new
{
   my $class = shift;

   if( @_ == 1 ) {
      my ( $sig ) = @_;
      return $PRIMITIVES{$sig} ||= bless [ prim => $sig ], $class;
   }
   elsif( @_ == 2 and $_[0] eq "list" ) {
      my ( undef, $membertype ) = @_;
      return $LISTS{$membertype->sig} ||= bless [ list => $membertype ], $class;
   }
   elsif( @_ == 2 and $_[0] eq "dict" ) {
      my ( undef, $membertype ) = @_;
      return $DICTS{$membertype->sig} ||= bless [ dict => $membertype ], $class;
   }

   die "TODO: @_";
}

=head2 new_from_sig

   $type = Tangence::Meta::Type->new_from_sig( $sig )

Parses the given full Tangence type signature and returns an instance to
represent it.

=cut

sub new_from_sig
{
   my $class = shift;
   my ( $sig ) = @_;

   $sig =~ m/^list\((.*)\)$/ and
      return $class->new( list => $class->new_from_sig( $1 ) );

   $sig =~ m/^dict\((.*)\)$/ and
      return $class->new( dict => $class->new_from_sig( $1 ) );

   return $class->new( $sig );
}

=head1 ACCESSORS

=cut

=head2 aggregate

   $agg = $type->aggregate

Returns C<"prim"> for primitive types, or the aggregation name for list and
dict aggregate types.

=cut

sub aggregate
{
   my $self = shift;
   return $self->[0];
}

=head2 member_type

   $member_type = $type->member_type

Returns the member type for aggregation types. Throws an exception for
primitive types.

=cut

sub member_type
{
   my $self = shift;
   die "Cannot return the member type for primitive types" if $self->[0] eq "prim";
   return $self->[1];
}

=head2 sig

   $sig = $type->sig

Returns the Tangence type signature for the type.

=cut

sub sig
{
   my $self = shift;
   $self->${\"_sig_for_$self->[0]"}();
}

sub _sig_for_prim
{
   my $self = shift;
   return $self->[1];
}

sub _sig_for_list
{
   my $self = shift;
   return "list(" . $self->[1]->sig . ")";
}

sub _sig_for_dict
{
   my $self = shift;
   return "dict(" . $self->[1]->sig . ")";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
