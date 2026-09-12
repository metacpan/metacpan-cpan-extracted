package Shared::Arena::Ring;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Ring - a record queue several processes can write at once

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $ring  = $arena->ring('events', slots => 4096, slot_size => 512);

    # any number of processes, no lock between them
    $ring->publish('order.paid', $payload);

    # each reader has its own position and sees everything
    my $cursor = $ring->cursor;
    for my $rec ($cursor->drain) {
        my ($topic, $payload, $seq) = @$rec;
    }

=head1 DESCRIPTION

A ring lives in an arena and is written by as many processes as care to,
without a lock and without a syscall. Readers are independent: each has its own
cursor, each sees every record, and a slow one never blocks a writer.

Get one from C<< $arena->ring($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 A ring has a fixed size, and forgets

The ring holds a fixed number of records. When it fills, the oldest is
overwritten: a publisher never blocks and never fails because a reader is
behind.

Nothing is lost quietly. A reader that has been overtaken discovers it, skips
to the oldest record still present, and adds what it missed to its own count.
For any cursor, at any moment,

    delivered + lapped + abandoned == published

so a caller can always say exactly how much it did not see. Size the ring for
the slowest reader you are willing to serve, and watch C<lapped>.

=head2 What a record can carry

A record is a topic and a payload, both arbitrary bytes, both allowed to be
empty. Neither is inspected: a topic is only a label the reader may look at.

A record larger than one slot is carried across several. One larger than half
the ring is B<refused>, and C<publish> returns -1. It is never truncated: a
truncated record arrives with the right sequence and the right topic and a body
that silently is not what was sent, which a reader has no way to detect.

Ask C<max_record> for the ceiling rather than working it out. It is the total
of topic and payload together, it depends on how the ring was configured, and
a caller that hard-codes it starts refusing records the day somebody changes
the configuration.

=head2 Records arrive in order, and whole

Every record is given a sequence when it is published, and cursors deliver in
sequence order. A single publisher's records therefore always arrive in the
order it wrote them, however much of the stream around them was lost.

A record is delivered whole or not at all. There is no state in which half of
one and half of another arrive together.

=head1 METHODS

=head2 publish

    my $seq = $ring->publish($topic, $payload);

Returns the record's B<sequence>, which is always greater than zero. Returns 0
when there is no usable ring, and -1 when the record was refused for size.

One value rather than a pair, and deliberately not a context-sensitive one:
C<< is($ring->publish(...), 1) >> would call it in list context and compare its
two return values against each other.

=head2 cursor

    my $cursor = $ring->cursor;
    my $cursor = $ring->cursor(from_start => 1);

A new reader, starting at B<now>: it sees what happens next and does not replay
what it missed. That is what a tail wants, and a process attaching to a busy
ring is almost always asking about the future.

C<< from_start => 1 >> begins at the oldest record the ring still holds.

Every cursor is independent. Two of them see the same records; neither consumes
anything from the other.

=head2 group

    my $g = $ring->group('workers');
    my $g = $ring->group('workers', topic => 'jobs');

A L<Shared::Arena::Ring::Group>: the same ring read as a B<queue> rather than a
broadcast. A cursor lives in the process that made it, so every reader sees
every record; a group's cursor lives in the ring, so each record goes to
exactly B<one> member of the pool.

    for my $rec ($g->claim(max => 8)) { ... }   # nobody else got these

Use a cursor when every worker needs to know, and a group when the work needs
doing once. Both can read one ring at the same time without interfering.

B<At most once>: a member that claims a record and then dies loses it. See
L<Shared::Arena::Ring::Group/At most once, which is a data-loss decision>.

=head2 max_record

    my $bytes = $ring->max_record;

The largest topic and payload together that this ring will carry. Ask, do not
assume.

=head2 slot_bytes

    my $bytes = $ring->slot_bytes;

What fits in a single slot. A record within this uses one slot; a larger one
spans several. Useful for sizing a ring, and of no interest at publish time.

=head2 slots

    my $n = $ring->slots;

=head2 stats

    my %s = $ring->stats;   # published, oversize, seq

Counted across every process, for the life of the ring. C<seq> is the next
sequence to be handed out.

=head1 CONFIGURING A RING

C<slots> and C<slot_size> are given once, by whoever creates it, and every
later attacher must ask for the same shape or be refused.

    my $ring = $arena->ring('events', slots => 4096, slot_size => 512);

C<slots> is how many records the ring holds when they are small, and it is what
decides how far behind a reader may fall. C<slot_size> is the space one slot
gives to a topic and payload plus a small header; make it comfortably larger
than a typical record and let the unusual ones span.

Both cost memory whether used or not: a ring occupies C<slots * slot_size>
bytes for its life.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Ring::Cursor>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
