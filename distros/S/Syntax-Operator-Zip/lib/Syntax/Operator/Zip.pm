#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk

package Syntax::Operator::Zip 0.10;

use v5.14;
use warnings;

use Carp;

use meta 0.004;
no warnings 'meta::experimental';

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::Zip> - infix operator to compose two lists together

=head1 SYNOPSIS

On Perl v5.38 or later:

   use Syntax::Operator::Zip;

   foreach (@xvals Z @yvals) {
      my ($x, $y) = @$_;
      say "Value $x is associated with value $y";
   }

Or on Perl v5.14 or later:

   use v5.14;
   use Syntax::Operator::Zip qw( zip );

   foreach (zip \@xvals, \@yvals) {
      my ($x, $y) = @$_;
      say "Value $x is associated with value $y";
   }

=head1 DESCRIPTION

This module provides infix operators that compose lists of elements by
associating successive elements from each of the input lists, forming a new
list.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

While Perl versions before this do not support custom infix operators, they
can still be used via C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>.
Custom keywords which attempt to parse operator syntax may be able to use
these.

Additionally, earlier versions of perl can still use the function-like
wrapper versions of these operators. Even though the syntax appears like a
regular function call, the code is compiled internally into the same more
efficient operator internally, so will run without the function-call overhead
of a regular function.

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

   @syms or @syms = qw( Z M );

   my %syms = map { $_ => 1 } @syms;
   foreach (qw( Z M )) {
      next unless delete $syms{$_};

      $on ? $^H{"Syntax::Operator::Zip/$_"}++
          : delete $^H{"Syntax::Operator::Zip/$_"};
   }

   my $callerpkg;

   foreach (qw( zip mesh )) {
      next unless delete $syms{$_};

      $callerpkg //= meta::package->get( $caller );

      $on ? $callerpkg->add_symbol( '&'.$_ => \&{$_} )
          : $callerpkg->remove_symbol( '&'.$_ );
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

   my @result = @alphas Z @betas Z @gammas Z ...

   # returns [$alphas[0], $betas[0], $gammas[0], ...], ...

I<Since version 0.10> this module supports list-associative combinations of
more than two input lists at once. The result will be composed of parallel
items from each of the given input lists.

=head2 M

   my @result = @lhs M @rhs;

   # returns  $lhs[0], $rhs[0], $lhs[1], $rhs[1], ...

Yields a list of the values from its operand lists, rearranged into pairs and
flattened. If one of the operand lists is shorter than the other, the missing
elements will be filled in with C<undef> so that the result is correctly lined
up.

   my @result = @alphas M @betas M @gammas M ...

   # returns $alphas[0], $betas[0], $gammas[0], ..., $alphas[1], ...

I<Since version 0.10> this module supports list-associative combinations of
more than two input lists at once. The result will be composed of parallel
items from each of the given input lists.

The result of this operator is useful for constructing hashes from two lists
containing keys and values

   my %hash = @keys M @values;

This is also useful combined with the multiple variable C<foreach> syntax of
Perl 5.36 and above:

   foreach my ( $alpha, $beta, $gamma ) ( @alphas M @betas M @gammas ) {
      ...
   }

=cut

=head1 FUNCTIONS

As a convenience, the following functions may be imported which implement the
same behaviour as the infix operators, though are accessed via regular
function call syntax. The lists for these functions to operate on must be
passed as references to arrays (either named variables, or anonymously
constructed by C<[...]>).

=head2 zip

   my @result = zip( \@lhs, \@rhs, ... );

A function version of the L</Z> operator.

See also L<List::Util/zip>.

=head2 mesh

   my @result = mesh( \@lhs, \@rhs, ... );

A function version of the L</M> operator.

See also L<List::Util/mesh>.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
