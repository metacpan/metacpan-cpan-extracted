#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Match 0.03;

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

=head1 Experimental Features

Some of the features of this module are currently marked as experimental (even
within the context that the module itself is experimental). They will provoke
warnings in the C<experimental> category, unless silenced.

   use Syntax::Keyword::Match qw( try :experimental(dispatch) );

   use Syntax::Keyword::Match qw( try :experimental );  # all of the above

=cut

my @EXPERIMENTAL = qw( dispatch );

sub import
{
   shift;
   my @syms = @_;

   @syms or @syms = ( "match" );

   my %syms = map { $_ => 1 } @syms;

   $^H{"Syntax::Keyword::Match/match"}++ if delete $syms{match};

   foreach ( @EXPERIMENTAL ) {
      $^H{"Syntax::Keyword::Match/experimental($_)"}++ if delete $syms{":experimental($_)"};
   }

   if( delete $syms{":experimental"} ) {
      $^H{"Syntax::Keyword::Match/experimental($_)"}++ for @EXPERIMENTAL;
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 KEYWORDS

=head2 match

   match( EXPR : OP ) {
      ...
   }

A C<match> statement provides the controlling expression, comparison operator,
and sequence of C<case> statements for a match operation. The expression is
evaluated to yield a scalar value, which is then compared, using the
comparison operator, against each of the C<case> labels in the order they are
written, topmost first. If a match is found then the body of the labelled
block is executed. If no label matches but a C<default> block is present, that
will be executed instead. After a single inner block has been executed, no
further tests are performed and execution continues from the statement
following the C<match> statement.

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

=head3 Comparison Operators

The comparison operator must be either C<eq> (to compare cases as strings) or
C<==> (to compare them as numbers), or C<=~> (to compare cases using regexps).

On Perl versions 5.32 onwards, the C<isa> operator is also supported, allowing
dispatch based on what type of object the controlling expression gives.

   match( $obj : isa ) {
      case(A::Package)       { ... }
      case(Another::Package) { ... }
   }

Remember that comparisons are made in the order they are written, from the top
downwards. Therefore, if you list a derived class as well as a base class,
make sure to put the derived class B<before> the base class, or instances of
that type will also match the base class C<case> block and the derived one
will never match.

   class TheBase {}
   class Derived extends TheBase {}

   match( $obj : isa ) {
      case(TheBase) { ... }
      case(Derived) {
         # This case will never match as the one above will always happen first
      }
   }

=head2 case

   case(VAL) { STATEMENTS... }

A C<case> statement must only appear inside the braces of a C<match>. It
provides a block of code to run if the controlling expression's value matches
the value given in the C<case> statement, according to the comparison
operator.

If the value is a non-constant expression, such as a variable or function
call, it will be evaluated as part of performing the comparison every time the
C<match> statement is executed. For best performance it is advised to extract
values that won't need computing again into a variable that can be calculated
just once at program startup; for example:

   my $condition = a_function("with", "arguments");

   match( $var : eq ) {
      case($condition) { ... }
      ...
   }

The C<:experimental(dispatch)> feature selects a more efficient handling of
sequences of multiple C<case> blocks with constant expressions. This handling
is implemented with a custom operator that will entirely confuse modules like
C<B::Deparse> or optree inspectors like coverage tools so is not selected by
default, but can be enabled for extra performance in critical sections.

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
