#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Finally 0.08;

use v5.14;
use warnings;

=head1 NAME

C<Syntax::Keyword::Finally> - add C<FINALLY> phaser block syntax to perl (REMOVED)

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

This module used to provide a syntax plugin that implements a keyword called
C<FINALLY>. The keyword has now been renamed to C<defer>.

You should change any code currently using it, to L<Syntax::Keyword::Defer>
instead.

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub import_into
{
   croak "'FINALLY' has now been removed; use Syntax::Keyword::Defer instead";
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
