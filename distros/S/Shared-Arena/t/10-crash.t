#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A PUBLISHER THAT DIES MID-RECORD, AND THE READER THAT GETS PAST IT.
#
# This is the case the whole peer table exists for. A publisher takes a
# sequence, starts writing, and is killed. Every reader that reaches that
# sequence now faces a hole it can neither deliver nor safely skip: skipping a
# record that is merely late throws away live data, and waiting for one that
# will never arrive stalls the reader for ever.
#
# The answer is not a timeout. A reader asks WHO claimed the slot, and whether
# that process is gone - kill(0) where only ESRCH means gone, plus a heartbeat
# that has stood still - and when both say yes it writes a tombstone into the
# hole so every reader after it passes by READING rather than by waiting.
#
# DETERMINISM. The window between reserving a sequence and committing it is a
# few instructions wide. A test that tries to kill a process inside it by luck
# flakes on a loaded smoker, gets marked TODO, and stops meaning anything - so
# the region carries a `stall_us` field that widens the window on purpose, and
# the kill lands inside it every time.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

require POSIX;

# ---- a publisher killed mid-record ----------------------------------------
{
    my $arena = Shared::Arena->create(size => 512 * 1024);
    my $ring  = $arena->ring('crash', slots => 32, slot_size => 128);
    $arena->region('flag', size => 16);
    $arena->poke('flag', 0, '....');

    my $cursor = $ring->cursor;

    # Two records that land cleanly, so the hole is in the middle of a stream
    # rather than at its start - a reader that only ever recovers at position
    # one is not recovering, it is restarting.
    $ring->publish('ok', 'first');
    $ring->publish('ok', 'second');

    # Half a second inside the window, and a reader that gives up waiting after
    # a tenth of one.
    $arena->_test_timing(stall_us => 500_000, reap_grace_us => 100_000);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $arena->poke('flag', 0, 'GO!!');
        $ring->publish('doomed', 'never committed');   # stalls inside publish
        POSIX::_exit(0);                               # never reached
    }

    # Wait until the child is actually inside publish, then kill it there.
    my $spins = 0;
    while ($arena->peek('flag', 0, 4) ne 'GO!!') {
        die "child never started\n" if ++$spins > 50_000_000;
    }
    select undef, undef, undef, 0.05;    # it is now inside the stall
    kill 'KILL', $pid;
    waitpid $pid, 0;
    isnt($? & 127, 0, 'the publisher was killed mid-record');

    # Nothing else may stall: turn the hook off before the parent publishes.
    $arena->_test_timing(stall_us => 0);

    # And life goes on behind the hole.
    $ring->publish('ok', 'third');

    my @got = $cursor->drain;
    my %s   = $cursor->stats;

    is(scalar @got, 3, 'the reader got past the hole and delivered every '
                     . 'record either side of it');
    is_deeply([map { $_->[1] } @got], ['first', 'second', 'third'],
              'in order, with the dead publisher\'s record simply absent');

    is($s{abandoned}, 1, 'and counted exactly one abandoned record');
    is($s{lapped}, 0, 'which is NOT counted as lapped - a crash and a slow '
                    . 'reader are different diagnoses');
    is($s{unattributed}, 0, 'and it was attributed: no hole went unexplained');

    my %p = $arena->peers;
    is($p{reaped}, 1, 'the dead peer was reaped exactly once');
}

# ---- a publisher that is merely SLOW must not be reaped --------------------
#
# The mutation this test exists to catch. Make the reader impatient and the
# publisher slow, and a design that reaps on a timeout will declare a live
# process dead and throw away a record that arrives moments later.
{
    my $arena = Shared::Arena->create(size => 512 * 1024);
    my $ring  = $arena->ring('slow', slots => 32, slot_size => 128);
    $arena->region('flag', size => 16);
    $arena->poke('flag', 0, '....');

    my $cursor = $ring->cursor;

    # A full second in the window against a reader that waits a fortieth of
    # one. The margin is deliberately huge: the point is not to be fast, it is
    # that no amount of scheduler bad luck should let the reader run out of
    # patience before the publisher is done. A design that reaps on elapsed
    # time alone fails this every time; one that asks whether the process is
    # alive passes it every time.
    $arena->_test_timing(stall_us => 1_000_000, reap_grace_us => 25_000);

    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $arena->poke('flag', 0, 'GO!!');
        $ring->publish('slow', 'late but real');
        POSIX::_exit(0);
    }

    # WAIT FOR THE HOLE TO EXIST before drawing any conclusion from a drain.
    #
    # The flag says the child has entered publish, not that it has reserved a
    # sequence yet. Draining before the reservation finds nothing to wait on at
    # all - and a run like that cannot distinguish a design that asks whether
    # the publisher is alive from one that reaps on a stopwatch, because
    # neither is ever asked the question. The ring's own sequence is what says
    # the reservation has happened.
    my $spins = 0;
    while (($ring->stats)[5] < 2) {          # seq advanced past its initial 1
        die "child never reserved a sequence\n" if ++$spins > 50_000_000;
    }

    # Now drain repeatedly while the child is still inside its stall. Every one
    # of these finds the hole, exhausts its grace, asks whether the publisher is
    # alive, and must answer yes.
    my @early;
    push @early, $cursor->drain for 1 .. 8;

    is(scalar @early, 0, 'a reader waiting on a live-but-slow publisher '
                       . 'delivers nothing yet');
    my %mid = $cursor->stats;
    is($mid{abandoned}, 0,
       'and does NOT reap it: kill(0) says the process is still there');

    waitpid $pid, 0;
    is($? >> 8, 0, 'the slow publisher finished normally');

    my @got = $cursor->drain;
    is(scalar @got, 1, 'and its record arrives after all');
    is($got[0][1], 'late but real',
       'whole, having never been declared abandoned');

    my %s = $cursor->stats;
    is($s{abandoned}, 0, 'with nothing counted as abandoned');
    my %p = $arena->peers;
    is($p{reaped}, 0, 'and no peer reaped');
}

done_testing;
