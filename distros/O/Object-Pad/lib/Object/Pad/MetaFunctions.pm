#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Object::Pad::MetaFunctions 0.814;

use v5.18;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
   metaclass
   deconstruct_object
   ref_field
   get_field
);

BEGIN {
   if( defined &builtin::reftype ) {
      warnings->unimport( 'experimental::builtin' );
      builtin->import(qw( reftype ));
   }
   else {
      require Scalar::Util;
      Scalar::Util->import(qw( reftype ));
   }
}

=head1 NAME

C<Object::Pad::MetaFunctions> - utility functions for C<Object::Pad> classes

=head1 SYNOPSIS

=for highlighter language=perl

   use v5.36;
   use Object::Pad::MetaFunctions qw( deconstruct_object );

   sub debug_print_object ( $obj )
   {
      my ( $classname, @repr ) = deconstruct_object( $obj );

      say "An object of type $classname having:";

      foreach my ( $fieldname, $value ) ( @repr ) {
         printf "%30s = %s\n", $fieldname, $value;
      }
   }

=head1 DESCRIPTION

This module contains a number of miscellaneous utility functions for working
with L<Object::Pad>-based classes or instances thereof.

These functions all involve a certain amount of encapsulation-breaking into
the object instances being operated on. This sort of thing shouldn't be
encouraged in most regular code, but there can be occasions when it is useful;
such as debug printing of values, generic serialisation, or tightly-coupled
unit tests that wish to operate on the internals of the object instances they
test.

Therefore, use of these functions should be considered "last-resort". Consider
carefully the sorts of things you are trying to do with them, and whether this
kind of reaching into the internals of an object, bypassing all of its
interface encapsulation, is really the best technique to achieve your goal.

=head1 FUNCTIONS

=cut

=head2 metaclass

   $metaclass = metaclass( $obj );

I<Since version 0.67.>

Returns the L<Object::Pad::MOP::Class> metaclass associated with the class
that the object is an instance of.

=head2 deconstruct_object

   ( $classname, @repr ) = deconstruct_object( $obj );

I<Since version 0.67.>

Returns a list of perl values containing a representation of all the fields in
the object instance. This representation form may be useful for tasks such as
debug printing or serialisation of the instance. This list is prefixed by the
name of the class of instance as a plain string.

The exact form of this representation is still experimental and may change in
a later version. Currently, it takes the form of an even-sized list of
key/value pairs, associating field names with their values. Each key gives the
name of a component class and the full name of the field within it, separated
by a dot (C<.>).

   'CLASSNAME.$FIELD1' => VALUE, 'CLASSNAME.@FIELD2' => VALUE, ...

In the case of scalar fields, the value is the actual value of that field. In
the case of array or hash fields, the value in the repr list is a reference to
an anonymous I<copy of> the value stored in the field.

   'CLASSNAME.$SCALARFIELD' => $VALUE,
   'CLASSNAME.@ARRAYFIELD'  => [ @VALUE ],
   'CLASSNAME.%HASHFIELD'   => { %VALUE },

The pairs are ordered, with the actual object class type first, followed by
any roles added by that class, then each parent class recursively. Within each
component class, the fields are given in declared order.

This reliable ordering may be useful when printing values in human-readable
form, or serialising to some stable storage.

=head2 ref_field

   $fieldref = ref_field( $fieldname, $obj );

I<Since version 0.67.>

Returns a reference to the named field storage variable of the given instance
object. The I<$fieldname> should be specified as the class name and the field
name separated by a dot (C<.>) (as per L</deconstruct_object>).

The class name may also be omitted; at which point the first occurrence of a
field of the given name found in any component class it matched instead.

If no matching field is found, an exception is thrown.

Be careful when using this function as it has the ability to expose instance
fields in a way that allows them to be modified. For a safer alternative when
only read access is required, use L</get_field> instead.

=cut

=head2 get_field

   $scalar = get_field( $fieldname, $obj );
   @array  = get_field( $fieldname, $obj );
   %hash   = get_field( $fieldname, $obj );

I<Since version 0.67.>

Returns the value of the named field of the given instance object. Behaves
correctly given context; namely, that when invoked on array or hash fields in
scalar context it will return the number of elements or keys, or in list
context will return the list of elements or key/value pairs.

=cut

sub get_field
{
   my $ref = ref_field( @_ );
   my $type = reftype $ref;
   return @$ref if $type eq "ARRAY";
   return %$ref if $type eq "HASH";
   return $$ref;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
