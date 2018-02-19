#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple FIFO queue used by Piper
#####################################################################

package Piper::Queue;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(ArrayRef);

use Moo;
use namespace::clean;

with 'Piper::Role::Queue';

our $VERSION = '0.05'; # from Piper-0.05.tar.gz

#pod =head1 SYNOPSIS
#pod
#pod =for stopwords dequeued
#pod
#pod   use Piper::Queue;
#pod
#pod   my $queue = Piper::Queue->new();
#pod   $queue->enqueue(qw(x y));
#pod   $queue->ready;         # 2
#pod   $queue->dequeue;       # 'x'
#pod   $queue->requeue('x');
#pod   $queue->dequeue;       # 'x'
#pod
#pod =head1 CONSTRUCTOR
#pod
#pod =head2 new
#pod
#pod =cut

has queue => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

#pod =head1 METHODS
#pod
#pod =head2 dequeue($num)
#pod
#pod Remove and return at most C<$num> items from the queue.  The default S<C<$num> is 1>.
#pod
#pod If C<$num> is greater than the number of items remaining in the queue, only the number remaining will be dequeued.
#pod
#pod Returns an array of items if wantarray, otherwise returns the last of the dequeued items, which allows singleton dequeues:
#pod
#pod     my @results = $queue->dequeue($num);
#pod     my $single  = $queue->dequeue;
#pod
#pod =cut

sub dequeue {
    my ($self, $num) = @_;
    $num //= 1;
    splice @{$self->queue}, 0, $num;
}

#pod =head2 enqueue(@items)
#pod
#pod Add C<@items> to the queue.
#pod
#pod =cut

sub enqueue {
    my $self = shift;
    push @{$self->queue}, @_;
}

#pod =head2 ready
#pod
#pod Returns the number of elements in the queue.
#pod
#pod =cut

sub ready {
    my ($self) = @_;
    return scalar @{$self->queue};
}

#pod =head2 requeue(@items)
#pod
#pod Inserts C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.
#pod
#pod =cut

sub requeue {
    my $self = shift;
    unshift @{$self->queue}, @_;
}

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim dequeued

=head1 NAME

Piper::Queue - Simple FIFO queue used by Piper

=head1 SYNOPSIS

  use Piper::Queue;

  my $queue = Piper::Queue->new();
  $queue->enqueue(qw(x y));
  $queue->ready;         # 2
  $queue->dequeue;       # 'x'
  $queue->requeue('x');
  $queue->dequeue;       # 'x'

=head1 CONSTRUCTOR

=head2 new

=head1 METHODS

=head2 dequeue($num)

Remove and return at most C<$num> items from the queue.  The default S<C<$num> is 1>.

If C<$num> is greater than the number of items remaining in the queue, only the number remaining will be dequeued.

Returns an array of items if wantarray, otherwise returns the last of the dequeued items, which allows singleton dequeues:

    my @results = $queue->dequeue($num);
    my $single  = $queue->dequeue;

=head2 enqueue(@items)

Add C<@items> to the queue.

=head2 ready

Returns the number of elements in the queue.

=head2 requeue(@items)

Inserts C<@items> to the top of the queue in an order such that C<dequeue(1)> would subsequently return C<$items[0]> and so forth.

=head1 SEE ALSO

=over

=item L<Piper::Role::Queue>

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
