#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Syntax::Operator::ExistsOr 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Operator::ExistsOr> - an infix operator sensitive to hash element existence

=head1 SYNOPSIS

On a suitable perl version:

   use Syntax::Operator::ExistsOr;

   sub func ( %args ) {
      my $count = $args{count} \\ 10;

      say "Count is ", $count // "<undef>";
   }

   func( count => 20 );
   func();

   func( count => undef );

=head1 DESCRIPTION

This module provides an infix operator that similar to the defined-or C<//>
core perl operator, but which cares about hash element existence rather than
definedness.

Current stable versions of perl do not directly support custom infix
operators, but the ability was added in the 5.37.x development cycle and is
available from perl v5.37.7 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail. This module is therefore I<almost>
entirely useless on stable perl builds. While the regular parser does not
support custom infix operators, they are supported via C<XS::Parse::Infix> and
hence L<XS::Parse::Keyword>, and so custom keywords which attempt to parse
operator syntax may be able to use it.

This module does not provide wrapper functions for the operators, as their
inherent short-circuiting behaviour would appear confusing when expressed in
function-like syntax.

=cut

=head1 OPERATORS

=head2 \\

   my $value = $hash{$key} \\ EXPR;

The lefthand operand must be a hash element access (i.e. C<$hash{$key}> or
C<< $href->{$key} >> for some expressions yielding a key and a hashref).

If the hash contains the given key then the operator yields its value (even if
that value is C<undef>). If the key does not exist in the hash, then the
righthand operand will be evaluated in scalar context and its value returned.

This is a short-circuiting operator; if the hash does contain the key then the
righthand side expression is not evaluated at all.

This operator parses at the same precedence level as the logical-or operators
(C<||> and C<//>).

=head2 existsor

   do {
      $hash{$key} existsor EXPR;
   };

Similar to the C<\\> operator but parses at the same level as the
low-precedence or operator (C<or>). This is unlikely to be very useful, as
normally C<or> would be used for value-less control flow. Such a potential use
for this operator would be neater written

   exists $hash{$key} or EXPR;

It is included largely for completeness.

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

   @syms or @syms = qw( existsor );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Operator::ExistsOr/existsor"}++ if delete $syms{existsor};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
