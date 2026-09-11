#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# ONE RECORD TO ONE MEMBER OF THE POOL.
#
# A cursor is process-local, so every reader holding one sees every record.
# A group's cursor is in the mapping, so whoever wins the compare-and-swap owns
# that record and nobody else does. The difference between fanout and a queue is
# where the cursor lives.
#
# THE ASSERTION THAT MATTERS IS THE PARTITION: across the whole pool, every
# record delivered exactly once, none twice, none missing. A test that only
# counted the total would pass with a group that handed the same record to
# everybody, which is precisely the bug this exists to prevent.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'needs fork' if $^O eq 'MSWin32';

my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);

# ---- a group is a queue, a cursor is a broadcast ---------------------------

{
    my $ring = $arena->ring('one', slots => 256, slot_size => 256);
    my $g1 = $ring->group('workers');
    my $g2 = $ring->group('workers');     # the SAME group, twice

    $ring->publish('t', "job $_") for 1 .. 4;

    my @a = $g1->claim(max => 2);
    my @b = $g2->claim(max => 2);
    is(scalar @a, 2, 'the first handle claimed two');
    is(scalar @b, 2, 'the second claimed the other two');

    my %seen;
    $seen{$_->[2]}++ for @a, @b;
    is(scalar keys %seen, 4, 'four distinct records between them');
    is_deeply([grep { $seen{$_} > 1 } keys %seen], [],
              'and NOT ONE was handed out twice');

    is_deeply([sort map { $_->[1] } @a, @b],
              [sort map { "job $_" } 1 .. 4], 'the payloads are all there');

    # NOT `scalar $g1->claim`: an XSUB returning a list in scalar context
    # hands back its LAST element, or undef for an empty one, which is not a
    # count. The ring's own tests carry the same warning.
    my @none = $g1->claim;
    is(scalar @none, 0, 'an empty group claims nothing');
}

# ---- two groups do not consume from each other -----------------------------

{
    my $ring = $arena->ring('two', slots => 256, slot_size => 256);
    my $a = $ring->group('alpha');
    my $b = $ring->group('beta');

    $ring->publish('t', 'shared');

    my @ga = $a->claim;
    my @gb = $b->claim;
    is(scalar @ga, 1, 'group alpha got it');
    is(scalar @gb, 1, 'and group beta got it too');
    is($ga[0][2], $gb[0][2], 'the same record: groups have their own cursors');
}

# ---- fanout and queue on ONE ring, which is the shape a bus needs ----------
#
# A message is published once and the DELIVERY MODE is where the cursor lives.
# A subscriber keeps its own and sees everything; a group keeps one in the ring
# and its members divide the work. Both at the same time, on the same records.

{
    my $ring = $arena->ring('bus', slots => 256, slot_size => 256);
    my $sub  = $ring->cursor;
    my $m1   = $ring->group('pool');
    my $m2   = $ring->group('pool');

    $ring->publish('t', "m$_") for 1 .. 4;

    my @fan = $sub->drain;
    is(scalar @fan, 4, 'the fanout subscriber saw every record');

    my @a = $m1->claim(max => 2);
    my @b = $m2->claim(max => 2);
    my %q;
    $q{$_->[2]}++ for @a, @b;
    is(scalar keys %q, 4, 'the queue members divided the same four between them');
    is_deeply([grep { $q{$_} > 1 } keys %q], [],
              'without either mode taking anything from the other');
}

# ---- bound to a topic ------------------------------------------------------

{
    my $ring = $arena->ring('topics', slots => 256, slot_size => 256);
    my $jobs = $ring->group('j', topic => 'jobs');

    $ring->publish('jobs', 'one');
    $ring->publish('chat', 'noise');
    $ring->publish('jobs', 'two');

    my @got = $jobs->claim(max => 10);
    is(scalar @got, 2, 'a bound group claimed only its own topic');
    is_deeply([map { $_->[1] } @got], ['one', 'two'], '...and in order');
    is($jobs->topic, 'jobs', 'it reports what it is bound to');

    my %s = $jobs->stats;
    is($s{delivered}, 2, 'delivered counts what the group got');
    is($s{skipped}, 1, 'and skipped counts the record that was not its topic');
}

# ---- the shape is the group's, not the caller's ----------------------------

{
    my $ring = $arena->ring('shape', slots => 64, slot_size => 128);
    $ring->group('g', topic => 'a');
    my $again = eval { $ring->group('g', topic => 'b') };
    ok(!$again, 'a caller asking for a different topic is refused');
    like($@, qr/different type or size|already carved/,
         '...and told it is a shape disagreement');
}

# ---- THE POINT: a pre-forked pool splits the work --------------------------
#
# Every child reports which sequences it claimed. Across the pool they must be
# a PARTITION of what was published: each exactly once.

{
    my $KIDS = 4;
    my $JOBS = 400;
    my $ring = $arena->ring('pool', slots => 2048, slot_size => 256);
    my $g    = $ring->group('pool-workers');

    $ring->publish('work', "job $_") for 1 .. $JOBS;

    pipe(my $rd, my $wr) or die "pipe: $!";
    # A START BARRIER, and it is not decoration. Forked sequentially with no
    # work to do, the first child drains all four hundred records before the
    # second one exists - so the partition assertion still passes and the
    # SHARING assertion is testing nothing. The children block on this pipe
    # until every one of them is up.
    pipe(my $gate_r, my $gate_w) or die "pipe: $!";

    my @pid;
    for my $k (1 .. $KIDS) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd; close $gate_w;
            my $go; sysread($gate_r, $go, 1);
            my @mine;
            # Claim until the group is empty. A worker that finds nothing is
            # done: the others took the rest.
            while (1) {
                my @got = $g->claim(max => 4);
                last unless @got;
                push @mine, map { $_->[2] } @got;
                # Doing something with a record, so a worker is not always in
                # the claim loop. Without it one process can win every race.
                select undef, undef, undef, 0.001;
            }
            print {$wr} join(',', $k, @mine), "\n";
            close $wr;
            exit 0;
        }
        push @pid, $pid;
    }
    close $wr;
    close $gate_r;
    print {$gate_w} 'x' for 1 .. $KIDS;   # everybody starts together
    close $gate_w;

    my (%owner, %count);
    while (my $line = <$rd>) {
        chomp $line;
        my ($k, @seqs) = split /,/, $line;
        for my $s (@seqs) { $owner{$s} = $k; $count{$s}++ }
    }
    waitpid($_, 0) for @pid;

    is(scalar keys %owner, $JOBS, "all $JOBS records were claimed");
    is_deeply([grep { $count{$_} > 1 } keys %count], [],
              'NOT ONE record went to two workers');

    my %per;
    $per{$_}++ for values %owner;
    cmp_ok(scalar keys %per, '>', 1,
           'more than one worker got some of it, so it really was shared');

    my %s = $g->stats;
    is($s{delivered}, $JOBS, 'the group counted every delivery');
    is($s{lapped}, 0, 'and lost nothing');
}

# ---- a member leaving does not take the pool's position with it ------------

{
    my $ring = $arena->ring('leave', slots => 256, slot_size => 256);

    my $before;
    {
        # THE GROUP FIRST, THEN THE RECORDS. A group starts at the ring's
        # current position, because a worker joining a pool wants the work that
        # arrives after it rather than a replay of whatever the ring still
        # holds. Pass from_start => 1 to want the replay.
        my $g = $ring->group('leavers');
        $ring->publish('t', "n$_") for 1 .. 4;
        my @got = $g->claim(max => 2);
        is(scalar @got, 2, 'a member claimed two');
        $before = $g->position;
    }   # the handle goes out of scope here

    my $g2 = $ring->group('leavers');
    is($g2->position, $before, 'the shared position survived the member');
    my @rest = $g2->claim(max => 10);
    is(scalar @rest, 2, 'and the next member picks up where it left off');
}

# ---- at most once: a claimed record dies with its claimant -----------------
#
# This is a DATA LOSS PROPERTY, documented rather than fixed, so it is asserted
# rather than assumed: a worker that claims and dies takes that record with it.
# Anything needing at-least-once wants a durable queue, not a cursor.

{
    my $ring = $arena->ring('lossy', slots => 256, slot_size => 256);
    my $g    = $ring->group('lossy-g');
    $ring->publish('t', "r$_") for 1 .. 3;

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my @got = $g->claim(max => 1);       # claims r1, then dies with it
        exit(@got ? 0 : 9);
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'the child claimed one record');

    my @rest = $g->claim(max => 10);
    is(scalar @rest, 2, 'the survivors get the REST, not the claimed one');
    is_deeply([map { $_->[1] } @rest], ['r2', 'r3'],
              'the record the dead worker held is gone: at most once');
}

done_testing;
