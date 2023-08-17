#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021,2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::In 0.06;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::In> - infix element-of-list meta-operator

=head1 SYNOPSIS

On Perl v5.38 or later:

   use Syntax::Operator::In;

   if($x in:eq @some_strings) {
      say "x is one of the given strings";
   }

=head1 DESCRIPTION

This module provides an infix meta-operator that implements a element-of-list
test on either strings or numbers.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

While Perl versions before this do not support custom infix operators, they
can still be used via C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>.
Custom keywords which attempt to parse operator syntax may be able to use
these.

For operators that already specialize on string or numerical equality, see
instead L<Syntax::Operator::Elem>.

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

   @syms or @syms = qw( in );

   my %syms = map { $_ => 1 } @syms;
   if( delete $syms{in} ) {
      $on ? $^H{"Syntax::Operator::In/in"}++
          : delete $^H{"Syntax::Operator::In/in"};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 OPERATORS

=head2 in

   my $present = $lhs in:OP @rhs;

   my $present = $lhs in<OP> @rhs;

Yields true if the value on the lefhand side is equal to any of the values in
the list on the right, according to some equality test operator C<OP>.

This test operator must be either C<eq> for string match, or C<==> for number
match, or any other custom infix operator that is registered in the
C<XPI_CLS_EQUALITY> classification.

There are currently two accepted forms of the syntax for this operator, using
either a prefix colon or a circumfix pair of angle-brackets. They are entirely
identical in semantics, differing only in the surface-level syntax to notate
them. This is because I'm still entirely undecided on which notation is better
in terms of readable neatness, flexibility, parsing ambiguity and so on. This
is somewhat of an experiment to see which will eventually win.

=cut

=head1 TODO

=over 4

=item *

Improve runtime performance of compiletime-constant sets of strings, by
detecting when the RHS contains string constants and convert it into a hash
lookup.

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
