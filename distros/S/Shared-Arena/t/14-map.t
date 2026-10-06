#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A MAP SEVERAL PROCESSES SHARE.
#
# Fixed capacity, open addressing, lock-free reads. The interesting parts are
# not store and fetch, they are the edges: what a delete leaves behind, what a
# full table does, and whether a counter really is atomic across processes.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 2 * 1024 * 1024);

# ---- the round trip --------------------------------------------------------
{
    my $map = $arena->map('basic', slots => 64, slot_size => 256);
    isa_ok($map, 'Shared::Arena::Map');
    is($map->capacity, 64, 'the capacity asked for');
    cmp_ok($map->max_pair, '>', 0, 'and room in a slot for a key and a value');

    is($map->store('greeting', 'hello'), 1, 'stored');
    is(($map->fetch('greeting'))[0], 'hello', 'and fetched back');
    is($map->exists('greeting'), 1, 'exists says so');

    is_deeply([$map->fetch('absent')], [],
              'an absent key is an EMPTY LIST, not undef - undef is a value a '
            . 'caller may legitimately store');
    is($map->exists('absent'), 0, 'and exists says no');

    # Overwrite.
    is($map->store('greeting', 'goodbye'), 1, 'stored over an existing key');
    is(($map->fetch('greeting'))[0], 'goodbye', 'and the new value is there');
    my %s = $map->stats;
    is($s{used}, 1, 'with one entry, not two');
}

# ---- values that are not text ---------------------------------------------
{
    my $map = $arena->map('bytes', slots => 32, slot_size => 256);
    my $bin = join '', map { chr } 0 .. 255;
    $bin = substr $bin, 0, 100;

    is($map->store('bin', $bin), 1, 'stored bytes with NULs and high bits');
    is(($map->fetch('bin'))[0], $bin, 'and they come back unchanged');
    is(length(($map->fetch('bin'))[0]), 100, 'including their length');

    is($map->store('empty', ''), 1, 'an empty value is storable');
    is(($map->fetch('empty'))[0], '', 'and comes back empty, not absent');
    is($map->exists('empty'), 1, 'and exists, which is the other question');

    is($map->store('', 'x'), -1, 'an empty key is refused');
    is($map->store('k', 'x' x $map->max_pair), -1,
       'a pair too big for a slot is refused');
}

# ---- delete leaves a tombstone, and a probe must pass over it ---------------
#
# The subtle one. Deleting must not leave an EMPTY slot, because an empty slot
# stops a probe, and a probe that stops early cannot find a key that was placed
# past the one just deleted. Filling a table then deleting from the middle of a
# probe chain is what exercises that.
{
    my $map = $arena->map('tomb', slots => 16, slot_size => 128);

    $map->store("k$_", "v$_") for 1 .. 10;
    my %s = $map->stats;
    is($s{used}, 10, 'ten entries');

    # 1 deleted, 0 was-not-there, and undef refused - three answers, because a
    # caller that deletes in order to RELY on the key being gone has to tell a
    # refusal from an absence. Both falsehoods, so a speculative delete can go
    # on ignoring the answer; `defined` is what separates them.
    is($map->delete('k5'), 1, 'deleted one from the middle');
    my $again = $map->delete('k5');
    ok(defined $again, 'a second delete answered rather than being refused');
    is($again, 0, 'and deleting it again says nothing was there');
    is_deeply([$map->fetch('k5')], [], 'it is gone');

    # Every other key must still be findable. If a delete had left a hole in a
    # probe chain, some of these would now be unreachable.
    for my $i (1 .. 10) {
        next if $i == 5;
        is(($map->fetch("k$i"))[0], "v$i", "k$i is still reachable past the hole");
    }

    %s = $map->stats;
    is($s{used}, 9, 'nine entries left');
    is($s{tombstones}, 1, 'and one tombstone, which is why the probe still works');

    # Reusing the tombstone rather than growing the table.
    is($map->store('k5', 'again'), 1, 'the key can be stored again');
    %s = $map->stats;
    is($s{used}, 10, 'back to ten entries');
    is($s{tombstones}, 0, 'having reused the tombstone rather than a fresh slot');
}

# ---- a full table refuses rather than growing ------------------------------
{
    my $map = $arena->map('full', slots => 8, slot_size => 128);

    my $stored = 0;
    $stored += ($map->store("key$_", $_) == 1) for 1 .. 8;
    is($stored, 8, 'a table of eight holds eight');

    is($map->store('one-too-many', 'x'), 0, 'and refuses the ninth');
    my %s = $map->stats;
    is($s{used}, 8, 'with the table still holding eight');
    is($s{full}, 1, 'and the refusal counted');

    # An overwrite of an existing key must still work when the table is full:
    # it needs no new slot.
    is($map->store('key1', 'replaced'), 1,
       'but an existing key can still be overwritten, needing no new slot');
    is(($map->fetch('key1'))[0], 'replaced', 'and the new value is there');
}

# ---- counters --------------------------------------------------------------
{
    my $map = $arena->map('counts', slots => 32, slot_size => 128);

    is($map->incr('hits'), 1, 'incr creates a counter at one');
    is($map->incr('hits'), 2, 'and counts up');
    is($map->incr('hits', 10), 12, 'by any amount');
    is($map->counter('hits'), 12, 'and the value can be read without changing it');

    is($map->incr('hits', -2), 10, 'a negative step counts down');

    is($map->counter('never-touched'), undef,
       'a key that was never counted has no counter value');
    $map->store('a-string', 'not a number');
    is($map->incr('a-string'), undef,
       'and a key holding something else is refused rather than reinterpreted');
    is(($map->fetch('a-string'))[0], 'not a number',
       'with its value left alone');
}

# ---- keys ------------------------------------------------------------------
{
    my $map = $arena->map('names', slots => 32, slot_size => 128);
    $map->store($_, 'x') for qw(alpha beta gamma);
    is_deeply([sort $map->keys], [qw(alpha beta gamma)], 'keys lists them');
    $map->delete('beta');
    is_deeply([sort $map->keys], [qw(alpha gamma)], 'and a deleted one is gone');
}

# ---- across a fork ---------------------------------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 5 if $^O eq 'MSWin32';
    require POSIX;

    my $map = $arena->map('forked', slots => 256, slot_size => 128);
    $map->store('from-parent', 'before the fork');

    my $KIDS = 4;
    my $EACH = 250;
    my @pids;
    for my $kid (1 .. $KIDS) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $seen = ($map->fetch('from-parent'))[0] // '';
            $map->store("child$kid", $seen);
            # Every child counts the same key. If the counter were not atomic
            # across processes, the total would come out short.
            #
            # AND AN INCREMENT THAT WAS REFUSED IS NOT ONE THAT LANDED. incr
            # answers undef when it could not write, and a test that throws
            # that away cannot tell "the counter lost an update" from "the
            # counter was never asked". An Alpine smoker read 999 of these
            # thousand: four children on one stripe, a holder descheduled, and
            # the waiter abandoning its write after burning its spin budget.
            #
            # SO IT RETRIES, rather than asserting that no refusal happened.
            # "Nothing was refused" is a claim about the scheduler, and this
            # file has no business making one: a box running a dozen builds can
            # park the holder for longer than any wait worth having, and a test
            # that calls that a bug reports the smoker rather than the map.
            # Retrying makes the total exact on any box, and a refusal that
            # outlasts the retries still shows up - in the exit status, and in
            # a total that cannot then add up.
            my $retried = 0;
            for (1 .. $EACH) {
                my $try = 0;
                $retried++, $try++ while !defined($map->incr('total'))
                                     && $try < 1000;
            }
            POSIX::_exit($retried > 254 ? 254 : $retried);
        }
        push @pids, $pid;
    }
    my $retried = 0;
    for (@pids) { waitpid $_, 0; $retried += ($? >> 8) }

    is(($map->fetch("child$_"))[0], 'before the fork',
       "child $_ read what the parent stored") for 1 .. $KIDS;

    note "increments that had to be retried: $retried" if $retried;

    my %s = $map->stats;
    is($s{full}, 0, 'nothing was refused as "full": the table had room');

    is($map->counter('total'), $KIDS * $EACH,
       "every one of the @{[ $KIDS * $EACH ]} increments from $KIDS processes "
     . 'landed - a counter is one atomic, not a read and a write');
}

done_testing;
