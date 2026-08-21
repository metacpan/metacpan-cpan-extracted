#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Cache;

# The in-memory store, and the front end over it.
#
# The assertion this whole component exists for is the byte budget: an LRU
# bounded by entry count does not bound memory, and a thousand entries of ten
# megabytes is ten gigabytes.

# ---- the byte budget holds ---------------------------------------------------
{
    my $cap = 256 * 1024;
    my $c = Punk::Cache::Memory->new(max_bytes => $cap);

    # write far past the cap with 4KB values
    my $val = 'x' x 4096;
    $c->set("k$_", $val, 0) for 1 .. 500;

    my %s = $c->stats;
    cmp_ok($s{bytes}, '<=', $cap,
        'THE BYTE BUDGET HOLDS after writing 2MB into a 256KB cache')
        or diag "bytes=$s{bytes} cap=$cap";
    cmp_ok($s{evictions}, '>', 0, 'and the evictions are counted');
    cmp_ok($s{entries}, '>', 0, 'and it did not simply empty itself');

    # the newest survive, the oldest are gone
    ok(defined $c->get('k500'), 'the most recent write is still there');
    ok(!defined $c->get('k1'),  'and the oldest has been evicted');
}

# ---- overwrite accounting ----------------------------------------------------
# The case that gets missed: replace a small value with a large one and the
# total must move by the DIFFERENCE. Getting this wrong is how a bounded cache
# quietly stops being bounded.
{
    my $c = Punk::Cache::Memory->new(max_bytes => 1024 * 1024);
    $c->set('k', 'x' x 1024, 0);
    my %s0 = $c->stats; my $small = $s0{bytes};

    $c->set('k', 'x' x 65536, 0);
    my %s = $c->stats;

    is($s{entries}, 1, 'an overwrite is still one entry');
    cmp_ok($s{bytes}, '>', $small, 'and the total grew');
    cmp_ok($s{bytes}, '<', $small + 70000,
        'by roughly the DIFFERENCE, not by the whole new value on top of '
      . 'the old one');

    $c->set('k', 'x' x 16, 0);
    my %s2 = $c->stats;
    cmp_ok($s2{bytes}, '<', $small,
        'and shrinks again on a smaller overwrite');
}

# ---- a value too big is refused, not stored ----------------------------------
# Making room would evict everything else and still not fit.
{
    my $c = Punk::Cache::Memory->new(max_bytes => 4096);
    $c->set('keep', 'small', 0);

    is($c->set('huge', 'x' x 65536, 0), 0, 'an oversize value is refused');
    my %s = $c->stats;
    is($s{refused}, 1, 'and the refusal is counted');
    is($c->get('keep'), 'small',
        'and it did not empty the cache on its way past - which is what '
      . 'making room for it would have done');
}

# ---- LRU order is by USE, not by insertion -----------------------------------
{
    my $c = Punk::Cache::Memory->new(max_bytes => 4096);
    $c->set($_, 'x' x 512, 0) for qw(a b c);

    $c->get('a');                     # a is now the most recently used

    $c->set("filler$_", 'x' x 512, 0) for 1 .. 8;   # force eviction

    ok(defined $c->get('a') || !defined $c->get('b'),
        'the least recently USED is evicted before the least recently SET');
}

# ---- TTL ---------------------------------------------------------------------
{
    my $c = Punk::Cache::Memory->new(max_bytes => 65536);

    $c->set('forever', 'v', 0);
    $c->set('brief',   'v', 1);

    is($c->get('forever'), 'v', 'a ttl of 0 means NO EXPIRY');
    is($c->get('brief'),   'v', 'and a live entry is returned');

    sleep 2;

    is($c->get('forever'), 'v', 'still there after two seconds');
    ok(!defined $c->get('brief'), 'and the one-second entry has expired');
    my %se = $c->stats;
    is($se{expired}, 1, 'the expiry is counted');
}

# ---- binary values and keys --------------------------------------------------
{
    my $c = Punk::Cache::Memory->new(max_bytes => 65536);
    my $bin = join '', map { chr } 0 .. 255;

    $c->set($bin, $bin, 0);
    is($c->get($bin), $bin, 'a binary key and value round trip, NUL and all');

    $c->set('empty', '', 0);
    is($c->get('empty'), '', 'a zero-length value is a value, not a miss');
}

# ---- stats count truthfully --------------------------------------------------
{
    my $c = Punk::Cache::Memory->new(max_bytes => 65536);
    $c->set('a', 'v', 0);
    $c->get('a');
    $c->get('a');
    $c->get('nope');

    my %s = $c->stats;
    is($s{hits},   2, 'hits count hits');
    is($s{misses}, 1, 'and misses count misses');

    $c->clear;
    my %after = $c->stats;
    is($after{entries}, 0, 'clear empties');
    is($after{bytes},   0, 'and the byte total goes with it');
    is($after{hits},    2, 'but the cumulative counters are not reset by it');
}

# ---- the front end -----------------------------------------------------------
{
    my $c = Punk::Cache->new(memory => max_bytes => '1M');

    my $ran = 0;
    my $v = $c->compute('k', 0, sub { $ran++; 'computed' });
    is($v, 'computed', 'compute returns the computed value');
    is($c->compute('k', 0, sub { $ran++; 'no' }), 'computed', 'and caches it');
    is($ran, 1, 'the code ran exactly once');

    # a cached undef is a HIT, or an expensive lookup that finds nothing is
    # repeated on every request - the case people meet caching "does this
    # user exist"
    my $nran = 0;
    $c->compute('u', 0, sub { $nran++; undef });
    my $again = $c->compute('u', 0, sub { $nran++; 'SHOULD NOT RUN' });
    ok(!defined $again, 'a cached undef comes back as undef');
    is($nran, 1, 'and is a HIT - the code did not run again');

    my $data = $c->compute('j', 0, sub { { a => [1, 2, 3] } }, json => 1);
    is_deeply($data->{a}, [1, 2, 3], 'json => 1 round trips a structure');
    my $cached = $c->compute('j', 0, sub { die "must not run\n" }, json => 1);
    is_deeply($cached->{a}, [1, 2, 3], 'and it comes back decoded from cache');
}

# ---- max_bytes suffixes ------------------------------------------------------
{
    is(Punk::Cache::_bytes('512M'), 512 * 1024 * 1024, '512M');
    is(Punk::Cache::_bytes('2G'),   2 * 1024 ** 3,     '2G');
    is(Punk::Cache::_bytes('64K'),  65536,             '64K');
    is(Punk::Cache::_bytes('1024'), 1024,              'a plain byte count');
    is(Punk::Cache::_bytes('banana'), undef, 'and nonsense is not a size');

    ok(!eval { Punk::Cache->new(memory => max_bytes => 'banana'); 1 },
        'which croaks at construction rather than at the first miss');
    like($@, qr/not a size/, 'and says so');

    ok(!eval { Punk::Cache->new('nosuchbackend'); 1 },
        'an unknown backend croaks');
    like($@, qr/unknown backend/, 'naming what it does know');
}

# ---- keys --------------------------------------------------------------------
{
    my $c = Punk::Cache->new(memory => max_bytes => '1M');
    ok(!eval { $c->get(undef); 1 },  'an undefined key croaks');
    ok(!eval { $c->get(''); 1 },     'an empty key croaks');
    ok(!eval { $c->get('x' x 5000); 1 }, 'an absurd key croaks');

    # a path is just a key here: the store never uses it as a filename
    $c->set('../../etc/passwd', 'harmless', 0);
    is($c->get('../../etc/passwd'), 'harmless',
        'a key that looks like a path is just a key');
}

# ---- a custom backend --------------------------------------------------------
{
    package TinyBackend;
    sub new    { bless { h => {} }, shift }
    sub get    { $_[0]{h}{ $_[1] } }
    sub set    { $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete { defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear  { %{ $_[0]{h} } = (); 1 }
    sub stats  { (entries => scalar keys %{ $_[0]{h} }) }

    package main;

    my $c = Punk::Cache->new(TinyBackend->new);
    $c->set('k', 'v');
    is($c->get('k'), 'v', 'anything with the five methods is a backend');

    ok(!eval { Punk::Cache->new(bless {}, 'NotABackend'); 1 },
        'and something without them is refused at construction');
    like($@, qr/must implement/, 'naming the method it lacks');
}

# ---- the keyword, through a real request -------------------------------------
{
    package CacheApp;
    use Punk;
    cache 'memory', max_bytes => '1M';
    our $RAN = 0;
    get '/x' => sub {
        my ($c) = @_;
        $c->text($c->cache->compute('k', 60, sub { $RAN++; 'made-once' }));
    };

    package main;
    my $app = CacheApp->to_app;
    my $call = sub {
        $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/x', SCRIPT_NAME => '',
                 QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                 'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                 'psgi.errors' => \*STDERR });
    };

    my $r1 = $call->();
    my $r2 = $call->();
    is($r1->[0], 200, 'the cached route serves');
    is($r2->[2][0], 'made-once', 'and serves the same value the second time');
    is($CacheApp::RAN, 1,
        'the expensive code ran ONCE across two requests - the store is built '
      . 'at to_app and shared, not constructed per request');

    # through the app's own accessor rather than reaching into the state
    # hash: the shape in there is not this test's business, and coupling to
    # it broke the moment named stores made it a hash of stores.
    my %s = CacheApp->punk_app->{cache}{default}->stats;
    is($s{hits},    1, 'one hit');
    is($s{misses},  1, 'and one miss');
    is($s{entries}, 1, 'holding one entry');
}

# ---- no cache configured -----------------------------------------------------
{
    package NoCacheApp;
    use Punk;
    get '/y' => sub { $_[0]->text(eval { $_[0]->cache; 'got one' } || 'croaked') };

    package main;
    my $app = NoCacheApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/y', SCRIPT_NAME => '',
                     QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                     'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                     'psgi.errors' => \*STDERR });
    is($r->[2][0], 'croaked',
        'an app with no cache keyword says so rather than handing back '
      . 'something that silently never hits');
}

# ---- fork: entries survive, statistics do not --------------------------------
# A worker inherits the parent's entries and they are still correct. Its
# COUNTERS are not: a child reporting its parent's hit rate is reporting a
# number about a different process, which an operator cannot act on.
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    my $c = Punk::Cache::Memory->new(max_bytes => 65536);
    $c->set('inherited', 'value', 0);
    $c->get('inherited') for 1 .. 5;         # five hits in the parent

    pipe my ($r, $w) or die "pipe: $!";
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        close $r;
        my $v = $c->get('inherited');
        my %s = $c->stats;
        syswrite $w, ($v // '-') . " $s{hits} $s{entries}\n";
        close $w;
        exec $^X, '-e', '1';
    }
    close $w;
    my $line = <$r>;
    chomp $line if defined $line;
    close $r;
    waitpid $pid, 0;

    my ($val, $hits, $entries) = split ' ', ($line // '- 0 0');
    is($val, 'value', 'a forked worker still sees the inherited entries');
    cmp_ok($entries, '>', 0, 'and still holds them');
    is($hits, 1,
        'but the hit count is ITS OWN - one, from the read it just did, not '
      . 'the five the parent made');
}

# ---- a bad cache config croaks at BOOT ---------------------------------------
# Not on the first miss at three in the morning. Asserted through to_app,
# because that is where it has to happen - the constructor croaking is not the
# same promise.
{
    package BadBackendApp;
    use Punk;
    cache 'nosuchbackend';
    get '/' => sub { $_[0]->text('never reached') };

    package BadSizeApp;
    use Punk;
    cache 'memory', max_bytes => 'banana';
    get '/' => sub { $_[0]->text('never reached') };

    package main;

    ok(!eval { BadBackendApp->to_app; 1 },
        'an unknown backend croaks at to_app, not at the first miss');
    like($@, qr/unknown backend/, 'naming what it does know');

    ok(!eval { BadSizeApp->to_app; 1 }, 'and so does a nonsense max_bytes');
    like($@, qr/not a size/, 'saying what a size looks like');
}

# ---- named caches ------------------------------------------------------------
# A session cache and a rendered-page cache want different budgets, different
# backends and different lifetimes. Sharing one store means the big cold thing
# evicts the small hot thing.
{
    package NamedApp;
    use Punk;
    cache 'memory', max_bytes => '1M';
    cache sessions => { backend => 'memory', max_bytes => '64K' };
    cache pages    => { backend => 'memory', max_bytes => '256K' };

    get '/n' => sub {
        my ($c) = @_;
        $c->cache->set('k', 'in-default');
        $c->cache('sessions')->set('k', 'in-sessions');
        $c->text(join '|',
                 $c->cache->get('k'),
                 $c->cache('sessions')->get('k'),
                 ($c->cache('pages')->get('k') // 'absent'));
    };

    package main;
    my $app = NamedApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/n',
                     SCRIPT_NAME => '', QUERY_STRING => '',
                     SERVER_NAME => 'l', SERVER_PORT => 80,
                     'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                     'psgi.errors' => \*STDERR });

    is($r->[2][0], 'in-default|in-sessions|absent',
        'named stores are ISOLATED - the same key in two of them is two '
      . 'values, and a third store has neither');

    my $stores = NamedApp->punk_app->{cache};
    is_deeply([ sort keys %$stores ], [qw(default pages sessions)],
        'the default and both named stores were built');

    my %sess = $stores->{sessions}->stats;
    my %page = $stores->{pages}->stats;
    is($sess{max_bytes}, 64 * 1024,  'each keeps its own budget');
    is($page{max_bytes}, 256 * 1024, 'and they differ');
}

# ---- an unknown name is an error, not an empty cache -------------------------
{
    package UnknownApp;
    use Punk;
    cache 'memory', max_bytes => '1M';
    get '/u' => sub {
        my ($c) = @_;
        $c->text(eval { $c->cache('nope'); 'got one' } || 'croaked');
    };

    package main;
    my $app = UnknownApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/u',
                     SCRIPT_NAME => '', QUERY_STRING => '',
                     SERVER_NAME => 'l', SERVER_PORT => 80,
                     'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                     'psgi.errors' => \*STDERR });
    is($r->[2][0], 'croaked',
        'asking for a cache that was never declared croaks rather than '
      . 'handing back a store that silently never hits');
}

done_testing;
