#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Finally 0.05;

use v5.14;
use warnings;

=head1 NAME

C<Syntax::Keyword::Finally> - add C<FINALLY> phaser block syntax to perl

=head1 SYNOPSIS

See instead L<Syntax::Keyword::Defer>.

   use Syntax::Keyword::Defer;

   {
      my $dbh = DBI->connect( ... ) or die "Cannot connect";
      defer { $dbh->disconnect; }

      my $sth = $dbh->prepare( ... ) or die "Cannot prepare";
      defer { $sth->finish; }

      ...
   }

=head1 DESCRIPTION

This module provides a syntax plugin that implements a phaser block that
executes its block when the containing scope has finished. The syntax of the
C<FINALLY> block looks similar to other phasers in perl (such as C<BEGIN>),
but the semantics of its execution are different.

The keyword has now been renamed to C<defer> but is otherwise identical to the
syntax and semantics that were provided here. This module currently provides
a back-compatibility layer.

This will be removed in a later version. You should change any code currently
using it, to L<Syntax::Keyword::Defer> instead.

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub import_into
{
   require Syntax::Keyword::Defer;
   Syntax::Keyword::Defer->import_into( $_[0], 'finally' );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
