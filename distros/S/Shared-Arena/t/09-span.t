#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# RECORDS THAT DO NOT FIT IN A SLOT.
#
# This is the feature the dist exists for. A fixed-slot ring that refuses
# anything larger than a slot pushes the problem onto its callers, and what they
# do with it is truncate - which is the one failure a reader cannot detect,
# because a truncated record arrives with the right sequence, the right topic
# and a body that silently is not what was sent.
#
# A record here reserves several slots with ONE atomic and its parts are
# published in REVERSE, head last. That ordering is the whole trick: a reader
# holding a committed head is holding proof that every continuation behind it is
# committed too, so it gathers the tail by arithmetic and never waits twice.
# Publish the head first and a reader can hold a valid head whose body has not
# been written yet - a hole in the middle of a record rather than between two.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 4 * 1024 * 1024);

# ---- the round trip, at every size that matters ---------------------------
{
    my $ring = $arena->ring('big', slots => 512, slot_size => 128);
    my $cap  = $ring->max_record;

    # A slot carries less than 128 bytes once its header is in it; half the ring
    # is 256 slots; so the ceiling is far above one slot and far below the ring.
    cmp_ok($cap, '>', 128, 'the spanned maximum exceeds a single slot');
    cmp_ok($cap, '<', 512 * 128, 'and stops short of the whole ring');

    my $cursor = $ring->cursor;

    # THE CEILING IS ON TOPIC PLUS DATA, not on data alone - a record carries
    # both and they share the slots. So the largest payload for a one-byte
    # topic is one less than the maximum, and asking for the maximum itself is
    # asking for one byte more than the ring can hold.
    #
    # Sizes chosen to land either side of every boundary: inside one slot, at
    # the exact edge, just over it, several slots, and the ceiling.
    my @sizes = (0, 1, 50, 80, 81, 100, 200, 1000, 5000, $cap - 2, $cap - 1);
    for my $n (@sizes) {
        my $payload = join '', map { chr(65 + ($_ % 26)) } 1 .. $n;
        my $seq = $ring->publish('t', $payload);
        cmp_ok($seq, '>', 0, "a $n byte record is published");
        my @got = $cursor->drain;
        is(scalar @got, 1, "  and read back as exactly one record");
        is($got[0][0], 't', "  with its topic");
        is(length $got[0][1], $n, "  and its full length");
        is($got[0][1], $payload, "  byte for byte");
    }
}

# ---- refused, never truncated ---------------------------------------------
{
    my $ring = $arena->ring('limit', slots => 64, slot_size => 128);
    my $cap  = $ring->max_record;
    my %before = $ring->stats;

    is($ring->publish('t', 'x' x $cap), -1,
       'a payload of the full maximum is refused, because the topic shares it');
    is($ring->publish('t', 'x' x ($cap + 1)), -1,
       'and so is one byte more');
    is($ring->publish('t', 'x' x ($cap * 4)), -1,
       'and so is one far over it');

    my %after = $ring->stats;
    is($after{oversize}, $before{oversize} + 3, 'each counted as oversize');
    is($after{published}, $before{published}, 'and neither counted as published');

    # A topic that will not fit a single slot is refused rather than split: a
    # reader that had to gather a whole record before it could tell what the
    # record was about could not filter at all.
    is($ring->publish('t' x 200, 'small'), -1,
       'a topic larger than one slot is refused, not split across them');
}

# ---- the sequence advances by the span ------------------------------------
{
    my $ring = $arena->ring('seqs', slots => 256, slot_size => 128);
    my $cursor = $ring->cursor;

    my $s1 = $ring->publish('t', 'x' x 10);      # one slot
    my $s2 = $ring->publish('t', 'x' x 10);      # one slot
    is($s2, $s1 + 1, 'a single-slot record advances the sequence by one');

    my $s3 = $ring->publish('t', 'x' x 2000);    # several
    my $s4 = $ring->publish('t', 'x' x 10);
    cmp_ok($s4 - $s3, '>', 1,
           'a spanned record consumes as many sequences as it uses slots');

    my @got = $cursor->drain;
    is(scalar @got, 4, 'all four records come back');
    is_deeply([map { length $_->[1] } @got], [10, 10, 2000, 10],
              'with their lengths intact and no continuation delivered as a '
            . 'record of its own');
    is_deeply([map { $_->[2] } @got], [$s1, $s2, $s3, $s4],
              'each under the sequence its publisher was given');
}

# ---- a spanned record that gets lapped is ONE loss, not several ------------
#
# The interaction worth asserting rather than hoping for: when a big record is
# overwritten, its continuations are overwritten too. A reader must count the
# record once and must never deliver an orphaned continuation as though it were
# a record in its own right.
{
    my $ring = $arena->ring('lapme', slots => 32, slot_size => 128);
    my $cursor = $ring->cursor;

    # Fill the ring several times over with records that each take many slots.
    my $sent = 0;
    for (1 .. 40) {
        $ring->publish('t', 'y' x 800) > 0 and $sent++;
    }

    my @got = $cursor->drain;
    my %s   = $cursor->stats;

    is($s{delivered}, scalar @got, 'the cursor delivered what it handed back');
    for my $rec (@got) {
        is(length $rec->[1], 800, 'every delivered record is whole');
        is($rec->[0], 't', 'and carries its topic, so it was a head');
    }
    cmp_ok($s{lapped}, '>', 0, 'and it was lapped, as intended');
    is($s{abandoned}, 0, 'with nothing mistaken for a crash');
}

done_testing;
