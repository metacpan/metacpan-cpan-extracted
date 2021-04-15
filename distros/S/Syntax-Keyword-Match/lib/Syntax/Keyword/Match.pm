#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Match 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Keyword::Match> - a C<match/case> syntax for perl

=head1 SYNOPSIS

   use v5.14;
   use Syntax::Keyword::Match;

   my $n = ...;

   match($n : ==) {
      case(1) { say "It's one" }
      case(2) { say "It's two" }
      case(3) { say "It's three" }
      default { say "It's something else" }
   }

=head1 DESCRIPTION

This module provides a syntax plugin that implements a control-flow block
called C<match/case>, which executes at most one of a choice of different
blocks depending on the value of its controlling expression.

This is similar to C's C<switch/case> syntax (copied into many other
languages), or syntax provided by L<Switch::Plain>.

This is an initial, experimental implementation. Furthermore, it is built as
a non-trivial example use-case on top of L<XS::Parse::Keyword>, which is also
experimental. No API or compatbility guarantees are made at this time.

=cut

sub import
{
   shift;
   my @syms = @_;

   @syms or @syms = ( "match" );

   foreach ( @syms ) {
      $_ eq "match" or croak "Unrecognised import symbol '$_'";

      $^H{"Syntax::Keyword::Match/$_"}++;
   }
}

=head1 KEYWORDS

=head2 match

   match( EXPR : OP ) {
      ...
   }

A C<match> statement provides the controlling expression, comparison operator,
and set of C<case> statements for a match operation. The expression is
evaluated to yield a scalar value, which is then compared, using the
comparison operator, against each of the C<case> labels. If a match is found
then the body of the labelled block is executed. If no label matches but a
C<default> block is present, that will be executed instead. After a single
inner block has been executed, no further tests are performed and execution
continues from the statement following the C<match> statement.

The comparison operator must be either C<eq> (to compare cases as strings) or
C<==> (to compare them as numbers).

The braces following the C<match> block must only contain C<case> or
C<default> statements. Arbitrary code is not supported here.

Even though a C<match> statement is a full statement and not an expression, it
can still yield a value if it appears as the final statment in its containing
C<sub> or C<do> block. For example:

   my $result = do {
      match( $topic : == ) {
         case(1) { ... }
      }
   };

=head2 case

   case(CONST) { STATEMENTS... }

A C<case> statement must only appear inside the braces of a C<match>. It
provides a block of code to run if the controlling expression's value matches
the given constant in the C<case> statement, according to the comparison
operator.

The C<CONST> expression must be a compile-time constant giving a single
scalar. Runtime expressions (such as variables or function calls) are not
supported, nor are lists of values.

=head2 default

A C<default> statement must only appear inside the braces of a C<match>. If
present, it must be the final choice, and there must only be one of them. It
provides a block of code to run if the controlling expression's value did not
match any of the given C<case> labels.

=cut

=head1 TODO

This is clearly an early experimental work. There are many features to add,
and design decisions to make. Rather than attempt to list them all here it
would be best to check the RT bug queue at

L<https://rt.cpan.org/Dist/Display.html?Name=Syntax-Keyword-Match>

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
