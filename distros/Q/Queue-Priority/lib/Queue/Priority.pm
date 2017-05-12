package Queue::Priority;

=head1 NAME

Queue::Priority

=head1 SYNOPSIS

    use Queue::Priority;
    use List::Util qw( shuffle );

    my $queue = Queue::Priority->new( 10 );

    foreach my $i ( shuffle 1 .. 10 ) {
        $queue->insert( $i );
    }

    while (1) {
        my $i = $queue->remove or last;
        printf "%d * 2 = %d\n", $i, $i * 2;
    }

=head1 DESCRIPTION

Priority queues automatically order their contents according to the inserted
item's priority. Calling code must ensure that their queue items are comparable
via this strategy (e.g. by overloading the <=> operator). This module is
implemented as an array heap.

=cut

use strict;
use warnings;
use Carp;
use Const::Fast;
use POSIX qw(floor);

our $VERSION = 1.0;

const my $SLOT_DATA  => 0;
const my $SLOT_COUNT => 1;
const my $SLOT_MAX   => 2;
const my $SLOT_DONE  => 3;

=head1 METHODS

=head2 new

Creates a new queue that can store C<$max> items.

=cut

sub new {
    my ( $class, $max ) = @_;

    croak 'expected positive int for $max'
        unless defined $max
            && $max > 0;

    # Pre-allocate array
    my @arr;
    $#arr = $max - 1;

    my $self = bless [], $class;
    $self->[ $SLOT_DATA  ] = \@arr;
    $self->[ $SLOT_COUNT ] = 0;
    $self->[ $SLOT_MAX   ] = $max;
    $self->[ $SLOT_DONE  ] = 0;

    return $self;
}

=head2 count

Returns the number of items currently stored.

=head2 is_empty

Returns true if the queue is empty.

=head2 is_full

Returns true if the queue is full.

=head2 peek

Returns the first (highest priority) element in the queue without removing it
from the queue.

=head2 is_shutdown

Returns true if the queue has been shut down.

=cut

sub count       { $_[0]->[ $SLOT_COUNT ] }
sub is_empty    { $_[0]->[ $SLOT_COUNT ] == 0 }
sub is_full     { $_[0]->[ $SLOT_COUNT ] >= $_[0]->[ $SLOT_MAX ] }
sub peek        { $_[0]->[ $SLOT_DATA ][ $_[1] || 0 ] }
sub is_shutdown { $_[0]->[ $SLOT_DONE ] };

=head2 shutdown

Shuts down the queue, after which no items may be inserted. Items already in
the queue can be pulled normally until empty, after which further calls to
C<remove> will return undefined.

=cut

sub shutdown {
    my $self = shift;
    $self->[ $SLOT_DONE ] = 1;
}

=head2 insert

Inserts an item into the queue. Dies if the queue is full, has been
shut down, or if the only argument is undefined.

=cut

sub insert {
    my ( $self, $item ) = @_;
    croak 'cannot insert undef' unless defined $item;
    croak 'queue is shut down' if $self->is_shutdown;
    croak 'queue is full' if $self->is_full;

    ++$self->[ $SLOT_COUNT ];

    # Place item at the bottom of the heap and sift up
    my $arr    = $self->[0];
    my $idx    = $self->[1] - 1;
    my $parent = $idx == 0 ? undef : floor( ( $idx - 1 ) / 2 );

    $self->[0][ $idx ] = $item;

    while ( defined $parent && $arr->[ $idx ] < $arr->[ $parent ] ) {
        @$arr[ $idx, $parent ] = @$arr[ $parent, $idx ];
        $idx    = $parent;
        $parent = $idx == 0 ? undef : floor( ( $idx - 1 ) / 2 );
    }

    return $self->[1];
}

=head2 remove

Removes and returns an item from the queue. If the queue is empty or shutdown,
returns undefined immediately.

=cut

sub remove {
    my $self = shift;

    return if $self->is_shutdown
           || $self->is_empty;

    my $item = shift @{ $self->[0] };
    --$self->[ $SLOT_COUNT ];

    # Move the last item to the root
    unshift @{ $self->[0] }, pop @{ $self->[0] };

    # Sift down
    my $idx  = 0;
    my $last = $self->[1] - 1;
    my $arr  = $self->[0];

    while ( 1 ) {
        my $l = $idx * 2 + 1;
        my $r = $idx * 2 + 2;

        last if $l > $last && $r > $last;

        my $least;

        if ( $r > $last ) {
            $least = $l;
        }
        else {
            $least = $arr->[$l] <= $arr->[$r] ? $l : $r;
        }

        if ( $arr->[ $idx ] > $arr->[ $least ] ) {
            @$arr[ $idx, $least ] = @$arr[ $least, $idx ];
            $idx = $least;
        }
        else {
            last;
        }
    }

    return $item;
}

=head1 DEBUG

=head2 dump

Prints an indented representation of the heap structure.

=cut

sub dump {
    my $self = shift;
    printf "Heap (%d/%d)\n", $self->[ $SLOT_COUNT ], $self->[ $SLOT_MAX ];
    $self->_dump( 0, 0 );
}

sub _dump {
    my ( $self, $idx, $indent ) = @_;
    return unless defined $self->peek( $idx );

    if ( $indent > 0 ) {
        print '  ' for ( 1 .. $indent );
    }

    printf "- %s\n", $self->peek( $idx );

    my $l = $idx * 2 + 1;
    my $r = $idx * 2 + 2;
    $self->_dump( $l, $indent + 1 );
    $self->_dump( $r, $indent + 1 );
}

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut

1;
