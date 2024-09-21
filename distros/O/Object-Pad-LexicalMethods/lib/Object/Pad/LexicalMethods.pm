#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Object::Pad::LexicalMethods 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Object::Pad::LexicalMethods> - operator for lexical method call syntax

=head1 SYNOPSIS

=for highlighter language=perl

   use v5.38;
   use Object::Pad;
   use Object::Pad::LexicalMethods;

   class WithPrivate {
      field $var;

      my method inc_var { $var++ }
      my method dec_var { $var-- }

      method bump {
         $self->&inc_var;
         say "In the middle";
         $self->&dec_var;
      }
   }

=head1 DESCRIPTION

Perl version 5.18 added lexical subroutines, which are located in the lexical
scope (much like variables declared with C<my>). L<Object::Pad> version 0.814
supports methods being declared lexically as well, meaning they do not appear
in the package namespace of the class, and are not accessible from other
scopes. However, Perl does not currently provide a method call syntax for
invoking these from the lexical scope while looking like method calls.

This module provides an infix operator for making the syntax of calls to
lexical subroutines as if they were methods defined on an object instance look
more like named method dispatch syntax.

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

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

   @syms or @syms = qw( ->& );

   $pkg->XS::Parse::Infix::apply_infix( $on, \@syms, qw( ->& ) );

   croak "Unrecognised import symbols @syms" if @syms;
}

=head1 OPERATORS

=head2 ->&

   @result = $instance->&lexmethod( @args );
   @result = $instance->&lexmethod;

Invokes a lexical subroutine (that must be visible in the current scope) as if
it were a method on instance given by the LHS operand. Arguments may be
passed; if so they must be surrounded by parentheses.

This is exactly equivalent to simply invoking the subroutine as a plain
function and passing in the instance as the first argument. However, the
syntax looks more like regular name-based dispatch method invocation, and is
perhaps less surprising to readers as a result. Also, this operator will only
accept I<lexical> subroutines as methods; it will reject package-named ones
that would otherwise be visible here.

Note that as this is implemented as a single infix operator named C<< ->& >>
whitespace is not permitted after the arrow but before the ampersand, whereas
other arrow-like operators in Perl (such as C<< ->[ ... ] >>) do permit this.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
