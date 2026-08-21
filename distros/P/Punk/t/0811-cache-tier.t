#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Time::HiRes ();
use Punk::Cache;

# The memory tier: a per-worker cache in front of a shared store.
#
# It exists because a file hit is 7.2us and 6.2us of that is the open()
# syscall - measured, in plan_punk_cache/phase-6-xs-front.md. Nothing around
# the syscall was worth tuning, so the only way a hit gets faster is not to
# open the file.
#
# t/0821 already asserts that a tier changes no ANSWERS, by running the whole
# conformance battery through one. What is left is here: that it changes the
# cost, that it cannot outlive what it stands in for, and that the two ways it
# could quietly corrupt a pool do not.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;

sub tiered {
    my (%opt) = @_;
    return Punk::Cache->new(file => dir => "$root/t" . $n++,
                            max_bytes => '64M', memory => '1M',
                            memory_ttl => 60, %opt);
}

# ---- it absorbs the reads ----------------------------------------------------
# Asserted by COUNT, not by clock: a timing assertion on a 6us syscall is a
# test that fails on a loaded machine rather than on a broken tier. The file
# store's own counters are visible through stats, so a read the tier answered
# is a read the backend never saw.
{
    my $c = tiered();
    $c->set('k', 'v' x 100);
    $c->get('k') for 1 .. 5;

    my %s = $c->stats;
    is($s{memory_hits}, 4,
        'five reads cost ONE trip to the file store and four memory hits - '
      . 'the whole point of the tier');
    is($s{memory_misses}, 1, 'and the one that faulted it in is counted');
    is($s{memory_entries}, 1, 'holding one entry');

    is($s{hits}, 5,
        'hits is the CACHE\'s, not the backend\'s: a read the tier answered '
      . 'is still a hit, and a caller measuring its hit rate does not care '
      . 'which half served it');
    is($s{misses}, 0, 'and nothing missed');
}

# ---- shared goes FALSE, or the pool never hears -------------------------------
# The file store reports is_shared, and an unshared store is one Punk::Cache
# publishes for. Put a per-worker tier in front and the shared premise is gone:
# every worker holds its own copy, so it must be told when a key changes.
{
    my $plain = Punk::Cache->new(file => dir => "$root/plain",
                                 max_bytes => '64M', name => 'p');
    my %p = $plain->stats;
    is($p{shared}, 1, 'a file store on its own is shared');

    my $c = tiered(name => 'tiered');
    my %s = $c->stats;
    is($s{shared}, 0,
        'and the SAME store with a tier is not - it holds per-worker copies '
      . 'now, so it has to publish like any unshared store or the pool goes '
      . 'on serving its own memory');
}

# ---- a tier in front of an unshared store is refused --------------------------
# Memory in front of memory multiplies the footprint and caches nothing new.
# Refusing it is also what lets a received invalidation drop the tier and stop,
# with no condition to get wrong - see the next block for why that matters.
{
    my $err = do { local $@; eval {
        Punk::Cache->new(memory => max_bytes => '1M', memory => '1M') }; $@ };
    like($err, qr/SHARED store/,
        'a tier in front of a per-process store is refused at BOOT, naming '
      . 'what is wrong with it');

    $err = do { local $@; eval { tiered(memory => 'banana') }; $@ };
    like($err, qr/not a size/, 'and a memory budget that is not a size croaks');

    $err = do { local $@; eval { tiered(memory_ttl => 0) }; $@ };
    like($err, qr/memory_ttl must be greater than zero/,
        'and so does a ceiling of zero, which would mean an entry that is '
      . 'never allowed to be read from the tier it was just put in');
}

# ---- the tier cannot outlive the entry it stands in for -----------------------
# The tier holds the expiry the STORE recorded, not one counted from the moment
# it faulted the value in. Getting this wrong serves a value the store
# considers gone, which is the failure mode nobody would look for in a cache
# that appears to be working.
{
    my $c = tiered(memory_ttl => 60);       # a ceiling far beyond the entry
    $c->set('brief', 'value', 1);
    is($c->get('brief'), 'value', 'the entry is served while it lives');

    Time::HiRes::sleep(1.3);
    is($c->get('brief'), undef,
        'and is GONE once the store\'s own expiry passes - the tier inherited '
      . 'the expiry rather than starting a fresh 60 seconds of its own');
}

# ---- memory_ttl is a ceiling, and it has a second job -------------------------
# punk_cachefile evicts coldest-first by st_atime, and a tier absorbs exactly
# the reads that keep a hot key's atime fresh - so without a ceiling the sweep
# would evict the hottest entries FIRST. The ceiling forces a re-read, which is
# what keeps that signal alive. It bounds staleness too, when the bus drops a
# message. One ceiling, two jobs.
{
    my $c = tiered(memory_ttl => 1);
    $c->set('long', 'value', 300);          # lives far longer than the ceiling

    $c->get('long');
    my %before = $c->stats;

    Time::HiRes::sleep(1.3);
    is($c->get('long'), 'value', 'the value is still served after the ceiling');

    my %after = $c->stats;
    cmp_ok($after{memory_misses}, '>', $before{memory_misses},
        'but it was re-read from the store rather than served from a tier '
      . 'entry older than the ceiling - which is what keeps the file\'s atime '
      . 'moving, and its eviction order honest');
}

# ---- one big value may not flush the hot set ---------------------------------
# punk_cache_set refuses only what cannot fit the WHOLE budget, so without a
# per-entry cap a single large value is admitted and evicts everything else on
# its way in.
{
    my $c = tiered();                       # 1M tier, so the cap is 128K
    $c->set('hot', 'small');
    $c->get('hot') for 1 .. 2;

    $c->set('big', 'x' x 200_000);
    $c->get('big') for 1 .. 3;

    my %s = $c->stats;
    is($c->get('hot'), 'small',
        'a value too big for a share of the tier did not push the hot entry '
      . 'out on its way past');
    is($c->get('big'), 'x' x 200_000,
        'and is still served correctly - refused from the TIER is not refused '
      . 'from the cache');
    ok($s{memory_entries} >= 1, 'the small entry is still tiered');
}

# ---- stats say enough to justify the memory ----------------------------------
{
    my $c = tiered();
    my %s = $c->stats;
    for my $k (qw(memory_hits memory_misses memory_evictions memory_refused
                  memory_expired memory_bytes memory_entries memory_max_bytes
                  memory_ttl)) {
        ok(exists $s{$k}, "stats reports $k");
    }
    is($s{memory_max_bytes}, 1024 * 1024, 'the tier budget is what was asked for');

    my $plain = Punk::Cache->new(file => dir => "$root/nostats",
                                 max_bytes => '64M');
    my %p = $plain->stats;
    ok(!exists $p{memory_hits},
        'and a store with no tier does not sprout keys that are always zero');
}

# ---- THE ONE THAT WOULD EAT THE CACHE ----------------------------------------
# A tiered store publishes (above). Punk::Cache's subscriber drops the key by
# calling the backend's delete - and for the file store, delete is unlink. So a
# tiered store that handled its own invalidations the ordinary way would have
# every worker DELETE THE FILE the writer had just written, on every write.
#
# The rule: a received invalidation drops the TIER and never touches the
# backend. Two stores on one directory and one topic stand in for two workers.
SKIP: {
    skip 'this Hyperman has no message bus', 4
        unless eval { require Hyperman; Hyperman->can('bus_init') };
    skip 'no arena on this platform', 4
        unless Hyperman->bus_init(slots => 256, slot_size => 512, wakers => 8);

    my $dir = "$root/pool";
    my $a = Punk::Cache->new(file => dir => $dir, max_bytes => '64M',
                             memory => '1M', memory_ttl => 60, name => 'pool');
    my $b = Punk::Cache->new(file => dir => $dir, max_bytes => '64M',
                             memory => '1M', memory_ttl => 60, name => 'pool');

    $a->set('k', 'original');
    is($b->get('k'), 'original', 'both workers see the value');
    $a->get('k');                       # both tiers now hold it

    $a->set('k', 'updated');
    Hyperman->dispatch;                 # deliver to this process's subscribers

    my @files = glob "$dir/*/*/*";
    is(scalar @files, 1,
        'AFTER THE INVALIDATION THE FILE IS STILL THERE - the receipt drops '
      . 'the tier copy and stops, because the backend is shared and going '
      . 'further would unlink what the writer had just written');

    is($b->get('k'), 'updated',
        'and the other worker dropped its tier copy, so it re-read the new '
      . 'value rather than serving its own');

    my %s = $b->stats;
    cmp_ok($s{invalidations_received}, '>', 0,
        'which it did because it was told, not because anything expired');
}

done_testing;
