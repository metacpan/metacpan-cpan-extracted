#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Object::Pad::Operator::Of 0.01;

use v5.14;
use warnings;

use Carp;

use Object::Pad;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::Operator::Of> - access fields of other instances

=head1 SYNOPSIS

On Perl v5.38 or later:

   use v5.38;
   use Object::Pad;
   use Object::Pad::Operator::Of;

   class Bucket {
      field $size :param;

      use overload '<=>' => method ($other, $) {
         return $size <=> $size of $other;
      };
   }

=head1 DESCRIPTION

This module provides an infix operator for accessing fields of other instances
of an L<Object::Pad> class, even if those fields do not have accessor methods.
This allows code to be written that can look into the inner workings of other
instances of the same class (or subclasses thereof), in order to implement
particular behaviours, such as sorting comparisons.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub unimport
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->unimport_into( $caller, @_ );
}

sub import_into   { shift->apply( 1, @_ ) }
sub unimport_into { shift->apply( 0, @_ ) }

sub apply
{
   my $pkg = shift;
   my ( $on, $caller, @syms ) = @_;

   @syms or @syms = qw( of );

   $pkg->XS::Parse::Infix::apply_infix( $on, \@syms, qw( of ) );

   croak "Unrecognised import symbols @syms" if @syms;
}

=head1 OPERATORS

=head2 of

   my $value = $field of $other;

Yields the current value of the given field of a different instance than
C<$self>. The field variable, on the left of the operator, must be lexically
visible in the current scope. The expression on the right must yield an
instance of the class that defines the field (or some subclass of it); if not
an exception is thrown.

=cut

=head1 TODO

=over 4

=item *

Try to find a better operator name, which puts the object instance on the left
and the field on the right.

=item *

Look into whether regular C<sub>s can also use C<of> expressions. Currently
no fields are visible due to the way that C<Object::Pad> implements methods.

=item *

Look into whether it might be possible to use C<of> expressions as lvalues,
for mutation or assignment.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
