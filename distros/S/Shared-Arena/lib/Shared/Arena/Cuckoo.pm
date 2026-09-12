package Shared::Arena::Cuckoo;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Cuckoo - a shared set that answers "no" exactly, "yes" probably, and can forget

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $seen  = $arena->cuckoo('nonces', capacity => 1_000_000);

    # refuse a replayed nonce, in any process
    return $c->status(409) if $seen->check($nonce);
    $seen->add($nonce) or warn "the nonce filter is full\n";

    # and forget it when its window closes
    $seen->remove($nonce);

=head1 DESCRIPTION

A table of short fingerprints, with two candidate buckets for every key. Adding
a key puts its fingerprint in one of its two buckets, and asking about a key
looks in both. A key that was added is always in one of them, so a "no" is
B<definitely> right. A "yes" means a matching fingerprint is there: B<probably>
the key, and occasionally a different key whose fingerprint happens to match.

What sets it apart from L<Shared::Arena::Bloom> is that a fingerprint can be
taken out again. A set whose members expire - nonces inside a replay window,
sessions that end, jobs that finish - can be kept tidy key by key instead of
being rotated whole.

It holds no keys, so a long key costs what a short one does: about 2.2 bytes a
key at capacity. A lookup reads two words of memory, where a Bloom filter at the
same rate reads thirteen bits scattered across its whole array.

Get one from C<< $arena->cuckoo($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 The rate is fixed

A wrong "yes" happens when one of the eight fingerprints in a key's two buckets
matches its own. Fingerprints are sixteen bits, so the chance is about
C<8 * load / 65535>: B<0.011%> at capacity, and less as the filter empties.
C<fp_rate> in the stats is that number at the current load.

It is not a setting. A filter that wants a looser rate in less space, or a
tighter one in more, wants to be a Bloom filter.

Unlike a Bloom filter it does not degrade past its capacity. A full cuckoo
filter refuses the next key instead of saturating, so the rate stays where it
was and the refusal tells you.

=head2 What it will not do

B<It will not safely remove a key it was not given.> Removing a key that was
never added can find another key's matching fingerprint and take that instead,
and then the other key checks false - the one wrong answer this filter otherwise
never gives. Only remove what C<add> said it stored.

That rules out one tempting pattern. A "yes" from C<check> can be a coincidence,
so adding a key only when C<check> says "no" and removing it later can take out
somebody else's fingerprint. If keys will be removed, add every one of them, and
remove each as many times as it was added.

B<It stores copies.> Every C<add> stores the key again. A key added twice is in
the filter twice, takes two slots, and needs removing twice. One key can be
added at most eight times, because every copy of it lives in the same two
buckets of four.

B<It does not grow.> When there is no room, C<add> returns false and the key is
B<not> stored. Nothing already stored is disturbed by the attempt. Watch C<load>:
a filter is 90% full at its capacity and starts refusing at about 96%.

B<It cannot make a decision exactly once.> C<check> followed by C<add> is two
steps, and two processes can both pass the check before either one adds. For
anything that must happen once, use a lock.

=head2 Across processes

C<check> and C<remove> never wait for anybody. C<add> stores a key with a single
atomic write whenever either of its buckets has room, which is nearly always
until the filter is nearly full.

When both are full it makes room by moving other keys to their other buckets,
and only one process at a time does that. A key being moved is copied before it
is deleted, so a C<check> never misses it on the way, and a process killed in
the middle of a move leaves at worst one key stored twice.

A process killed while it holds the right to move keys does not keep it. The
next process that needs it checks that the holder has gone, takes over, and
counts it in C<recovered>.

=head2 Sizing

    my $f = $arena->cuckoo('seen', capacity => 1_000_000);

C<capacity> is how many keys you expect to hold at once. The table is sized so
that many fill it to 90%, which leaves room for the ones you did not expect: in
practice the first refusal comes at about 96% full. It costs about 2.2 bytes a
key of capacity, so a million keys take 2.2 MB.

=head1 METHODS

=head2 add

    my $stored = $f->add($key);

True when the key is stored, false when there was no room for it. A false
leaves the filter exactly as it was.

=head2 check

    if ($f->check($key)) { ... }

False is exact: this key is not in the filter. True is probable.

=head2 remove

    my $removed = $f->remove($key);

Takes out one copy of a key that was added, and returns true when one was
found. Only for keys C<add> stored; see L</What it will not do>.

=head2 reset

    $f->reset;

Forgets everything. Adds and removes running at the same moment may land on
either side of it, so C<count> can end up describing the other side.

=head2 count

    my $n = $f->count;

Keys stored now, counting every copy.

=head2 slots

    my $most = $f->slots;

Fingerprints the table has room for. A filter starts refusing before it gets
there, at about 96%.

=head2 stats

    my %s = $f->stats;
    # capacity, slots, buckets, bytes, count, load, fp_rate,
    # kicks, moves, full, recovered

C<load> is C<count / slots> and is the number to watch. C<fp_rate> is the chance
of a wrong "yes" at that load. C<kicks> counts adds that had to move keys to
make room, C<moves> the keys moved, and C<full> the adds refused. C<recovered>
counts the times a process took over from one that died moving keys, and is
zero unless something was killed.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Bloom>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
