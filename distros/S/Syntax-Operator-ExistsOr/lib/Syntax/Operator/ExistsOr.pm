#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

package Syntax::Operator::ExistsOr 0.02;

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

Support for custom infix operators was added in the Perl 5.37.x development
cycle and is available from development release v5.37.7 onwards, and therefore
in Perl v5.38 onwards. The documentation of L<XS::Parse::Infix>
describes the situation in more detail.

While Perl versions before this do not support custom infix operators, they
can still be used via C<XS::Parse::Infix> and hence L<XS::Parse::Keyword>.
Custom keywords which attempt to parse operator syntax may be able to use
these.

This module does not provide wrapper functions for the operators, as their
inherent short-circuiting behaviour would appear confusing when expressed in
function-like syntax.

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

   @syms or @syms = qw( existsor );

   my %syms = map { $_ => 1 } @syms;
   if( delete $syms{existsor} ) {
      $on ? $^H{"Syntax::Operator::ExistsOr/existsor"}++
          : delete $^H{"Syntax::Operator::ExistsOr/existsor"};
   }

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

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

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
