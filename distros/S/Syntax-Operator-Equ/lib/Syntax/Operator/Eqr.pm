#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

package Syntax::Operator::Eqr 0.09;

use v5.14;
use warnings;

use Carp;

use meta 0.003_002;
no warnings 'meta::experimental';

# Load the XS code
require Syntax::Operator::Equ;

=head1 NAME

C<Syntax::Operator::Eqr> - string equality and regexp match operator

=head1 SYNOPSIS

On Perl v5.38 or later:

   use v5.38;
   use Syntax::Operator::Eqr;

   if($str eqr $pat) {
      say "x and y are both undef, or both defined and equal strings, " .
          "or y is a regexp that matches x";
   }

Or via L<Syntax::Keyword::Match> on Perl v5.14 or later:

   use v5.14;
   use Syntax::Keyword::Match;
   use Syntax::Operator::Eqr;

   match($str : eqr) {
      case(undef)   { say "The variable is not defined" }
      case("")      { say "The variable is defined but is empty" }
      case(qr/^.$/) { say "The variable contains exactly one character" }
      default       { say "The string contains more than one" }
   }

=head1 DESCRIPTION

This module provides an infix operators that implements a matching operation
whose behaviour depends on whether the right-hand side operand is undef, a
quoted regexp object, or some other value. If undef, it is true only if the
lefthand operand is also undef. If a quoted regexp object, it behaves like
Perl's C<=~> pattern-matching operator. If neither, it behaves like the C<eq>
operator.

This operator does not warn when either or both operands are C<undef>.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

While Perl versions before this do not support custom infix operators, they
can still be used via C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>.
Custom keywords which attempt to parse operator syntax may be able to use
these. One such module is L<Syntax::Keyword::Match>; see the SYNOPSIS example
given above.

=head2 Comparison With Smartmatch

At first glance it would appear a little similar to core perl's ill-fated
smartmatch operator (C<~~>), but this version is much simpler. It does not try
to determine if stringy or numerical match is preferred, nor does it attempt
to make sense of any C<ARRAY>, C<HASH>, C<CODE> or other complicated container
values on either side. Its behaviour is in effect entirely determined by the
value on its righthand side - the three cases of C<undef>, some C<qr/.../>
object, or anything else.

This in particular makes it behave sensibly with the C<match/case> syntax
provided by L<Syntax::Keyword::Match>.

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

   @syms or @syms = qw( eqr );

   my %syms = map { $_ => 1 } @syms;
   if( delete $syms{eqr} ) {
      $on ? $^H{"Syntax::Operator::Eqr/eqr"}++
          : delete $^H{"Syntax::Operator::Eqr/eqr"};
   }

   my $callerpkg;

   foreach (qw( is_eqr )) {
      next unless delete $syms{$_};

      $callerpkg //= meta::package->get( $caller );

      $on ? $callerpkg->add_symbol( '&'.$_ => \&{$_} )
          : $callerpkg->remove_symbol( '&'.$_ );
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 eqr

   my $matches = $lhs eqr $rhs;

Yields true if both operands are C<undef>, or if the right-hand side is a
quoted regexp value that matches the left-hand side, or if both are defined
and contain equal string values. Yields false if given exactly one C<undef>,
two unequal strings, or a string that does not match the pattern.

=cut

=head1 FUNCTIONS

As a convenience, the following functions may be imported which implement the
same behaviour as the infix operators, though are accessed via regular
function call syntax.

These wrapper functions are implemented using L<XS::Parse::Infix>, and thus
have an optimising call-checker attached to them. In most cases, code which
calls them should not in fact have the full runtime overhead of a function
call because the underlying test operator will get inlined into the calling
code at compiletime. In effect, code calling these functions should run with
the same performance as code using the infix operators directly.

=head2 is_eqr

   my $matches = is_eqr( $lhs, $rhs );

A function version of the L</eqr> stringy operator.

=cut

=head1 SEE ALSO

=over 4

=item *

L<Syntax::Operator::Equ> - equality operators that distinguish C<undef>

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
