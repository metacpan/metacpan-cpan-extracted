#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Basic queue role used by the Piper system
#####################################################################

package Piper::Role::Queue;

use v5.10;
use strict;
use warnings;

use Moo::Role;

our $VERSION = '0.05'; # from Piper-0.05.tar.gz

#pod =head1 DESCRIPTION
#pod
#pod =for stopwords dequeued queueing
#pod
#pod The role exists to support future subclassing of L<Piper> (and L<testing|/TESTING> such subclasses) with alternate queueing systems.
#pod
#pod =head1 REQUIRES
#pod
#pod This role requires the following object methods.
#pod
#pod =head2 dequeue($num)
#pod
#pod Removes and returns C<$num> items from the queue.
#pod
#pod Default C<$num> should be 1.  If wantarray, should return an array of items from the queue.  Otherwise, should return the last of the dequeued items (allows singleton dequeues, behaving similar to splice):
#pod
#pod   Ex:
#pod   my @results = $queue->dequeue($num);
#pod   my $single = $queue->dequeue;
#pod
#pod If requesting more items than are left in the queue, should only return the items left in the queue (and should not return C<undef>s as placeholders).
#pod
#pod =cut

requires 'dequeue';

#pod =head2 enqueue(@items)
#pod
#pod Adds the C<@items> to the queue.  It should not matter what the C<@items> contain, within reason.
#pod
#pod =cut

requires 'enqueue';

#pod =head2 ready
#pod
#pod Returns the number of items that are ready to be dequeued.
#pod
#pod =cut

requires 'ready';

#pod =head2 requeue(@items)
#pod
#pod Inserts the C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.
#pod
#pod =cut

requires 'requeue';

#pod =head1 TESTING
#pod
#pod Verify the functionality of a new queue class by downloading the L<Piper> tests and running the following:
#pod
#pod   PIPER_QUEUE_CLASS=<New queue class> prove t/01_Queue.t
#pod
#pod =cut

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim dequeued queueing

=head1 NAME

Piper::Role::Queue - Basic queue role used by the Piper system

=head1 DESCRIPTION

The role exists to support future subclassing of L<Piper> (and L<testing|/TESTING> such subclasses) with alternate queueing systems.

=head1 REQUIRES

This role requires the following object methods.

=head2 dequeue($num)

Removes and returns C<$num> items from the queue.

Default C<$num> should be 1.  If wantarray, should return an array of items from the queue.  Otherwise, should return the last of the dequeued items (allows singleton dequeues, behaving similar to splice):

  Ex:
  my @results = $queue->dequeue($num);
  my $single = $queue->dequeue;

If requesting more items than are left in the queue, should only return the items left in the queue (and should not return C<undef>s as placeholders).

=head2 enqueue(@items)

Adds the C<@items> to the queue.  It should not matter what the C<@items> contain, within reason.

=head2 ready

Returns the number of items that are ready to be dequeued.

=head2 requeue(@items)

Inserts the C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.

=head1 TESTING

Verify the functionality of a new queue class by downloading the L<Piper> tests and running the following:

  PIPER_QUEUE_CLASS=<New queue class> prove t/01_Queue.t

=head1 SEE ALSO

=over

=item L<Piper>

=back

=head1 VERSION

version 0.05

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
