#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::Elem 0.04;

use v5.14;
use warnings;

use Carp;

=encoding UTF-8

=head1 NAME

C<Syntax::Operator::Elem> - element-of-list operators

=head1 SYNOPSIS

On a suitably-patched perl:

   use Syntax::Operator::Elem;

   if($x elem @some_strings) {
      say "x is one of the given strings";
   }

Or, on a standard perl:

   use v5.14;
   use Syntax::Operator::Elem qw( elem_str );

   if(elem_str $x, @some_strings) {
      say "x is one of the given strings";
   }

=head1 DESCRIPTION

This module provides infix operators that implement element-of-list tests for
strings and numbers.

Current versions of perl do not directly support custom infix operators. The
documentation of L<XS::Parse::Infix> describes the situation, with reference
to a branch experimenting with this new feature. This module is therefore
I<almost> entirely useless on standard perl builds. While the regular parser
does not support custom infix operators, they are supported via
C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>, and so custom keywords
which attempt to parse operator syntax may be able to use it.

Additionally, standard versions of perl can still use the function-like
wrapper versions of these operators. Even though the syntax appears like a
regular function call, the code is compiled internally into the same more
efficient operator internally, so will run without the function-call overhead
of a regular function.

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

   require Syntax::Operator::In;  # no import

   @syms or @syms = qw( in );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Operator::Elem/elem"}++ if delete $syms{in};

   foreach (qw( elem_str elem_num )) {
      no strict 'refs';
      *{"${caller}::$_"} = \&{$_} if delete $syms{$_};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 elem

   my $present = $lhs elem @rhs;

Yields true if the string on the lefthand side is equal to any of the strings
in the list on the right.

Note that it is specifically B<not> guaranteed that this test will be
performed in any particular order. Nor is it guaranteed that any C<eq>
operator overloading present on any of the elements is respected. These
conditions may allow an implementation at least partially based on a hash,
balanced binary tree, or other techniques.

=head2 ∈

   my $present = $lhs ∈ @rhs;

Yields true if the number on the lefthand side is equal to any of the numbers
in the list on the right.

Note that it is specifically B<not> guaranteed that this test will be
performed in any particular order. Nor is it guaranteed that any C<==>
operator overloading present on any of the elements is respected. These
conditions may allow an implementation at least partially based on a hash,
balanced binary tree, or other techniques.

=cut

=head1 FUNCTIONS

As a convenience, the following functions may be imported which implement the
same behaviour as the infix operators, though are accessed via regular
function call syntax.

=head2 elem_str

   my $present = elem_str( $lhs, @rhs );

A function version of the L</elem> stringy operator.

=head2 elem_num

   my $present = elem_num( $lhs, @rhs );

A function version of the L</∈> numerical operator.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
