#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Syntax::Operator::Is 0.02;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::Is> - match operator using L<Data::Checks> constraints

=head1 SYNOPSIS

On Perl v5.38 or later:

   use v5.38;
   use Syntax::Operator::Is;

   use Data::Checks qw( Num Object );

   my $x = ...;

   if($x is Num) {
      say "x can be used as a number";
   }
   elsif($x is Object) {
      say "x can be used as an object";
   }

Or via L<Syntax::Keyword::Match> on Perl v5.14 or later:

   use v5.14;
   use Syntax::Operator::Is;
   use Syntax::Keyword::Match;

   use Data::Checks qw( Num Object );

   my $x = ...;

   match($x : is) {
      case(Num)    { say "x can be used as a number"; }
      case(Object) { say "x can be used as an object"; }
   }

=head1 DESCRIPTION

This module provides an infix operator that checks if a given value matches a
value constraint provided by L<Data::Checks>.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

While Perl versions before this do not support custom infix operators, they
can still be used via C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>.
Custom keywords which attempt to parse operator syntax may be able to use
these. One such module is L<Syntax::Keyword::Match>; see the SYNOPSIS example
given above.

=head2 Operator Name vs C<Test::More> / C<Test2::V0>

This module provides a named operator called C<is>. The same name is used by
both L<Test::More> and L<Test2::V0> as a unit test assertion function. Since
each has to be imported by request, this does not cause issues for code that
does not try to use both of them at once. Most real use-cases will not be unit
test scripts, and most unit test scripts will not need to use this operator.

In situations where you need to use this C<is> operator and one of the testing
modules at the same time (for example, during a unit test of some
check-related code), note that because of the way infix operator plugins work,
the named operator will always take precedence and thus you will need to call
the C<is()> testing function by its fully-qualified name:

   use Test2::V0;
   use Syntax::Operator::Is;

   Test2::V0::is( 1 is Num, builtin::true, '1 is Num' );

Alternatively, use the ability of L<XS::Parse::Infix> to import the operator
with a different name and avoid the collision.

   use Test2::V0;
   use Syntax::Operator::Is is => { -as => "is_checked" };

   is( 1 is_checked Num, builtin::true, '1 is Num' );

=cut

sub import
{
   my $pkg = shift;
   $pkg->apply( 1, @_ );
}

sub unimport
{
   my $pkg = shift;
   $pkg->apply( 0, @_ );
}

sub apply
{
   my $pkg = shift;
   my ( $on, @syms ) = @_;

   @syms or @syms = qw( is );

   $pkg->XS::Parse::Infix::apply_infix( $on, \@syms, qw( is ) );

   croak "Unrecognised import symbols @syms" if @syms;
}

=head1 OPERATORS

=head2 is

   my $ok = $value is $Constraint;

Yields true if the given value is accepted by the given constraint checker.
Yields false but should not otherwise throw an exception if the value is
rejected.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
