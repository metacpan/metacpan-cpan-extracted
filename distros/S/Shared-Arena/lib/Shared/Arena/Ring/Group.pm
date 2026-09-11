package Shared::Arena::Ring::Group;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Ring::Group - one record to one member of the pool

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    # in the parent, before the fork
    my $ring = $arena->ring('work', slots => 4096, slot_size => 512);
    my $jobs = $ring->group('workers', topic => 'jobs');

    # in every worker, after the fork
    for my $rec ($jobs->claim(max => 8)) {
        my ($topic, $payload, $seq) = @$rec;
        do_the_work($payload);          # nobody else was given this one
    }

=head1 DESCRIPTION

L<Shared::Arena::Ring::Cursor> is a broadcast: a cursor lives in the process
that made it, so every reader holding one sees every record. That is what you
want for a chat room, and it is exactly wrong for a pool of workers, where four
processes would each do all of the work.

A B<group> is a queue. Its cursor lives in the ring's own region, so every
member advances the same word and whoever wins the compare-and-swap owns that
record. B<The difference between a broadcast and a queue is where the cursor
lives, and nothing else.>

The load balancing falls out of the claim and needs no scheduler: a worker busy
with the last record is not in the claim loop, so it is not claiming, so the
free ones take the next. Four workers over four hundred records measured a
hundred each.

Get one from C<< $ring->group($name) >>. Every process asks for the same name;
the first creates it and the rest join.

=head2 At most once, which is a data-loss decision

B<A member that claims a record and then dies loses it.> The claim moved the
shared cursor and nothing remains that says which record was in flight or who
held it.

That is deliberate rather than an oversight. Making it at-least-once means
recording the claimant with every claim and having a survivor prove it dead and
re-claim, which is a durable queue rather than a cursor. Choosing wrongly here
is a data-loss bug rather than a slow path, so it is stated beside the feature:
if losing a record when a worker segfaults is not acceptable, this is not the
structure you want.

Everything else the ring loses is counted. C<lapped> is records that went past
before anybody claimed them, which means the pool is not keeping up or the ring
is too small.

=head2 Bound to a topic

    my $jobs = $ring->group('w', topic => 'jobs');

A bound group delivers only records whose topic matches, and advances past the
rest, counting them in C<skipped>.

Groups do not consume from each other: each has its own cursor, so one record
can go to one member of every group that wants it. A group and a plain cursor on
the same ring do not interfere either - the cursor still sees everything.

=head2 Where a new group starts

At the ring's current position, so a worker joining a pool gets the work that
arrives after it rather than a replay of whatever the ring still holds. Pass
C<< from_start => 1 >> to want the replay.

This catches people out in tests: publish first, then create the group, and the
group correctly sees nothing.

=head1 METHODS

=head2 claim

    my @records = $g->claim;              # up to one
    my @records = $g->claim(max => 8);    # up to eight
    my @records = $g->claim(max => 0);    # everything available

Records this worker has claimed, as C<[topic, payload, sequence]> arrayrefs.
Each is this process's alone. An empty list means there is nothing to take right
now - not that the ring is finished.

It never blocks. A worker loop waits on C<< $arena->waker_fd >> and claims when
it is woken.

Do not call it in scalar context expecting a count: an XSUB returning a list in
scalar context hands back its last element.

=head2 position

    my $seq = $g->position;

The group's shared position: the sequence every member is working from. It is
the pool's, not this process's, and it survives every member leaving.

=head2 topic

    my $t = $g->topic;

What the group is bound to, or C<undef> when it takes everything.

=head2 stats

    my %s = $g->stats;
    # name, topic, position, delivered, lapped, skipped, mine

C<delivered> is the pool's, across every member. C<mine> is this process's share
of it, and comparing the two is what says whether the work is spread or whether
one worker is doing all of it.

=head1 CAVEATS

A group handle going out of scope is a member B<leaving>, not the group being
destroyed. The cursor in the mapping stays where it is, because other workers
are still claiming from it, and the next member picks up where the pool left
off. There is no way to delete a group: the table holds 64 of them and they last
as long as the ring.

=head1 SEE ALSO

L<Shared::Arena::Ring>, L<Shared::Arena::Ring::Cursor>, L<Shared::Arena>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
