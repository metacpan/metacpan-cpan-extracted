#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::Divides 0.03;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::Divides> - an infix operator for division test

=head1 SYNOPSIS

On a suitable perl version:

   use Syntax::Operator::Divides;

   say "Multiple of 10" if $x %% 10;

Or, on a standard perl via L<Syntax::Keyword::Match>:

   use v5.14;
   use Syntax::Keyword::Match;
   use Syntax::Operator::Divides;

   foreach ( 1 .. 100 ) {
      match( $_ : %% ) {
         case(15) { say "FizzBuzz" }
         case(3)  { say "Fizz" }
         case(5)  { say "Buzz" }
         default  { say $_ }
      }
   }

=head1 DESCRIPTION

This module provides an infix operator that implements an integer divides test
which returns true if the lefthand operand is a whole multiple of the
righthand.

Current stable versions of perl do not directly support custom infix
operators, but the ability was added in the 5.37.x development cycle and is
available from perl v5.37.7 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail. This module is therefore I<almost>
entirely useless on stable perl builds. While the regular parser does not
support custom infix operators, they are supported via C<XS::Parse::Infix> and
hence L<XS::Parse::Keyword>, and so custom keywords which attempt to parse
operator syntax may be able to use it.

=cut

sub import
{
   my $class = shift;
   my $caller = caller;

   $class->import_into( $caller, @_ );
}

sub import_into
{
   my $class = shift;
   my ( $caller, @syms ) = @_;

   @syms or @syms = qw( divides );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Operator::Divides/divides"}++ if delete $syms{divides};

   {
      no strict 'refs';
      *{"${caller}::is_divisor"} = \&is_divisor if delete $syms{is_divisor};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 %%

   my $divides = $numerator %% $denominator;

Yields true if the numerator operand is a whole integer multiple of the
denominator. This is implemented by using the C<%> modulus operator and
testing if the remainder is zero.

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

=head2 is_divisor

   my $divides = is_divisor( $numerator, $denominator );

A function version of the L</%%> operator.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
