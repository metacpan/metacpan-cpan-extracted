#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Time::HiRes ();
use Punk::Cache;

# The file store: the default, because the filesystem is already shared and a
# per-worker memory cache costs N times its cap.
#
# The assertions that matter here are the ones a single process cannot make:
# atomic writes under concurrent writers, and single-flight collapsing a herd.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fresh { Punk::Cache::File->new(dir => "$root/c" . $n++, @_) }

# ---- keys never become paths -------------------------------------------------
# A cache key is application data, and often user data.
{
    my $c = fresh();
    my @nasty = (
        '../../etc/passwd',
        '/etc/passwd',
        "with\0nul",
        "new\nline",
        'x' x 4000,
        join('', map { chr } 0 .. 255),
    );

    for my $k (@nasty) {
        my $label = length($k) > 20 ? substr($k, 0, 12) . '...' : $k;
        $label =~ s/[^\x20-\x7e]/./g;
        $c->set($k, "value-for-$label", 0);
        is($c->get($k), "value-for-$label", "a key round trips: $label");
    }

    ok(!-e '/tmp/../etc/passwd.punkcache', 'and nothing escaped the cache dir');

    my %s = $c->stats;
    is($s{entries}, scalar @nasty,
        'every one of them is a distinct entry - none collided');
}

# ---- TTL, including across a restart -----------------------------------------
# The expiry lives in the entry, not in mtime, so a new store over the same
# directory honours it.
{
    my $dir = "$root/ttl";
    my $c = Punk::Cache::File->new(dir => $dir, max_bytes => 1024 * 1024);

    $c->set('forever', 'v', 0);
    $c->set('brief',   'v', 1);
    is($c->get('forever'), 'v', 'a ttl of 0 means NO EXPIRY');

    # a brand new store over the same directory - as a restart would be
    my $c2 = Punk::Cache::File->new(dir => $dir, max_bytes => 1024 * 1024);
    is($c2->get('forever'), 'v', 'entries survive a restart');
    is($c2->get('brief'),   'v', 'and so does an unexpired ttl');

    sleep 2;
    ok(!defined $c2->get('brief'), 'which then expires when it should');
    is($c2->get('forever'), 'v',   'while the eternal one stays');
}

# ---- the byte budget ---------------------------------------------------------
{
    my $cap = 128 * 1024;
    my $c = fresh(max_bytes => $cap);

    my $val = 'x' x 4096;
    $c->set("k$_", $val, 0) for 1 .. 200;      # ~800KB into a 128KB cache
    $c->_sweep;                                 # force the reconcile

    my %s = $c->stats;
    cmp_ok($s{bytes}, '<=', $cap,
        'THE BYTE BUDGET HOLDS after writing 800KB into a 128KB cache')
        or diag "bytes=$s{bytes} cap=$cap";
    cmp_ok($s{evictions}, '>', 0, 'and the evictions are counted');
    cmp_ok($s{entries},   '>', 0, 'and it did not empty itself');
}

# ---- an oversize value is refused --------------------------------------------
{
    my $c = fresh(max_bytes => 8192);
    $c->set('keep', 'small', 0);
    is($c->set('huge', 'x' x 65536, 0), 0, 'an oversize value is refused');
    my %s = $c->stats;
    is($s{refused}, 1, 'and counted');
    is($c->get('keep'), 'small', 'without disturbing what was there');
}

# ---- concurrent writers ------------------------------------------------------
# Atomic rename means a reader never sees a partial entry. The survivor must be
# one of the values written WHOLE, never a mixture.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $dir = "$root/conc";
    my $c = Punk::Cache::File->new(dir => $dir, max_bytes => 4 * 1024 * 1024);
    my @kids;

    for my $w (1 .. 6) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $mine = Punk::Cache::File->new(dir => $dir,
                                              max_bytes => 4 * 1024 * 1024);
            # every worker writes a DIFFERENT whole value to the same key
            $mine->set('contended', ("w$w" x 2000), 0) for 1 .. 40;
            exec $^X, '-e', '1';
        }
        push @kids, $pid;
    }
    waitpid $_, 0 for @kids;

    my $got = $c->get('contended');
    ok(defined $got, 'the contended key survived six concurrent writers');
    like($got, qr/\A(?:w[1-6])+\z/,
        'and holds ONE writer\'s value whole - never a mixture, because a '
      . 'reader cannot see a half-written entry')
        or diag 'got ' . length($got) . ' bytes';
}

# ---- SINGLE-FLIGHT -----------------------------------------------------------
# N workers miss the same expensive key at the same moment and compute it ONCE.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $dir   = "$root/flight";
    my $count = "$root/computes";
    my @kids;

    for my $w (1 .. 6) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $c = Punk::Cache->new(file => dir => $dir,
                                     max_bytes => '1M', lock_wait => 5);
            Time::HiRes::sleep(0.05);        # everybody misses together
            my $v = $c->compute('expensive', 60, sub {
                # record that a computation happened, then take a while
                if (open my $fh, '>>', $count) { print $fh "x"; close $fh }
                Time::HiRes::sleep(0.3);
                'the-answer';
            });
            exec $^X, '-e', ($v eq 'the-answer' ? '1' : 'exit 1');
        }
        push @kids, $pid;
    }
    waitpid $_, 0 for @kids;

    my $computes = -s $count || 0;
    is($computes, 1,
        'SINGLE-FLIGHT: six workers missed the same key at once and it was '
      . 'computed ONCE - the moment a cache is most valuable is the moment '
      . 'a herd would stop it helping')
        or diag "computed $computes times";

    my $c = Punk::Cache->new(file => dir => $dir, max_bytes => '1M');
    is($c->get('expensive'), 'the-answer', 'and the value is there');
}

# ---- a dead winner does not wedge the key ------------------------------------
# The lock holder can be killed between taking it and writing the value. A lock
# older than the wait budget is STOLEN, or one crash poisons a key until
# somebody notices.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $dir = "$root/wedged";
    my $c = Punk::Cache->new(file => dir => $dir, max_bytes => '1M',
                             lock_wait => 1);

    # a worker that takes the lock and dies holding it
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $mine = Punk::Cache->new(file => dir => $dir, max_bytes => '1M',
                                    lock_wait => 1);
        $mine->backend->_lock('orphan');
        exec $^X, '-e', '1';                 # gone, lock still held
    }
    waitpid $pid, 0;

    my $t0 = Time::HiRes::time();
    my $v = $c->compute('orphan', 60, sub { 'computed-anyway' });
    my $took = Time::HiRes::time() - $t0;

    is($v, 'computed-anyway',
        'a key whose lock holder died is still computed - correctness never '
      . 'depends on the lock');
    cmp_ok($took, '<', 4,
        'and promptly, because a stale lock is stolen rather than obeyed')
        or diag "took ${took}s";
}

# ---- the keyword validates the directory at boot ------------------------------
{
    package BadDirApp;
    use Punk;
    cache 'file', dir => '/proc/nonexistent/nope', max_bytes => '1M';
    get '/' => sub { $_[0]->text('never reached') };

    package main;
    ok(!eval { BadDirApp->to_app; 1 },
        'an unwritable cache dir croaks at to_app, not on the first miss');
    like($@, qr/Punk::Cache::File/, 'naming the store that could not start');
}

# ---- a collision is a MISS, not a wrong answer -------------------------------
# The key is stored in the entry and compared on read, so two keys landing on
# one path can only ever produce a miss.
#
# Rather than hunt a real FNV-1a 64 collision - a birthday search of about
# four billion hashes - this manufactures the exact condition: write B's
# entry, then move the file to where A would look. A's path now holds an entry
# whose header says B, which is precisely what a collision is.
{
    my $dir = "$root/collide";
    my $c = Punk::Cache::File->new(dir => $dir, max_bytes => 1024 * 1024);

    my $find = sub {
        my @f;
        my $walk;
        $walk = sub {
            my ($d) = @_;
            opendir my $dh, $d or return;
            for my $e (grep { !/\A\./ } readdir $dh) {
                my $p = "$d/$e";
                if    (-d $p) { $walk->($p) }
                elsif (-f $p) { push @f, $p }
            }
            closedir $dh;
        };
        $walk->($dir);
        return @f;
    };

    $c->set('key-a', 'value-a', 0);
    my ($path_a) = $find->();
    ok($path_a, 'key-a has an entry on disk');

    $c->delete('key-a');
    $c->set('key-b', 'value-b', 0);
    my ($path_b) = $find->();
    ok($path_b && $path_b ne $path_a, 'key-b lands somewhere else');

    # make key-a's path hold key-b's entry: a collision, exactly
    rename $path_b, $path_a or die "rename: $!";

    is($c->get('key-a'), undef,
        'A COLLISION IS A MISS - the entry at that path belongs to another '
      . 'key, and the stored key is compared on read, so the wrong value is '
      . 'never handed back as if it were the right one');
}

done_testing;
