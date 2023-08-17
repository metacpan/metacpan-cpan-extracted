#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Object::Pad::FieldAttr::Checked 0.02;

use v5.14;
use warnings;

use Object::Pad 0.66;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::FieldAttr::Checked> - apply value constraint checks to C<Object::Pad> fields

=head1 SYNOPSIS

With L<Types::Standard>:

   use Object::Pad;
   use Object::Pad::FieldAttr::Checked;
   use Types::Standard qw( Num );

   class Point {
      field $x :param :reader :Checked(Num);
      field $y :param :reader :Checked(Num);
   }

   Point->new( x => 123, y => "456" );         # this is fine

   Point->new( x => "hello", y => "world" );   # throws an exception

Or, standalone:

   use Object::Pad;
   use Object::Pad::FieldAttr::Checked;

   package Numerical {
      use Scalar::Util qw( looks_like_number );
      sub check { looks_like_number $_[1]; }
   }

   class Point {
      field $x :param :reader :Checked(Numerical);
      field $y :param :reader :Checked(Numerical);
   }

   ...

=head1 DESCRIPTION

This module provides a third-party field attribute for L<Object::Pad>-based
classes, which declares that values assigned to the field must conform to a
given value constraint check.

B<WARNING> The ability for L<Object::Pad> to take third-party field attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

Additionally, the behaviour provided by this module should be considered more
of a work-in-progress stepping stone. Ideally, value constraint syntax ought
to be provided in a much more fundamental way by native Perl syntax, allowing
it to be used on C<my> lexicals, subroutine parameters, and other places as
well as object fields. This module is more of a placeholder to allow some part
of that behaviour to be specified for object fields, while not getting in the
way of a more general, more powerful system being added in future.

=head1 FIELD ATTRIBUTES

=head2 :Checked

   field $name :Checked(EXPRESSION) ...;

Declares that any value assigned to the field must conform to the constraint
checking object specified by the expression. Attempts to assign a
non-conforming value will throw an exception and the field will not be
modified.

At compiletime, the string given by I<EXPRESSION> is C<eval()>'ed in scalar
context, and its result is stored as part of the field's definition. The value
of the expression must either be an object reference, or a string containing
the name of a package. In either case, a method called C<check> must exist on
it.

At runtime, this constraint checking value is used every time an attempt is
made to assign a new value to the field, whether that is from C<:param>
initialisation, invoking a C<:writer> or C<:mutator> accessor, or direct
assignment into the field variable by method code within the class. The
checker is used as the invocant for invoking a C<check> method, and the new
value for the field is passed as an argument. If the method returns true, the
assignment is allowed. If false, it is rejected with an exception and the
field itself remains unmodified.

   $ok = $checker->check( $value );

As this is the interface supported by L<Types::Standard>, any constraint
object provided by that module is already supported here.

   use Types::Standard qw( Str Num );

   field $name :Checked(Str);
   field $age  :Checked(Num);

(For performance reasons, the C<check> method is actually resolved into a
function at compiletime when the C<:Checked> attribute is applied, and this
stored value is the one that is called at assignment time. If the method
itself is replaced later by globref assignment or other trickery, this updated
value will not be used.)

=cut

sub import
{
   $^H{"Object::Pad::FieldAttr::Checked/Checked"}++;
}

sub unimport
{
   delete $^H{"Object::Pad::FieldAttr::Checked/Checked"};
}

=head1 SEE ALSO

=over 4

=item *

L<Object::Pad::FieldAttr::Isa> - apply class type constraints to C<Object::Pad> fields

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
