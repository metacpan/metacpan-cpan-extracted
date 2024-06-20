#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Signature::Attribute::Checked 0.03;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Signature::Attribute::Checked> - apply value constraint checks to subroutine parameters

=head1 SYNOPSIS

With L<Types::Standard>

   use v5.26;
   use Sublike::Extended;
   use Signature::Attribute::Checked;
   use Types::Standard qw( Num );

   extended sub add ($x :Checked(Num), $y :Checked(Num)) {
      return $x + $y;
   }

   say add(10, 20);            # this is fine

   say add("hello", "world");  # throws an exception

=head1 DESCRIPTION

This module provides a third-party subroutine parameter attribute via
L<XS::Parse::Sublike>, which declares that values passed to a subroutine must
conform to a given constraint check.

B<WARNING> The ability for sublike constructions to take third-party parameter
attributes is still new and highly experimental, and subject to much API
change in future. As a result, this module should be considered equally
experimental. Core perl's parser does not permit parameters to take
attributes. This ability must be requested specially; either by using
L<Sublike::Extended>, or perhaps enabled directly by some other sublike
keyword using the C<XS::Parse::Sublike> infrastructure.

Additionally, the behaviour provided by this module should be considered more
of a work-in-progress stepping stone. Ideally, constraint syntax ought
to be provided in a much more fundamental way by Perl itself, allowing it to
be used on C<my> lexicals, class fields, and other places as well as
subroutine parameters. This module is more of a placeholder to allow some part
of that behaviour to be specified for subroutine parameters, while not getting
in the way of a more general, more powerful system being added in future.

=head1 PARAMETER ATTRIBUTES

=head2 :Checked

   extended sub f($x :Checked(EXPRESSION)) { ... }

Declares that any value passed to the parameter at the time the subroutine is
called must conform to the constraint checker specified by the expression.
Attempts to pass a non-conforming value will throw an exception and the
subroutine body will not be invoked. Currently only scalar parameters are
supported.

At compiletime, the string given by I<EXPRESSION> is C<eval()>'ed in scalar
context, and its result is stored as part of the subroutine's definition. The
expression must yield either an object reference, a code reference, or a
string containing the name of a package. In the case of an object or package,
a method called C<check> must exist on it.

If using a plain package name as a checker, be sure to quote package names so
it will not upset C<use strict>.

   extended sub xyz ($x :Checked('CheckerPackage')) { ... }

At runtime, this constraint checker is used every time an attempt is made to
call the function. The checker is used as the invocant for invoking a C<check>
method, and the value for the parameter is passed as an argument. If the
method returns true, the call is allowed. If false, it is rejected with an
exception and the function body is not invoked.

   $ok = $checkerobj->check( $value );  # if an object

   $ok = $checkersub->( $value );       # if a code reference

   $ok = $checkerpkg->check( $value );  # if a package name

(For performance reasons, the C<check> method is actually resolved into a
function at compiletime when the C<:Checked> attribute is applied, and this
stored function is the one that is called at assignment time. If the method
itself is replaced later by globref assignment or other trickery, this updated
function will not be used.)

As this is the interface supported by L<Types::Standard>, any constraint
object provided by that module is already supported here.

   use Types::Standard qw( Str Num );

   extended sub ghi ($x :Checked(Str), $y :Checked(Num)) { ... }

It is not specified what order these checks are performed in. In particular,
if any parameter default expressions invoke any side-effects, it is
unspecified whether such side-effects will happen if a value passed for a
parameter fails its constraint check. Users should take care not to attempt to
invoke any side-effects during such expressions.

Note further that these value checks are only performed once, at the time the
subroutine is invoked. Code within the body of the subroutine can freely
assign any other kind of value to the variable corresponding to a C<:Checked>
parameter without issue.

   extended sub foo ($n :Checked(Num)) {
      $x = "seven";   # this is permitted
   }

=cut

sub import
{
   $^H{"Signature::Attribute::Checked/Checked"}++;
}

sub unimport
{
   delete $^H{"Signature::Attribute::Checked/Checked"};
}

=head1 SEE ALSO

=over 4

=item *

L<Object::Pad::FieldAttr::Checked> - apply value constraint checks to C<Object::Pad> fields

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
