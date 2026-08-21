#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp ();
use Time::HiRes ();
use Punk::Cache;

# Cross-worker invalidation.
#
# Without it the two shipped stores are not interchangeable and the pluggable
# interface is a lie: a delete on the file store reaches every worker because
# the filesystem is shared, and the same call on the memory store reaches one.
#
# What travels is the KEY, never the value. Publishing values would make this
# a replication system, and a bus slot is 2KB - a cached page would be refused
# outright and the pool would silently diverge.

# ---- a shared store needs none of this ---------------------------------------
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $f = Punk::Cache->new(file => dir => "$dir/f", max_bytes => '1M',
                             name => 'pages');
    my %s = $f->stats;
    is($s{shared}, 1, 'the file store declares itself shared');

    $f->set('k', 'v');
    $f->delete('k');
    my %after = $f->stats;
    is($after{invalidations_sent}, 0,
        'and sends nothing - every worker already sees the same files, so '
      . 'there is nothing to tell them');
}

# ---- an unshared store says so, and reports the pool honestly ----------------
{
    my $m = Punk::Cache->new(memory => max_bytes => '1M', name => 'sessions');
    my %s = $m->stats;
    is($s{shared}, 0, 'the memory store is not shared');
    is($s{pool},   0,
        'and with no arena mapped it reports NO pool - not merely that the '
      . 'ABI is present, which would be false comfort');
}

# ---- the origin token is PER PROCESS -----------------------------------------
# A publisher receives its own publication, and the token is how a store
# recognises its own message and leaves it alone - without it a `set` would
# tell the store that wrote it to drop what it has just written.
#
# So the token has to be minted per PROCESS. A store is built at boot, in the
# parent, and then forked into every worker: one minted at construction is the
# SAME in all of them, so every worker dismisses every other worker's
# invalidation as its own and the pool serves stale values forever.
#
# Asserted here rather than only through the real pool below, because that
# test can only make the assertion on a machine that spreads its requests -
# and on one that does not, it skips and this whole class of bug goes unseen.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $m = Punk::Cache->new(memory => max_bytes => '1M', name => 'origin');
    my $parent = $m->_origin;

    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $r;
        syswrite $w, $m->_origin;
        close $w;
        exec $^X, '-e', '1';
    }
    close $w;
    my $child = do { local $/; <$r> };
    close $r;
    waitpid $pid, 0;

    ok(length($child // ''), 'the forked worker reported a token') or skip 'no token', 1;
    isnt($child, $parent,
        'a forked worker mints its OWN origin token - inheriting the '
      . "parent's would make every worker ignore every other worker");
}

# ---- set invalidates as well as delete ---------------------------------------
# The one people forget. Worker A writing a new value while B through H serve
# the old one from memory until it expires is the same staleness bug wearing a
# different hat, and the commoner one: updating a cached thing happens far
# more often than deleting it.
SKIP: {
    skip 'this Hyperman has no message bus', 3
        unless eval { require Hyperman; Hyperman->can('bus_init') };
    skip 'no arena on this platform', 3
        unless Hyperman->bus_init(slots => 256, slot_size => 512, wakers => 8);

    my $m = Punk::Cache->new(memory => max_bytes => '1M', name => 'inv');
    my %s0 = $m->stats;
    is($s0{pool}, 1, 'with an arena the pool is reported live');

    $m->set('k', 'v');
    my %s1 = $m->stats;
    is($s1{invalidations_sent}, 1, 'a SET publishes an invalidation');

    $m->delete('k');
    my %s2 = $m->stats;
    is($s2{invalidations_sent}, 2, 'and so does a delete');
}

# ---- two named caches do not invalidate each other ---------------------------
SKIP: {
    skip 'this Hyperman has no message bus', 2
        unless eval { require Hyperman; Hyperman->can('bus_init') };
    skip 'no arena on this platform', 2 unless Hyperman->bus_init;

    my $a = Punk::Cache->new(memory => max_bytes => '1M', name => 'alpha');
    my $b = Punk::Cache->new(memory => max_bytes => '1M', name => 'beta');

    $a->set('shared-name', 'in-alpha');
    $b->set('shared-name', 'in-beta');

    # deliver whatever is pending to this process's own subscribers
    Hyperman->dispatch;

    is($b->get('shared-name'), 'in-beta',
        "alpha's invalidation did not empty beta - each store has its own "
      . 'topic, or two caches in one app would fight');
    is($a->get('shared-name'), 'in-alpha', 'and beta did not empty alpha');
}

# ---- ACROSS REAL WORKERS -----------------------------------------------------
# The assertion the whole phase exists for, and it needs a real pool: a set on
# one worker must make every OTHER worker stop serving its cached copy.
#
# Run against BOTH shapes that hold per-worker copies. The memory store is the
# obvious one. The file store with a memory tier is the one that looks shared
# and is not: every worker keeps its own tier, so it needs telling exactly as
# the memory store does - and it carries a failure the memory store cannot,
# because the file store's `delete` is `unlink`, so a receipt that reached the
# backend would have every worker destroy the entry the writer had just made.
my @VARIANTS = (
    { label => 'the memory store',        tier => 0 },
    { label => 'a file store + a tier',   tier => 1 },
);

for my $variant (@VARIANTS) {
SKIP: {
    my $LABEL = $variant->{label};
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    skip 'this Hyperman has no message bus', 4
        unless eval { require Hyperman; Hyperman->can('bus_init') };

    my $port  = 26900 + (($$ + ($variant->{tier} ? 151 : 0)) % 300);
    my $host  = "127.0.0.1:$port";
    my $tmp   = File::Temp::tempdir(CLEANUP => 1);
    my $truth = "$tmp/truth";
    my $cdir  = "$tmp/cache";
    my $tier  = $variant->{tier};
    open my $tfh, '>', $truth or die $!;
    print $tfh 'original';
    close $tfh;

    my $pid = fork // die "fork: $!";
    if (!$pid) {


        package InvApp;
        use Punk;
        # One package, one branch per process - each child is its own
        # interpreter, so only the declaration it runs is ever recorded.
        if ($tier) {
            cache 'file', dir => $cdir, max_bytes => '64M',
                          memory => '1M', memory_ttl => 30;
        }
        else {
            cache 'memory', max_bytes => '1M';
        }

        # A cache in front of a SOURCE OF TRUTH, which is the only shape in
        # which invalidation means anything: recomputing has to be able to
        # produce the new value, or a dropped key just comes back the same.
        get '/read' => sub {
            my ($c) = @_;
            my $v = $c->cache->compute('shared-key', 300, sub {
                open my $fh, '<', $truth or return 'missing';
                local $/;
                my $d = <$fh>;
                close $fh;
                return $d;
            });
            $c->text("$$:$v");
        };
        get '/stats' => sub {
            my ($c) = @_;
            my %s = $c->cache->stats;
            $c->text("$$:recv=$s{invalidations_received}:sent=$s{invalidations_sent}:pool=$s{pool}");
        };
        # change the truth here, and tell the pool to drop what it has
        get '/write/:v' => sub {
            my ($c) = @_;
            open my $fh, '>', $truth or return $c->text("$$:failed");
            print $fh $c->param('v');
            close $fh;
            $c->cache->delete('shared-key');
            $c->text("$$:wrote");
        };

        package main;
        Hyperman->run(app => InvApp->to_app, host => '127.0.0.1',
                      port => $port, workers => 3);
        exit 0;
    }

    for (1 .. 80) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        last if $s;
        Time::HiRes::sleep(0.1);
    }

    my $fetch = sub {
        my ($path) = @_;
        my $s = IO::Socket::INET->new(PeerAddr => $host) or return '';
        $s->autoflush(1);
        syswrite $s, "GET $path HTTP/1.1\r\nHost: $host\r\n"
                   . "Connection: close\r\n\r\n";
        my $body = '';
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm 5;
            while (sysread $s, my $c, 4096) { $body .= $c }
            alarm 0;
        };
        alarm 0;
        close $s;
        return $body =~ /(\d+:[a-z-]+)\s*\z/ ? $1 : '';
    };

    # warm every worker, and find out how many there are. A test that cannot
    # tell one worker from three proves nothing here - it was passing on a
    # single worker that hid this entire class of bug in the room work.
    # Keep reading until the requests have actually spanned workers. With a
    # shared listener one worker can take a whole burst, and then a
    # per-worker cache would satisfy every assertion below while fixing
    # nothing - which is precisely how this class of bug survived in the room
    # work until a test was made to prove the spread first.
    my %warmed;
    for (1 .. 60) {
        my $r = $fetch->('/read');
        $warmed{$1}++ if $r =~ /\A(\d+):/;
        last if keys %warmed >= 2 && (values %warmed)[0] >= 2;
        Time::HiRes::sleep(0.02);
    }

    SKIP: {
        skip 'every request landed on one worker; this machine will not '
           . 'spread them, so nothing here could distinguish a working '
           . 'invalidation from a single-worker cache', 4
            if keys %warmed < 2;

        is(scalar(grep { $fetch->('/read') =~ /:original\z/ } 1 .. 6), 6,
            "$LABEL: every worker is serving the cached original");

        $fetch->("/write/updated");

        # Converged WITHIN A BOUND, not instantly. Invalidation is
        # asynchronous and best effort by design - the message has to reach
        # each worker's loop and be drained - so asserting that the very next
        # read is fresh asserts more than the design promises and produces a
        # test that fails on timing rather than on correctness.
        my (@seen, @stale);
        for my $attempt (1 .. 20) {
            Time::HiRes::sleep(0.25);
            @seen  = map { $fetch->('/read') } 1 .. 12;
            @stale = grep { /:original\z/ } @seen;
            last unless @stale;
        }

        is_deeply(\@stale, [],
            "$LABEL: AFTER A WRITE ON ONE WORKER, no worker serves the old "
          . 'value - which is exactly what a per-worker cache could not do')
            or diag sprintf 'still stale on %d of %d reads across %d workers',
                            scalar @stale, scalar @seen, scalar keys %warmed;

        is(scalar(grep { /:updated\z/ } @seen), scalar @seen,
            "$LABEL: and they all recomputed to the new value");

        # The half a tier can get wrong that the memory store cannot. The
        # writer deleted the key and published; every other worker received
        # that and must drop its TIER copy only. A receipt that went on to the
        # backend would unlink the shared file, so the pool would look
        # perfectly coherent here while quietly running with no cache at all.
        SKIP: {
            skip 'no file store in this variant', 1 unless $tier;
            my @files = grep { !/\.(?:tmp|lock)/ } glob "$cdir/*/*/*";
            cmp_ok(scalar @files, '>', 0,
                "$LABEL: and the cache files SURVIVED the invalidation - the "
              . 'receipt dropped each tier copy without unlinking what the '
              . 'pool shares');
        }
    }
    note "$LABEL: workers warmed: " . keys(%warmed);

    kill 'TERM', $pid;
    waitpid $pid, 0;
}
}

done_testing;
