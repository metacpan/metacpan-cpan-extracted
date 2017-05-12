package Queue::Q::ReliableFIFO;
use strict;
use warnings;

use Carp qw(croak);

# enqueue_item($item)
# enqueue_item(@items)
sub enqueue_item { croak("Unimplemented") }

# my $item_or_undef = claim_item($n) # $n is number of items to claim
sub claim_item { croak("Unimplemented") }

# mark_item_as_done($item_previously_claimed)
# mark_item_as_done(@item_previously_claimed)
sub mark_item_as_done { croak("Unimplemented") }

sub flush_queue { croak("Unimplemented") }

# my $nitems = queue_length()
# my $nitems = queue_length('busy')   # claimed items
# my $nitems = queue_length('failed') # failed items
sub queue_length { croak("Unimplemented") }

# consume(\&callback)
sub consume  { croak("Unimplemented") }


1;
__END__

=head1 NAME

Queue::Q::ReliableFIFO - FIFO queue keeping track of claimed items

=head1 SYNOPSIS

  use Queue::Q::ReliableFIFO::Redis; # or ::Perl or ...
  my $q = ... create object of chosen ReliableFIFO implementation...
  
  # producer:
  $q->enqueue_item([qw(my data structure)]); # rinse repeat...
  
  # consumer:
  my $item = $q->claim_item;
  # work with data...
  $q->mark_item_as_done($item);
  
  # Implementation dependent: somewhere in a recovery cron job
  # - Fetch claimed items older than $n minutes/seconds
  # - Requeue or log&drop those timed-out items

=head1 DESCRIPTION

Abstract interface class for a FIFO queue that keeps track
of all in-flight ("claimed") items. Implementations are
required to provide strict ordering and adhere to
the run-time complexities listed below (or better).

The general workflow with C<Queue::Q::ReliableFIFO> based
queue is:

=over 2

=item *

Producer enqueues one or multiple items.

=item *

Consumer claims one or multiple items and works on them.

=item *

Consumer marks its claimed items as done.

=back

To recover from failed consumers, one may apply in any one of many
application specific recovery strategies such as periodically
re-enqueuing all claimed items that are older than a threshold
or possible simply clearing them out and logging the fact.

Since the actual recovery strategy is application-dependent and the
support by the queue implementation may vary, there's no API for this
in this abstract base class. That may change in a future release.

=head1 METHODS

=head2 enqueue_item

Given a data structure, that data structure is added to
the queue. Items enqueued with C<enqueue_item> in order
must be returned by C<claim_item> in the same order.

Complexity: O(1)

=head2 enqueue_items

Given a number data structures, enqueues them in order.
This is conceptually the same as calling C<enqueue_item> multiple
times, but may help save on network round-trips.

Complexity: O(n) where n is the number of items to enqueue.

=head2 claim_item

Returns the oldest item in the queue. Returns C<undef>
if there is none left.

Complexity: O(1)

Implementations may (but should not)
deviate from the strict O(1) complexity
for the number of B<claimed> items at any given time. That is
acceptable as high as O(log(n)). This is likely acceptable
because the number of items being worked on is likely not
to be extremely large.
Implementations that make use of this relaxed requirement
must document that clearly.
The number of B<queued> items
must not affect the complexity, however.

=head2 claim_items

As C<enqueue_items> is to C<enqueue_item>, C<claim_items> is to
C<claim_item>. Takes one optional parameter (defaults to 1):
The number of items to fetch and return:

  my @items = $q->claim_items(20); # returns a batch of 20 items

If there are less than the desired number of items to be claimed,
returns a correspondingly shorter list.

Complexity: O(n) where n is the number of items claimed.

See the documentation of C<claim_item> for a potential relaxation
on the complexity bounds with respect to the number of
in-flight, claimed items.

=head2 mark_item_as_done

Given a item that was previously
claimed from this queue, it is removed from the claimed-items
tracking and thus removed from the queue altogether.

Complexity: Generally O(1), but O(log(n)) under relaxed requirements
(see above).

=head2 mark_items_as_done

Given any number of items that were
previously claimed from this queue, they are removed from the claimed-items
tracking and thus removed from the queue altogether.

Complexity: Generally O(n), but O(n*log(n)) under relaxed requirements
(see above) with n understood to be the number of items to mark as done.

=head2 queue_length

Returns the number of items available in the queue.

Complexity: O(1)

=head2 flush_queue

Removes all content in the queue.

Complexity: O(n) where n is the number of items in the queue.

=head1 AUTHOR

Herald van der Breggen, E<lt>herald.vanderbreggen@booking.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Herald van der Breggen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
