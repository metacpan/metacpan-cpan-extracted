package Shared::Arena::Map;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Map - a fixed-capacity map several processes share

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $map   = $arena->map('cache', slots => 4096, slot_size => 512);

    $map->store('user:42', $blob);
    my ($blob) = $map->fetch('user:42');

    # counters are one atomic, so a rate limit costs nothing to share
    my $hits = $map->incr("rate:$ip");

=head1 DESCRIPTION

A map in an arena, written and read by any number of processes. Reads take no
lock. Writes take one of a stripe of locks, so two writers touching different
keys almost never meet.

Get one from C<< $arena->map($name) >>. Every process can ask for the same name
with the same arguments; the first creates it and the rest attach.

Keys and values are both arbitrary bytes. Neither is interpreted, and both may
contain anything, including NUL. A key must not be empty; a value may be.

=head2 It has a fixed size, and does not grow

The table is sized once and never rehashes. Growing a table that other
processes are reading means moving entries they are part-way through looking
for, and the only safe ways to do that are to stop every process or to keep two
tables alive until the last reader has left. Neither belongs in something whose
whole appeal is that a read is a hash and a compare.

So a full table B<refuses> a new key and C<store> returns 0. Watch C<used>
against C<capacity>, and size the table for the worst case you will accept.

Overwriting a key that is already there always works, full table or not: it
needs no new slot.

=head2 What deleting leaves behind

A deleted entry becomes a tombstone rather than an empty slot, and this is not
an implementation detail a caller can ignore. An empty slot ends a search, so
turning a deleted entry into one would make every key stored past it
unreachable. The tombstone keeps the path open.

Tombstones are reused by the next key that lands on one, but they are never
swept. A workload that deletes constantly will accumulate them and start
refusing keys while C<used> still looks low. C<tombstones> is in the stats so
that is a number rather than a mystery. If you are churning keys, size for
C<used + tombstones>, or use a fresh map.

=head2 Reading while somebody writes

A value can be replaced while another process is reading it. Each entry carries
a version, so a reader that copied a value while it was being replaced notices
and tries again.

A reader that keeps losing gives up after a bounded number of attempts. It
reports the key as B<not readable>, which C<fetch> spells as an empty list, and
counts a C<busy>. B<A non-zero C<busy> does not mean a key was missing>: it
means a fetch gave up on an entry that may well be there. It should be rare
enough to be interesting.

=head1 METHODS

=head2 store

    my $rc = $map->store($key, $value);

1 when stored, 0 when the table is full, -1 when the key is empty or the pair
does not fit a slot.

=head2 fetch

    my ($value) = $map->fetch($key);

The value, or an B<empty list> when the key is not there. Not C<undef>: C<undef>
is a value a caller may legitimately store, and a door that used it to mean
absent could not tell the two apart. Use C<exists> to ask the other question.

=head2 exists

    if ($map->exists($key)) { ... }

=head2 delete

    my $was_there = $map->delete($key);

=head2 incr

    my $now = $map->incr($key);
    my $now = $map->incr($key, $by);

Adds to a counter, creating it at C<$by> when the key is absent, and returns the
new value. C<$by> may be negative. Returns C<undef> when the table is full, or
when the key holds something that is not a counter.

This is the one operation that does not go through the version at all: a counter
is a single machine word, so the addition is one atomic instruction and cannot
be seen half-done. Two hundred processes incrementing one key lose nothing, and
a shared rate limit costs about what incrementing a variable costs.

A key holding a value that is not a counter is refused rather than
reinterpreted. Storing a string and then counting on it is a bug, and quietly
overwriting the string would hide both the bug and the string.

=head2 counter

    my $n = $map->counter($key);

A counter's value without changing it, or C<undef> when the key is absent or
holds something else.

=head2 keys

    my @keys = $map->keys;

Every live key, in the table's own order, which is neither insertion order nor
sorted.

B<A snapshot, not a lock.> Entries may be added or removed while this walks, so
a key it returns may be gone by the time you use it, and one added behind the
walk will not appear. It is for looking at a table, not for iterating one that
is being written.

=head2 stats

    my %s = $map->stats;
    # used, capacity, tombstones, busy, full

=head2 max_pair, capacity

    my $bytes = $map->max_pair;    # key + value that fits one slot
    my $slots = $map->capacity;

=head1 SIZING A MAP

    my $map = $arena->map('cache', slots => 4096, slot_size => 512);

C<slots> is the number of entries, and there is no load factor to leave room
for beyond your own: an open-addressed table slows down as it fills, so leave
headroom rather than sizing it exactly. C<slot_size> bounds a key and its value
together; ask C<max_pair> rather than working it out.

A map costs C<slots * slot_size> bytes for its life, used or not.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Ring>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
