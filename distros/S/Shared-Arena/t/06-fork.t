#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# WHAT SURVIVES A FORK, AND WHAT EACH PROCESS GETS ITS OWN OF.
#
# An arena is made before the fork and inherited, which is the whole ordinary
# use of this dist. Everything below is a promise the documentation makes about
# what that inheritance means, asserted rather than assumed:
#
#   * the mapping is shared, so a child's writes are the parent's reads
#   * a ring and a cursor made before the fork keep working in both
#   * a cursor is COPIED, not shared: both sides see every record and neither
#     consumes anything from the other
#   * each process registers as a peer of its own, so a hole either of them
#     leaves can be attributed to the process that actually left it
#   * a carve made in a child is visible to the parent
#
# Every child leaves with POSIX::_exit, never exit: a forked child that unwinds
# runs the parent's END blocks and its test plan a second time, and the harness
# then sees two plans and a pass count nobody can explain.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

require POSIX;

my $parent = $$;

# ---- the mapping is shared ------------------------------------------------
{
    my $arena = Shared::Arena->create(size => 512 * 1024);
    $arena->region('scratch', size => 256);
    $arena->poke('scratch', 0, 'written by the parent');

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $seen = $arena->peek('scratch', 0, 21);
        $arena->poke('scratch', 64,
                     $seen eq 'written by the parent' ? 'child agrees' : 'child saw junk');
        POSIX::_exit(0);
    }
    waitpid $pid, 0;

    is($?, 0, 'the child exited cleanly');
    is($arena->peek('scratch', 64, 12), 'child agrees',
       'the child read what the parent wrote before the fork');
    is($arena->peek('scratch', 0, 21), 'written by the parent',
       'and the parent still sees its own bytes');
    is($arena->created, 1, 'the parent is still the creator');
}

# ---- a ring made before the fork works in both -----------------------------
{
    my $arena = Shared::Arena->create(size => 1024 * 1024);
    my $ring  = $arena->ring('shared', slots => 256, slot_size => 256);
    my $cursor = $ring->cursor;

    # Two records before the fork, so the child inherits a cursor with a
    # position that is already behind.
    $ring->publish('pre', 'one');
    $ring->publish('pre', 'two');

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # THE INHERITED CURSOR. It was copied at the fork, positioned where the
        # parent's was, so the child sees the two records published before it
        # existed - and the parent will see them too, because a copy consumes
        # nothing from the original.
        my @mine = $cursor->drain;
        my $ok = (@mine == 2 && $mine[0][1] eq 'one' && $mine[1][1] eq 'two');
        $ring->publish('child', $ok ? 'inherited-ok' : 'inherited-wrong');
        $ring->publish('child', 'from the child');
        POSIX::_exit(0);
    }
    waitpid $pid, 0;
    is($?, 0, 'the child exited cleanly');

    my @got = $cursor->drain;
    is(scalar @got, 4, 'the parent sees all four records');
    is_deeply([map { $_->[1] } @got],
              ['one', 'two', 'inherited-ok', 'from the child'],
              'including the two the child also drained, in order - a forked '
            . 'cursor is a copy, not a second reader of one position');

    my %s = $ring->stats;
    is($s{published}, 4, 'and the ring counted every publish from both');
}

# ---- a cursor made in the child is its own ---------------------------------
{
    my $arena = Shared::Arena->create(size => 1024 * 1024);
    my $ring  = $arena->ring('own', slots => 256, slot_size => 256);
    $arena->region('answer', size => 64);
    $arena->poke('answer', 0, '..');

    $ring->publish('pre', 'before the fork');

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # Made AFTER the fork, so it starts at now and does not replay.
        my $c = $ring->cursor;
        my @first = $c->drain;
        $ring->publish('mid', 'published by the child');
        my @second = $c->drain;
        $arena->poke('answer', 0,
                     (@first == 0 && @second == 1) ? 'ok' : 'no');
        POSIX::_exit(0);
    }
    waitpid $pid, 0;

    is($arena->peek('answer', 0, 2), 'ok',
       'a cursor made in the child starts at now, and sees what follows');
}

# ---- each process is its own peer ------------------------------------------
#
# The child must NOT inherit the parent's registration. A record a child leaves
# unfinished has to be attributable to the child, and a claim naming its parent
# would send a reader to ask whether the wrong process is alive.
{
    my $arena = Shared::Arena->create(size => 512 * 1024);
    my $ring  = $arena->ring('peers', slots => 64, slot_size => 128);

    $ring->publish('parent', 'x');       # registers the parent
    my %before = $arena->peers;
    is($before{live}, 1, 'one peer before the fork');

    my @pids;
    for (1 .. 3) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            $ring->publish('child', "from $$");
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    my %after = $arena->peers;
    is($after{used}, 4, 'each of the three children took a peer slot of its own');
    is($after{reaped}, 0, 'and none of them was mistaken for a crash, because '
                        . 'each finished the record it started');
}

# ---- a carve in a child is visible to the parent ---------------------------
{
    my $arena = Shared::Arena->create(size => 512 * 1024);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my ($off) = $arena->region('made-by-the-child', size => 128);
        $arena->poke('made-by-the-child', 0, 'hello from below');
        POSIX::_exit($off ? 0 : 1);
    }
    waitpid $pid, 0;
    is($?, 0, 'the child carved a region');

    my ($off, $len) = $arena->region('made-by-the-child');
    ok($off, 'and the parent finds it by name, having never carved it');
    is($len, 128, 'at the size the child asked for');
    is($arena->peek('made-by-the-child', 0, 16), 'hello from below',
       'with the bytes the child wrote');
    is_deeply([$arena->regions], ['made-by-the-child'],
              'and it is the only region, so the registry was not written twice');
}

# ---- nothing here ran in a child ------------------------------------------
is($$, $parent, 'every assertion above ran in the parent process');

done_testing;
