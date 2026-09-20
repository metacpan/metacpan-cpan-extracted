#!perl
use 5.010;
use strict;
use warnings;
use Config;
use Test::More;
use Time::HiRes ();
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
#
# AND A CHECK THAT MUST LAND BEFORE THE DEADLINE IS ONLY A CHECK WHEN IT DID.
# A smoker running a dozen builds can park this process for longer than any
# ttl worth waiting out, and the FreeBSD box did exactly that between a store
# with a 40ms ttl and the `exists` three lines later, which then read as
# "expired early". So every live check runs inside a measured window: `live`
# stores, runs the checks, and accepts their answers only when the whole of it
# fitted inside the ttl. A window that overran says nothing about the map and
# is run again with a fresh store, a few times, before it is called a failure.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

sub live {
    my ($ttl_ms, $store, $check) = @_;
    my @r;
    for my $try (1 .. 5) {
        my $t0 = Time::HiRes::time();
        $store->();
        @r = $check->();
        my $took = (Time::HiRes::time() - $t0) * 1000;
        return @r if $took < $ttl_ms;
        note sprintf 'the live window took %.0fms against a %dms ttl (try %d): '
                   . 'it says nothing, so again', $took, $ttl_ms, $try;
    }
    diag "five live windows in a row overran the ttl; these checks ran late";
    return @r;
}

my $arena = Shared::Arena->create(size => 2 * 1024 * 1024);

# ---- a key with a deadline is present, then absent -------------------------

{
    my $m = $arena->map('ttl', slots => 64, slot_size => 128);
    $m->store('perm', 'forever');
    my ($val, $there) = live(40,
        sub { $m->store('temp', 'briefly', ttl_ms => 40) },
        sub { (($m->fetch('temp'))[0], $m->exists('temp') ? 1 : 0) });

    is(($m->fetch('perm'))[0], 'forever', 'a key with no ttl is stored');
    is($val, 'briefly', 'a key with a ttl is present before it');
    ok($there, 'exists agrees while it is live');

    select undef, undef, undef, 0.12;

    is(scalar($m->fetch('temp')), undef, 'and absent once the deadline passes');
    ok(!$m->exists('temp'), 'exists agrees it is gone');
    is(($m->fetch('perm'))[0], 'forever', 'the key with no ttl is untouched');
}

# ---- the ttl in seconds, matching the cache's surface ----------------------

{
    my $m = $arena->map('secs', slots => 64, slot_size => 128);
    my ($there) = live(30,
        sub { $m->store('k', 'v', ttl => 0.03) },      # 30ms
        sub { $m->exists('k') ? 1 : 0 });
    ok($there, 'ttl in seconds stores');
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
    my ($val) = live(200,
        sub {
            $m->store('k', 'first', ttl_ms => 30);
            select undef, undef, undef, 0.02;
            $m->store('k', 'second', ttl_ms => 200);   # renew, well before it lapses
            select undef, undef, undef, 0.05;          # past the FIRST deadline
        },
        sub { ($m->fetch('k'))[0] });
    is($val, 'second', 'a re-store renews the deadline');
}

# ---- an expired counter resets to zero, it does not accumulate -------------

{
    my $m = $arena->map('ctr', slots => 64, slot_size => 128);
    # incr does not take a ttl, so give the counter one via store, as 8 raw
    # bytes, then let it lapse. The bytes are built by hand: a perl without
    # 64-bit integers has no Q template (t/24 dodges it the same way).
    my $five = $Config{byteorder} =~ /^1234/
             ? pack('L', 5) . ("\0" x 4)
             : ("\0" x 4) . pack('L', 5);
    is($m->incr('hits'), 1, 'a fresh counter starts at one');
    is($m->incr('hits'), 2, '...and climbs');
    my ($read) = live(30,
        sub { $m->store('win', $five, ttl_ms => 30) },   # an 8-byte counter with a ttl
        sub { $m->counter('win') });
    is($read, 5, 'a stored 8-byte value reads as a counter');

    select undef, undef, undef, 0.09;

    # The lapsed counter is gone: incr must start it fresh at $by, not add to 5.
    is($m->incr('win', 3), 3, 'an expired counter resets to zero before adding');
}

# ---- a counter created with a deadline: a fixed window in one call ---------
#
# The deadline is set when the increment CREATES the counter or resets a lapsed
# one, and never renewed by a hit inside the window. The mutation this exists
# to catch is the sliding window - an incr that re-arms the deadline on every
# hit - which passes every "it expires" test and fails only the one that hits
# again INSIDE the window and then looks just after the ORIGINAL deadline.

{
    my $m = $arena->map('win', slots => 64, slot_size => 128);
    is($m->incr('w', 1, ttl_ms => 60), 1, 'a counter created with a ttl starts at one');
    is($m->incr('w', 1, ttl_ms => 60), 2, '...and climbs inside its window');
    is($m->incr('w', 5), 7, 'an incr with no ttl adds to the same live counter');

    my ($late) = live(60,
        sub {
            $m->incr('slide', 1, ttl_ms => 60);           # the window opens: t0
            select undef, undef, undef, 0.03;             # t0 + 30ms
            $m->incr('slide', 1, ttl_ms => 60);           # 2; MUST NOT re-arm
        },
        sub { $m->counter('slide') });
    is($late, 2, 'two hits inside the window count two');

    select undef, undef, undef, 0.05;                     # t0 + 80ms: past 60,
                                                          # before a slid 90
    is($m->incr('slide', 1, ttl_ms => 60), 1,
       'the counter lapsed at the FIRST deadline: the second hit did not '
     . 'slide the window');

    select undef, undef, undef, 0.09;
    is($m->incr('w', 3, ttl_ms => 60), 3,
       'after the deadline a hit starts the next window at $by');
    is($m->incr('w', 1), 4, '...with a fresh deadline: still live');
}

# ---- four workers on one window counter, across the deadline ---------------
#
# Every hit before the deadline vanishes at it, from every process, because the
# deadline is in the entry. Ten hits each from four children after it are
# exactly forty, and not forty plus whatever came before.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';
    my $m = $arena->map('pool-win', slots => 64, slot_size => 128);

    my $burst = sub {
        my ($n) = @_;
        my @kids;
        for (1 .. 4) {
            my $pid = fork;
            die "fork: $!" unless defined $pid;
            if (!$pid) { $m->incr('pw', 1, ttl_ms => 100) for 1 .. $n; exit 0 }
            push @kids, $pid;
        }
        waitpid $_, 0 for @kids;
    };

    my $before;
    for my $try (1 .. 5) {
        my $t0 = Time::HiRes::time();
        $m->delete('pw');
        $burst->(25);
        $before = $m->counter('pw');
        my $took = (Time::HiRes::time() - $t0) * 1000;
        last if $took < 100;
        note sprintf 'the pre-deadline burst took %.0fms against a 100ms ttl '
                   . '(try %d): again', $took, $try;
    }
    is($before, 100, 'four children put a hundred hits into the window');

    select undef, undef, undef, 0.15;
    $burst->(10);
    is($m->counter('pw'), 40,
       'after the deadline the count is exactly the forty hits that followed it');
}

# ---- shared across a pre-forked pool ---------------------------------------
#
# One worker sets a deadline; every worker sees the same lapse, because the
# deadline is a wall-clock timestamp in the shared entry, not per-process state.
#
# The child's first look has to land before the deadline, and a fork is where
# a loaded host is most likely to park the new process. So the child times its
# look against the parent's store, and a look that came after the deadline is
# reported as late (exit 3) rather than as a miss, and the parent runs the whole
# thing again.

SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $m = $arena->map('pool', slots => 64, slot_size => 128);
    my $rc;
    for my $try (1 .. 5) {
        my $t0 = Time::HiRes::time();
        $m->store('ban', 'yes', ttl_ms => 200);

        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            # The child sees it live now...
            my $live = $m->exists('ban') ? 1 : 0;
            my $late = (Time::HiRes::time() - $t0) * 1000 >= 200;
            select undef, undef, undef, 0.3;
            # ...and gone after, from a deadline the parent set.
            my $gone = $m->exists('ban') ? 0 : 1;
            exit(!$live && $late ? 3 : $live && $gone ? 0 : 1);
        }
        waitpid($pid, 0);
        $rc = $? >> 8;
        last unless $rc == 3;
        note "the child's first look came after the 200ms deadline (try $try): again";
    }
    is($rc, 0, 'a child sees the deadline the parent set, live then gone');

    # And by now the parent agrees.
    ok(!$m->exists('ban'), 'the parent sees it gone too');
}

done_testing;
