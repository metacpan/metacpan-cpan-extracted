#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Operator::Zip 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::Zip> - infix operator to compose two lists together

=head1 SYNOPSIS

On a suitably-patched perl:

   use Syntax::Operator::Zip;

   foreach (@xvals Z @yvals) {
      my ($x, $y) = @$_;
      say "Value $x is associated with value $y";
   }

Or, on a standard perl:

   use v5.14;
   use Syntax::Operator::Zip qw( zip );

   foreach (zip \@xvals, \@yvals) {
      my ($x, $y) = @$_;
      say "Value $x is associated with value $y";
   }

=head1 DESCRIPTION

This module provides infix operators that compose two lists of elements by
associating successive elements from the left and right-hand lists together,
forming a new list.

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

   @syms or @syms = qw( Z );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Operator::Zip/Z"}++ if delete $syms{Z};

   foreach (qw( zip mesh )) {
      no strict 'refs';
      *{"${caller}::$_"} = \&{$_} if delete $syms{$_};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 Z

   my @result = @lhs Z @rhs;

   # returns  [$lhs[0], $rhs[0]], [$lhs[1], $rhs[1]], ...

Yields a list of array references, each containing a pair of items from the
two operand lists. If one of the operand lists is shorter than the other, the
missing elements will be filled in with C<undef> so that every array reference
in the result contains exactly two items.

=head2 M

   my @result = @lhs M @rhs;

   # returns ($lhs[0], $rhs[0], $lhs[1], $rhs[1], ...)

Yields a list of the values from its operand lists, rearranged into pairs and
flattened. If one of the operand lists is shorter than the other, the missing
elements will be filled in with C<undef> so that the result is correctly lined
up.

The result of this operator is useful for constructing hashes from two lists
containing keys and values

   my %hash = @keys M @values;

=cut

=head1 FUNCTIONS

As a convenience, the following functions may be imported which implement the
same behaviour as the infix operators, though are accessed via regular
function call syntax. The two lists for these functions to operate on must be
passed as references to arrays (either named variables, or anonymously
constructed by C<[...]>).

=head2 zip

   my @result = zip( \@lhs, \@rhs );

A function version of the L</Z> operator.

See also L<List::Util/zip>.

=head2 mesh

   my @result = mesh( \@lhs, \@rhs );

A function version of the L</M> operator.

See also L<List::Util/mesh>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
