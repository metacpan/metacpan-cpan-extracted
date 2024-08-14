#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

package Object::Pad::FieldAttr::Checked 0.12;

use v5.14;
use warnings;

use Object::Pad 0.802;  # requires pre-filled ctx->bodyop when invoking gen_accessor_ops

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::FieldAttr::Checked> - apply value constraint checks to C<Object::Pad> fields

=head1 SYNOPSIS

With L<Data::Checks>:

   use Object::Pad;
   use Object::Pad::FieldAttr::Checked;
   use Data::Checks qw( Num );

   class Point {
      field $x :param :reader :Checked(Num);
      field $y :param :reader :Checked(Num);
   }

   Point->new( x => 123, y => "456" );         # this is fine

   Point->new( x => "hello", y => "world" );   # throws an exception

=head1 DESCRIPTION

This module provides a third-party field attribute for L<Object::Pad>-based
classes, which declares that values assigned to the field must conform to a
given constraint check.

B<WARNING> The ability for L<Object::Pad> to take third-party field attributes
is still new and highly experimental, and subject to much API change in
future. As a result, this module should be considered equally experimental.

Additionally, the behaviour provided by this module should be considered more
of a work-in-progress stepping stone. Ideally, constraint syntax ought
to be provided in a much more fundamental way by Perl itself, allowing it to
be used on C<my> lexicals, subroutine parameters, and other places as well as
object fields. This module is more of a placeholder to allow some part of that
behaviour to be specified for object fields, while not getting in the way of a
more general, more powerful system being added in future.

=head1 FIELD ATTRIBUTES

=head2 :Checked

   field $name :Checked(EXPRESSION) ...;

Declares that any value assigned to the field during the constructor or using
an accessor method must conform to the constraint checker specified by the
expression. Attempts to assign a non-conforming value will throw an exception
and the field will not be modified. Currently only scalar fields are
supported.

At compiletime, the string given by I<EXPRESSION> is C<eval()>'ed in scalar
context, and its result is stored as part of the field's definition. The
expression must yield a value usable by L<Data::Checks>. Namely, one of:

=over 4

=item *

Any of the constraint checkers provided by the L<Data::Checks> module itself.

=item *

An B<object> reference with a C<check> method:

   $ok = $checkerobj->check( $value );

=item *

A B<plain string> giving the name of a package with a C<check> method:

   $ok = $checkerpkg->check( $value );

If using a plain package name as a checker, be sure to quote package names so
it will not upset C<use strict>.

   field $x :Checked('CheckerPackage');

=back

As this is the interface supported by L<Types::Standard>, any constraint
object provided by that module is already supported here.

   use Types::Standard qw( Str Num );

   field $name :Checked(Str);
   field $age  :Checked(Num);

At runtime, this constraint checker is used every time an attempt is made to
assign a value to the field I<from outside the object class>, whether that is
from C<:param> initialisation, or invoking a C<:writer>, C<:accessor> or
C<:mutator>. The checker is used as the invocant for invoking a C<check>
method, and the new value for  the field is passed as an argument. If the
method returns true, the assignment is allowed. If false, it is rejected with
an exception and the field itself remains unmodified.

(For performance reasons, the C<check> method is actually resolved into a
function at compiletime when the C<:Checked> attribute is applied, and this
stored function is the one that is called at assignment time. If the method
itself is replaced later by globref assignment or other trickery, this updated
function will not be used.)

B<Note carefully> that direct assignment into the field variable by code
within the class is not checked. This is partly because of design
considerations, and partly because any way to implement that would be horribly
slow, or flat-out impossible. I<Prior to version 0.04> this module used to
claim that even direct assignments would be checked. but this gave a false
sense of safety if deeply-nested containers were involved and modified from
within.

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
