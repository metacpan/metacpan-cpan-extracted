#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021,2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::In 0.03;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::In> - infix element-of-list meta-operator

=head1 SYNOPSIS

On a suitably-patched perl:

   use Syntax::Operator::In;

   if($x in<eq> @some_strings) {
      say "x is one of the given strings";
   }

=head1 DESCRIPTION

This module provides an infix meta-operator that implements a element-of-list
test on either strings or numbers.

Current versions of perl do not directly support custom infix operators. The
documentation of L<XS::Parse::Infix> describes the situation, with reference
to a branch experimenting with this new feature. This module is therefore
I<almost> entirely useless on standard perl builds. While the regular parser
does not support custom infix operators, they are supported via
C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>, and so custom keywords
which attempt to parse operator syntax may be able to use it.

For operators that already specialize on string or numerical equality, see
instead L<Syntax::Operator::Elem>.

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

   @syms or @syms = qw( in );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Operator::In/in"}++ if delete $syms{in};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 in

   my $present = $lhs in<OP> @rhs;

Yields true if the value on the lefhand side is equal to any of the values in
the list on the right, according to some equality test operator C<OP>.

This test operator must be either C<eq> for string match, or C<==> for number
match, or any other custom infix operator that is registered in the
C<XPI_CLS_EQUALITY> classification.

=cut

=head1 TODO

=over 4

=item *

Improve runtime performance of compiletime-constant sets of strings, by
detecting when the RHS contains string constants and convert it into a hash
lookup.

=item *

Consider further on the syntax for this operator. Maybe instead of the
circumfix anglebrackets, a single colon might look nicer?

   $lhs in:OP @rhs

   $x in:== @numbers
   $x in:eq @strings

Does the lacking of end marker make parsing harder though?

=item *

Consider cross-module integration with L<Syntax::Keyword::Match>, permitting

   match($val : elem) {
      case(@arr_of_strings) { ... }
   }

Or perhaps this would be too weird, and maybe C<match/case> should have an
"any-of" list/array matching ability itself. See also
L<https://rt.cpan.org/Ticket/Display.html?id=143482>.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
