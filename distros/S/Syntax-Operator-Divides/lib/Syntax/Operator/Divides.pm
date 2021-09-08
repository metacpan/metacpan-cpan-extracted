#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Operator::Divides 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::Divides> - an infix operator for division test

=head1 SYNOPSIS

On a suitably-patched perl:

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

Current versions of perl do not directly support custom infix operators. The
documentation of L<XS::Parse::Infix> describes the situation, with reference
to a branch experimenting with this new feature. This module is therefore
I<almost> entirely useless on standard perl builds. While the regular parser
does not support custom infix operators, they are supported via
C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>, and so custom keywords
which attempt to parse operator syntax may be able to use it. One such module
is L<Syntax::Keyword::Match>; see the SYNOPSIS example given above.

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

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 %%

   my $divides = $numerator %% $denominator;

Yields true if the numerator operand is a whole integer multiple of the
denominator. This is implemented by using the C<%> modulus operator and
testing if the remainder is zero.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
