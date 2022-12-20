#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

package Syntax::Keyword::Defer 0.08;

use v5.14;
use warnings;

use Carp;

our @CARP_NOT = qw( Syntax::Keyword::Finally );

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Syntax::Keyword::Defer> - execute code when leaving a block

=head1 SYNOPSIS

   use Syntax::Keyword::Defer;

   {
      my $dbh = DBI->connect( ... ) or die "Cannot connect";
      defer { $dbh->disconnect; }

      my $sth = $dbh->prepare( ... ) or die "Cannot prepare";
      defer { $sth->finish; }

      ...
   }

=head1 DESCRIPTION

This module provides a syntax plugin that implements a block which executes
when the containing scope has finished.

It similar to features provided by other languages; Swift, Zig, Jai, Nim and
Odin all provide this. Note that while Go also provides a C<defer> keyword,
the semantics here are not the same. Go's version defers until the end of the
entire function, rather than the closest enclosing scope as is common to most
other languages, and this module.

The operation can be considered a little similar to an C<END> block, but with
the following key differences:

=over 2

=item *

A C<defer> block runs at the time that execution leaves the block it is
declared inside, whereas an C<END> block runs at the end time of the entire
program regardless of its location.

=item *

A C<defer> block is invoked at the time its containing scope has finished,
which means it might run again if the block is entered again later in the
program. An C<END> block will only ever run once.

=item *

A C<defer> block will only take effect if execution reaches the line it is
declared on; if the line is not reached then nothing happens. An C<END> block
will always be invoked once declared, regardless of the dynamic extent of
execution at runtime.

=back

C<defer> blocks are primarily intended for cases such as resource finalisation
tasks that may be conditionally required.

For example in the synopsis code, after normal execution the statement handle
will be finished using the C<< $sth->finish >> method, then the database will
be disconnected with C<< $dbh->disconnect >>. If instead the prepare method
failed then the database will still be disconnected, but there is no need to
finish with the statement handle as the second C<defer> block was never
encountered.

=cut

=head1 KEYWORDS

=head2 defer

   defer {
      STATEMENTS...
   }

The C<defer> keyword introduces a block which runs its code body at the time
that its immediately surrounding code block finishes.

When the C<defer> statement is encountered, the body of the code block is
pushed to a queue of pending operations, which is then flushed when the
surrounding block finishes for any reason - either by implicit fallthrough,
or explicit termination by C<return>, C<die> or any of the loop control
statements C<next>, C<last> or C<redo>.

   sub f
   {
      defer { say "The function has now returned"; }
      return 123;
   }

If multiple C<defer> statements appear within the same block, they are pushed
to the queue in LIFO order; the last one encountered is the first one to be
executed.

   {
      defer { say "This happens second"; }
      defer { say "This happens first"; }
   }

A C<defer> block will only take effect if the statement itself is actually
encountered during normal execution. This is in direct contrast to an C<END>
phaser which always occurs. This makes it ideal for handling finalisation of a
resource which was created on a nearby previous line, where the code to create
it might have thrown an exception instead. Because the exception skipped over
the C<defer> statement, the code body does not need to run.

   my $resource = Resource->open( ... );
   defer { $resource->close; }

Unlike as would happen with e.g. a C<DESTROY> method on a guard object, any
exceptions thrown from a C<defer> block are still propagated up to the caller
in the usual way.

   use Syntax::Keyword::Defer;

   sub f
   {
      my $count = 0;
      defer { $count or die "Failed to increment count"; }

      # some code here
   }

   f();

Z<>

   $ perl example.pl
   Failed to increment count at examples.pl line 6.

However, if a C<defer> block is being run because of exceptional return of its
scope, any further exceptions it attempts to raise are turned into warnings.
This ensures that the original exception which caused the stack-unwind to run
the block in the first place does not get overwritten on the way.

Because a C<defer> block is a true block (e.g. in the same way something like
an C<if () {...}> block is), rather than an anonymous sub, it does not appear
to C<caller()> or other stack-inspection tricks. This is useful for calling
C<croak()>, for example.

   sub g
   {
      my $count = 0;
      defer { $count or croak "Expected some items"; }

      $count++ for @_;
   }

Here, C<croak()> will correctly report the caller of the C<g()> function,
rather than appearing to be called from an C<__ANON__> sub invoked at the end
of the function itself.

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

   @syms or @syms = qw( defer );

   my %syms = map { $_ => 1 } @syms;
   $^H{"Syntax::Keyword::Defer/defer"}++   if delete $syms{defer};

   croak "'FINALLY' has now been removed; use 'defer' instead" and $^H{"Syntax::Keyword::Defer/finally"}++
      if delete $syms{finally};

   croak "Unrecognised import symbols @{[ keys %syms ]}" if keys %syms;
}

=head1 TODO

This module contains a unit test file copied and edited from my core perl
branch to provide the same syntax. Several test cases are currently commented
out because this implementation does not yet handle them:

=over 4

=item *

Detection logic of defer-during-throw is currently based on the truth of the
C<ERRSV> (C<$@>), which means it is liable to false positives. There may not
be much that can be done about this.

=item *

Try to fix the double-exception test failure on Perl versions before v5.20.
(Test currently skipped on those versions)

=item *

Try to detect and forbid nonlocal flow control (C<goto>, C<next/last/redo>)
from leaving the C<defer> block.

E.g. currently the following will crash the interpreter:

   sub func { last ITEM }

   ITEM: foreach(1..10) {
      say;
      defer { func() }
   }

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
