#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Finally 0.01;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Keyword::Finally> - add C<FINALLY> phaser block syntax to perl

=head1 SYNOPSIS

   use Syntax::Keyword::Finally;

   {
      my $dbh = DBI->connect( ... ) or die "Cannot connect";
      FINALLY { $dbh->disconnect; }

      my $sth = $dbh->prepare( ... ) or die "Cannot prepare";
      FINALLY { $sth->finish; }

      ...
   }

=head1 DESCRIPTION

This module provides a syntax plugin that implements a phaser block that
executes its block when the containing scope has finished. The syntax of the
C<FINALLY> block looks similar to other phasers in perl (such as C<BEGIN>),
but the semantics of its execution are different.

The operation can be considered a little similar to an C<END> block, but with
the following key differences:

=over 2

=item *

A C<FINALLY> block runs at the time that execution leaves the block it is
declared inside, whereas an C<END> block runs at the end time of the entire
program regardless of its location.

=item *

A C<FINALLY> block is invoked at the time its containing scope has finished,
which means it might run again if the block is entered again later in the
program. An C<END> block will only ever run once.

=item *

A C<FINALLY> block will only take effect if execution reaches the line it is
declared on; if the line is not reached then nothing happens. An C<END> block
will always be invoked once declared, regardless of the dynamic extent of
execution at runtime.

=back

C<FINALLY> blocks are primarily intended for cases such as resource
finalisation tasks that may be conditionally required.

For example in the synopsis code, after normal execution the statement handle
will be finished using the C<< $sth->finish >> method, then the database will
be disconnected with C<< $dbh->disconnect >>. If instead the prepare method
failed then the database will still be disconnected, but there is no need to
finish with the statement handle as the second C<FINALLY> block was never
encountered.

=cut

=head1 KEYWORDS

=head2 FINALLY

   FINALLY {
      STATEMENTS...
   }

The C<FINALLY> keyword introduces a phaser block (similar to e.g. C<BEGIN> and
C<END>), which runs its code body at the time that its immediately surrounding
code block finishes.

When the C<FINALLY> statement is encountered, the body of the code block is
pushed to a queue of pending operations, which is then flushed when the
surrounding block finishes for any reason - either by implicit fallthrough,
or explicit termination by C<return>, C<die> or any of the loop control
statements C<next>, C<last> or C<redo>.

   sub f
   {
      FINALLY { say "The function has now returned"; }
      return 123;
   }

If multiple C<FINALLY> statements appear within the same block, they are
pushed to the queue in LIFO order; the last one encountered is the first one
to be executed.

   {
      FINALLY { say "This happens second"; }
      FINALLY { say "This happens first"; }
   }

A C<FINALLY> phaser will only take effect if the statement itself is actually
encountered during normal execution. This is in direct contrast to an C<END>
phaser which always occurs. This makes it ideal for handling finalisation of a
resource which was created on a nearby previous line, where the code to create
it might have thrown an exception instead. Because the exception skipped over
the C<FINALLY> statement, the code body does not need to run.

   my $resource = Resource->open( ... );
   FINALLY { $resource->close; }

=cut

sub import
{
   my $pkg = shift;
   my $caller = caller;

   $pkg->import_into( $caller, @_ );
}

sub import_into
{
   my $pkg = shift;
   my ( $caller, @syms ) = @_;

   @syms or @syms = qw( finally );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Keyword::Finally/finally"}++ if delete $syms{finally};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 TODO

This module contains a unit test file copied and edited from my core perl
branch to provide the same syntax. Several test cases are currently commented
out because this implementation does not yet handle them:

=over 4

=item *

Ensure that C<FINALLY> blocks can throw exceptions.

=item *

Complain on attempts to C<return>, C<goto>, or C<next/last/redo> out of a
C<FINALLY> block.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
