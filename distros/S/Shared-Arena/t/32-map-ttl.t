#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A PER-KEY DEADLINE ON A MAP.
#
# The case a plain map handles wrong: a denylist, a nonce, a dedup window.
# Without a deadline every caller writes its own `> time` check and its own
# delete, and the failure is always the same one - forgetting the check, which
# turns every ban permanent. This puts the deadline in the entry.
#
# TIMING IS A RANGE, NEVER A POINT. A sleep is a lower bound on elapsed time
# and nothing more, so the tests below say "before the deadline it is present,
# after it is gone", with the sleep comfortably past the ttl.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 2 * 1024 * 1024);

# ---- a key with a deadline is present, then absent -------------------------

{
    my $m = $arena->map('ttl', slots => 64, slot_size => 128);
    $m->store('perm', 'forever');
    $m->store('temp', 'briefly', ttl_ms => 40);

    is(($m->fetch('perm'))[0], 'forever', 'a key with no ttl is stored');
    is(($m->fetch('temp'))[0], 'briefly', 'a key with a ttl is present before it');
    ok($m->exists('temp'), 'exists agrees while it is live');

    select undef, undef, undef, 0.12;

    is(scalar($m->fetch('temp')), undef, 'and absent once the deadline passes');
    ok(!$m->exists('temp'), 'exists agrees it is gone');
    is(($m->fetch('perm'))[0], 'forever', 'the key with no ttl is untouched');
}

# ---- the ttl in seconds, matching the cache's surface ----------------------

{
    my $m = $arena->map('secs', slots => 64, slot_size => 128);
    $m->store('k', 'v', ttl => 0.03);       # 30ms
    ok($m->exists('k'), 'ttl in seconds stores');
    select undef, undef, undef, 0.10;
    ok(!$m->exists('k'), '...and lapses');
}

# ---- lazy collection: the fetch that finds it dead reclaims the slot -------

{
    my $m = $arena->map('lazy', slots => 64, slot_size => 128);
    $m->store("k$_", 'x', ttl_ms => 30) for 1 .. 10;
    my %before = $m->stats;
    is($before{used}, 10, 'ten live keys');
    is($before{expired}, 0, 'none collected yet');

    select undef, undef, undef, 0.09;

    # Reading each expired key is what collects it.
    is(scalar($m->fetch("k$_")), undef, "k$_ reads as absent") for 1 .. 10;

    my %after = $m->stats;
    is($after{expired}, 10, 'each fetch collected the lapsed entry it landed on');
    is($after{used}, 0, 'and used dropped to zero without a sweeper');
    cmp_ok($after{tombstones}, '>=', 10, 'the collected slots became tombstones');

    # And a tombstone is reusable: the table did not fill with corpses.
    is($m->store('fresh', 'y'), 1, 'a new key reuses a collected slot');
}

# ---- store refreshes the deadline ------------------------------------------

{
    my $m = $arena->map('refresh', slots => 64, slot_size => 128);
    $m->store('k', 'first', ttl_ms => 30);
    select undef, undef, undef, 0.02;
    $m->store('k', 'second', ttl_ms => 200);   # renew, well before it lapses
    select undef, undef, undef, 0.05;          # past the FIRST deadline
    is(($m->fetch('k'))[0], 'second', 'a re-store renews the deadline');
}

# ---- an expired counter resets to zero, it does not accumulate -------------

{
    my $m = $arena->map('ctr', slots => 64, slot_size => 128);
    # incr does not take a ttl, so give the counter one via store, as 8 raw
    # bytes, then let it lapse.
    is($m->incr('hits'), 1, 'a fresh counter starts at one');
    is($m->incr('hits'), 2, '...and climbs');
    $m->store('win', pack('Q', 5), ttl_ms => 30);   # an 8-byte counter with a ttl
    is($m->counter('win'), 5, 'a stored 8-byte value reads as a counter');

    select undef, undef, undef, 0.09;

    # The lapsed counter is gone: incr must start it fresh at $by, not add to 5.
    is($m->incr('win', 3), 3, 'an expired counter resets to zero before adding');
}

# ---- shared across a pre-forked pool ---------------------------------------
#
# One worker sets a deadline; every worker sees the same lapse, because the
# deadline is a wall-clock timestamp in the shared entry, not per-process state.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $m = $arena->map('pool', slots => 64, slot_size => 128);
    $m->store('ban', 'yes', ttl_ms => 60);

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # The child sees it live now...
        my $live = $m->exists('ban') ? 1 : 0;
        select undef, undef, undef, 0.12;
        # ...and gone after, from a deadline the parent set.
        my $gone = $m->exists('ban') ? 0 : 1;
        exit($live && $gone ? 0 : 1);
    }
    waitpid($pid, 0);
    is($? >> 8, 0, 'a child sees the deadline the parent set, live then gone');

    # And by now the parent agrees.
    ok(!$m->exists('ban'), 'the parent sees it gone too');
}

done_testing;
