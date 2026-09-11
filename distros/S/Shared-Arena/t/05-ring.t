#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# Publish and read: the record round-trip, the refusals, and the two things a
# cursor is for.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

# NOT `my $a`, and not `my $b` anywhere below either: they are sort's
# variables, and a lexical of either name turns every `sort { $a <=> $b }` in
# the same scope into a comparison against whatever the lexical holds - here an
# arena object, which sorts as its address.
my $top = Shared::Arena->create(size => 1024 * 1024);
my $r = $top->ring('events', slots => 64, slot_size => 256);
ok($r, 'carved and bound a ring');
isa_ok($r, 'Shared::Arena::Ring');
is($r->slots, 64, 'with the slot count asked for');

# The capacity is a runtime question. A consumer that compiles the answer in is
# a consumer that starts refusing records the day somebody reconfigures the
# ring, which is exactly how a live tail elsewhere in this workspace ended up
# truncating.
# This is the SPANNED maximum: a record may cross up to half the ring, so it is
# larger than one slot. A consumer that compiles either number in is one that
# starts refusing records the day somebody reconfigures the ring, which is
# exactly how a live tail elsewhere in this workspace ended up truncating.
my $max = $r->max_record;
cmp_ok($max, '>', 256, 'a record may span slots, so the maximum exceeds one');
cmp_ok($max, '<', 64 * 256, 'and stops at half the ring, so a record can '
                          . 'never overwrite its own head');

# What fits in a single slot, which is what the small-record cases below use.
my $one = 200;

# ---- the round trip -------------------------------------------------------
{
    my $c = $r->cursor;                      # from now
    my $seq = $r->publish('greet', 'hello');
    cmp_ok($seq, '>', 0, 'published, and the return value is its sequence');
    my @got = $c->drain;
    is(scalar @got, 1, 'the cursor saw one record');
    is($got[0][0], 'greet', 'the topic came back');
    is($got[0][1], 'hello', 'and the payload, byte for byte');
    is($got[0][2], $seq, 'under the sequence publish reported');

    is_deeply([$c->drain], [], 'and a second drain has nothing to say');
}

# ---- a cursor starts at NOW ------------------------------------------------
{
    $r->publish('before', 'x') for 1 .. 3;
    my $c = $r->cursor;
    is_deeply([$c->drain], [],
              'a fresh cursor does not replay what happened before it existed');
    $r->publish('after', 'y');
    # NOT `scalar $c->drain`: an XSUB returning a list in scalar context hands
    # back its last element, not a count, so that spelling compares an arrayref
    # against 1 and fails for a reason that has nothing to do with the ring.
    my @after = $c->drain;
    is(scalar @after, 1, 'but does see what happens after');
}

# ---- from_start replays what is still in the ring --------------------------
{
    # NOT `my $b`: it would shadow the sort block's $b below, and every
    # comparison would silently become a number against an arena object.
    my $arena = Shared::Arena->create(size => 256 * 1024);
    my $ring = $arena->ring('replay', slots => 8, slot_size => 128);
    $ring->publish('n', $_) for 1 .. 5;
    my $c = $ring->cursor(from_start => 1);
    my @got = $c->drain;
    is(scalar @got, 5, 'from_start replays everything still held');
    is_deeply([map { $_->[1] } @got], [1 .. 5], 'in order');
    my @seqs = map { $_->[2] } @got;
    is_deeply([@seqs], [sort { $a <=> $b } @seqs], 'with increasing sequences');
}

# ---- binary payloads, and an empty one -------------------------------------
{
    my $c = $r->cursor;
    my $bin = join '', map { chr } 0 .. 255;
    $bin = substr $bin, 0, $one;
    cmp_ok($r->publish('bin', $bin), '>', 0,
           'published bytes with NULs and high bits');
    cmp_ok($r->publish('', ''), '>', 0,
           'and an empty topic with an empty payload');
    my @got = $c->drain;
    is(scalar @got, 2, 'both came back');
    is($got[0][1], $bin, 'the binary payload is unchanged');
    is(length $got[0][1], length $bin, 'including its length');
    is_deeply([@{$got[1]}[0,1]], ['', ''],
              'and the empty one is empty, not absent');
}

# ---- what is refused -------------------------------------------------------
{
    my %before = $r->stats;
    is($r->publish('t', 'x' x ($max + 1)), -1,
       'a record larger than the ring will hold is refused');
    my %after = $r->stats;
    is($after{oversize}, $before{oversize} + 1, 'and counted as oversize');
    is($after{published}, $before{published},
       'and not counted as published, because it was not');

    # Exactly at the limit is the interesting case either side of which a
    # fencepost lives.
    my $c = $r->cursor;
    cmp_ok($r->publish('t', 'x' x ($max - 1)), '>', 0,
           'a record that exactly fills the ring\'s limit is published');
    my @got = $c->drain;
    is(length $got[0][1], $max - 1, 'and comes back whole');
}

# ---- two cursors do not consume each other's records -----------------------
#
# The property that makes a cursor an object rather than a static. Two readers
# sharing one position means whichever asks first gets everything.
{
    my $c1 = $r->cursor;
    my $c2 = $r->cursor;
    $r->publish('fan', $_) for 1 .. 3;
    my @first  = $c1->drain;
    my @second = $c2->drain;
    is(scalar @first, 3, 'the first cursor saw all three');
    is(scalar @second, 3, 'and so did the second');
    is_deeply([map { $_->[1] } @first], [map { $_->[1] } @second],
              'the same three, in the same order');
}

done_testing;
