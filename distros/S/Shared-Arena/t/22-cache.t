#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# A CACHE, WHICH IS A MAP THAT THROWS SOMETHING AWAY INSTEAD OF SAYING NO.
#
# The behaviour that makes it a cache rather than a table is all in what happens
# when it is full, so that is what most of this is about:
#
#   * a set NEVER fails for want of room; something else leaves instead
#   * what leaves is chosen, not arbitrary: an expired entry before a live one,
#     and among live ones, one that has not been read recently
#   * an entry past its deadline is a miss, not stale data
#   * the hit rate is a number you can read, because a cache you cannot measure
#     is a cache you cannot size

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);

# ---- the round trip --------------------------------------------------------
{
    my $c = $arena->cache('basic', capacity => 64, ways => 8, entry_size => 256);
    isa_ok($c, 'Shared::Arena::Cache');
    is($c->capacity, 64, 'the capacity asked for');
    cmp_ok($c->max_pair, '>', 0, 'and room in an entry');

    is($c->set('k', 'v'), 1, 'stored');
    is(($c->get('k'))[0], 'v', 'and fetched back');
    is_deeply([$c->get('nope')], [], 'a key never set is an empty list');

    is($c->set('k', 'w'), 1, 'overwritten');
    is(($c->get('k'))[0], 'w', 'with the new value');

    is($c->remove('k'), 1, 'removed');
    is_deeply([$c->get('k')], [], 'and gone');
    is($c->remove('k'), 0, 'removing it again says nothing was there');

    my %s = $c->stats;
    is($s{hits}, 2, 'two hits were counted');
    is($s{misses}, 2, 'and two misses');
    cmp_ok($s{hit_rate}, '>', 0.49, 'so the hit rate is a half');
    cmp_ok($s{hit_rate}, '<', 0.51, 'and is reported as one');
}

# ---- IT NEVER REFUSES ------------------------------------------------------
#
# The difference from the map, stated as a test. Ten times the capacity goes in
# and every single set succeeds.
{
    my $c = $arena->cache('evicting', capacity => 64, ways => 8, entry_size => 128);

    my $refused = 0;
    for my $i (1 .. 640) {
        $refused++ unless $c->set("key$i", "value$i") == 1;
    }
    is($refused, 0, '640 sets into a cache of 64 and not one was refused - a '
                  . 'cache that says no is a map');

    my %s = $c->stats;
    cmp_ok($s{evictions}, '>', 0, 'so things were evicted instead');
    cmp_ok($s{live}, '<=', 64, 'and it never holds more than its capacity');

    # The most recent writes should mostly still be there; the oldest should
    # mostly be gone. "Mostly" because which bucket a key lands in decides who
    # it competes with, and that is the trade a set-associative cache makes.
    my $recent = grep { scalar $c->get("key$_") } 630 .. 640;
    my $old    = grep { scalar $c->get("key$_") } 1 .. 11;
    cmp_ok($recent, '>', $old,
           'the recent keys survived better than the ancient ones');
}

# ---- a read protects an entry from the next sweep --------------------------
#
# The point of CLOCK. An entry that is being read keeps its place; one that is
# not is what leaves. Read one key on every pass and it should outlive keys
# written after it.
{
    my $c = $arena->cache('clock', capacity => 16, ways => 16, entry_size => 128);

    # One bucket only (16 ways, 16 capacity), so everything competes directly
    # and the policy is the only thing deciding.
    $c->set('favourite', 'keep me');

    for my $i (1 .. 200) {
        $c->get('favourite');            # read it every time round
        $c->set("filler$i", 'x');
    }

    ok(scalar $c->get('favourite'),
       'a key read on every pass survived 200 competing writes - which is '
     . 'what the reference bit is for');
}

# ---- expiry ----------------------------------------------------------------
{
    my $c = $arena->cache('ttl', capacity => 32, ways => 8, entry_size => 128);

    is($c->set('quick', 'gone soon', ttl_ms => 60), 1, 'stored with a deadline');
    is(($c->get('quick'))[0], 'gone soon', 'and readable straight away');

    select undef, undef, undef, 0.15;    # past it

    is_deeply([$c->get('quick')], [],
              'past its deadline it is a MISS, not stale data');
    my %s = $c->stats;
    cmp_ok($s{expired}, '>', 0, 'and the expiry was counted');

    # No deadline means no expiry.
    $c->set('forever', 'still here');
    select undef, undef, undef, 0.15;
    is(($c->get('forever'))[0], 'still here',
       'an entry with no deadline does not expire');

    # A ttl in seconds, which is what a caller thinks in.
    $c->set('seconds', 'v', ttl => 10);
    is(($c->get('seconds'))[0], 'v', 'a ttl given in seconds works too');
}

# ---- an expired entry is taken before a live one ---------------------------
{
    my $c = $arena->cache('prefer', capacity => 8, ways => 8, entry_size => 128);

    # Fill the single bucket: four that die immediately, four that do not.
    $c->set("dead$_", 'x', ttl_ms => 20) for 1 .. 4;
    $c->set("live$_", 'x') for 1 .. 4;
    select undef, undef, undef, 0.1;     # the first four are now past it

    my %before = $c->stats;
    $c->set('newcomer', 'x');
    my %after = $c->stats;

    is($after{evictions}, $before{evictions},
       'a newcomer took an expired entry rather than evicting a live one');

    # And all four live ones are still there.
    my $survivors = grep { scalar $c->get("live$_") } 1 .. 4;
    is($survivors, 4, 'every unexpired entry survived');
    ok(scalar $c->get('newcomer'), 'and the newcomer is in');
}

# ---- what is refused, which is only what cannot fit ------------------------
{
    my $c = $arena->cache('limits', capacity => 8, ways => 8, entry_size => 128);
    my $max = $c->max_pair;

    is($c->set('k', 'x' x $max), -1, 'a pair too big for an entry is refused');
    is($c->set('', 'v'), -1, 'and so is an empty key');
    is($c->set('k', 'x' x ($max - 1)), 1, 'one that exactly fits is stored');
    is(length(($c->get('k'))[0]), $max - 1, 'and comes back whole');
}

# ---- clear -----------------------------------------------------------------
{
    my $c = $arena->cache('wipe', capacity => 32, ways => 8, entry_size => 128);
    $c->set("k$_", 'v') for 1 .. 20;
    my %before = $c->stats;
    cmp_ok($before{live}, '>', 0, 'it holds entries');

    $c->clear;
    my %s = $c->stats;
    is($s{live}, 0, 'clear empties it');
    is_deeply([$c->get('k1')], [], 'and the keys are gone');

    $c->set('after', 'v');
    ok(scalar $c->get('after'), 'and it works afterwards');
}

# ---- across a fork ---------------------------------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';
    require POSIX;

    my $c = $arena->cache('forked', capacity => 512, ways => 8, entry_size => 256);
    $c->set('from-parent', 'before the fork');

    my $KIDS = 4;
    my @pids;

    # The children report through a PIPE, not through the cache.
    #
    # They did report through the cache, and it failed 9 runs in 12 on a
    # two-processor container while passing 12 in 12 here. The reason is the
    # test arguing with itself: four children write 2000 churn keys into a
    # 512-entry cache precisely to force eviction, and then it asserted that an
    # entry written before that churn had survived it. Whether any had was a
    # coin toss decided by scheduling.
    #
    # What the assertion is actually about is whether a child can READ what the
    # parent stored, and a pipe answers that exactly. Eviction is asserted
    # below, where it belongs.
    pipe(my $rd, my $wr) or die "pipe: $!";
    for my $kid (1 .. $KIDS) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd;
            my $seen = ($c->get('from-parent'))[0] // '';
            print {$wr} (($seen eq 'before the fork') ? "ok\n" : "NOT ok\n");
            close $wr;
            # Enough churn from every process at once to make the buckets
            # contend, since eviction is the part that takes a lock.
            $c->set("churn$kid-$_", 'x' x 50) for 1 .. 500;
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    close $wr;
    my @said = <$rd>;
    waitpid $_, 0 for @pids;
    chomp @said;

    is_deeply(\@said, [ ('ok') x $KIDS ],
              'every child read what the parent stored before the fork');

    my %s = $c->stats;
    cmp_ok($s{evictions}, '>', 0, 'the churn from four processes evicted');
    cmp_ok($s{live}, '<=', $c->capacity,
           'and the cache never exceeded its capacity under contention');
}

# ---- the counts are exact across a fork ------------------------------------
#
# A process counts hits in its own handle and publishes them in batches, and a
# fork copies whatever it has not published yet. The parent publishes its copy,
# so the child must throw its own copy away or every fork counts the parent's
# recent hits twice. Ten hits and three misses are left pending on purpose.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';
    require POSIX;

    my $c = $arena->cache('tally', capacity => 64, ways => 8, entry_size => 128);
    $c->set('k', 'v');
    my %before = $c->stats;
    $c->get('k')    for 1 .. 10;
    $c->get('nope') for 1 .. 3;

    my $KIDS = 4;
    my @pids;
    for my $kid (1 .. $KIDS) {
        my $pid = fork();
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            $c->get('k')    for 1 .. 1000;
            $c->get('nope') for 1 .. 100;
            undef $c;                  # letting the handle go publishes
            POSIX::_exit(0);
        }
        push @pids, $pid;
    }
    waitpid $_, 0 for @pids;

    my %s = $c->stats;
    is($s{hits} - $before{hits}, 10 + $KIDS * 1000,
       'every hit in every process counted once - the ten pending at the fork '
     . 'were not counted again by each child');
    is($s{misses} - $before{misses}, 3 + $KIDS * 100, 'and every miss');
}

# ---- a value wider than the stack buffer -----------------------------------
#
# A get copies onto the stack when an entry is small enough, and allocates the
# most an entry could hold when it is not. Both paths, both answers.
{
    my $c = $arena->cache('wide', capacity => 8, ways => 8, entry_size => 4096);
    cmp_ok($c->max_pair, '>', 1024, 'an entry wider than the stack buffer');
    my $big = join '', map { chr(65 + $_ % 26) } 1 .. 3000;
    is($c->set('big', $big), 1, 'a 3000-byte value stored');
    $c->set('small', 'v');
    is(($c->get('big'))[0], $big, 'and it comes back whole');
    is(($c->get('small'))[0], 'v', 'and so does a small one beside it');
    is_deeply([$c->get('nope')], [], 'and a miss is still an empty list');
}

done_testing;
