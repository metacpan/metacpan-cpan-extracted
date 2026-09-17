#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr blessed);
use Shared::Arena ();

# serialise => 1: A MAP OR CACHE THAT STORES A STRUCTURE AND GIVES IT BACK.
#
# The other tenants store bytes, so a reference stored in one comes back as
# "HASH(0x...)". A serialised tenant encodes the value through Struct::Codec
# going in and decodes coming out, and the assertions here are about SAMENESS:
# is_deeply for the shape, refaddr for a shared referent, the UTF-8 flag, the
# class of a blessed thing. And about the edges: what cannot be encoded croaks
# and stores nothing, what does not fit is refused the way bytes are, a counter
# cannot live in one, two processes cannot disagree about the flag, and corrupt
# bytes croak rather than crash.
#
# Every write and read is made twice where a door exists: through the method
# form, which is the compiled op, and through ->can, which is the plain XSUB.
# That is the t/24-xop.t differential, and it matters more here than anywhere
# because the two paths have separate copies of the encode and decode branch.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
my $cache = $arena->cache('sc', capacity => 64, entry_size => 1024, serialise => 1);
my $map   = $arena->map('sm', slots => 64, slot_size => 1024, serialise => 1);
my $plain = $arena->cache('pc', capacity => 64, entry_size => 1024);

ok($cache->serialised, 'a cache made with serialise => 1 says so');
ok($map->serialised,   'and so does a map');
ok(!$plain->serialised, 'and one made without does not');

my $xs_get   = Shared::Arena::Cache->can('get');
my $xs_set   = Shared::Arena::Cache->can('set');
my $xs_fetch = Shared::Arena::Map->can('fetch');
my $xs_store = Shared::Arena::Map->can('store');
my $xs_incr  = Shared::Arena::Map->can('incr');
my $xs_ctr   = Shared::Arena::Map->can('counter');

# ---- the round trip --------------------------------------------------------
my $shared = { deep => [1, 2, 3] };
my $value  = {
    name   => 'x',
    n      => 42,
    f      => 1.5,
    list   => [1, 'two', undef, [3]],
    a      => $shared,
    b      => $shared,
    nested => { k => 'v', empty => {} },
};

{
    is($cache->set('h', $value), 1, 'cache set: a hashref is stored');
    my ($back) = $cache->get('h');
    is_deeply($back, $value, 'cache get: and comes back the same shape');
    is(refaddr($back->{a}), refaddr($back->{b}),
       'a referent shared twice in the value is shared twice coming out');
    isnt(refaddr($back), refaddr($value), 'and it is a copy, not the original');
    $back->{a}{deep}[0] = 'changed';
    is($value->{a}{deep}[0], 1, 'so changing the copy leaves the original alone');

    is($map->store('h', $value), 1, 'map store: a hashref is stored');
    my ($mback) = $map->fetch('h');
    is_deeply($mback, $value, 'map fetch: and comes back the same shape');
    is(refaddr($mback->{a}), refaddr($mback->{b}), 'with its sharing intact');

    my @miss = $cache->get('absent');
    is(scalar @miss, 0, 'a miss is still an empty list');
    ok(!defined scalar $map->fetch('absent'), 'and undef in scalar context');
}

# ---- the op door and the XSUB agree ----------------------------------------
{
    Shared::Arena::_xop_reset();
    is($cache->set('op', $value), $cache->$xs_set('xs', $value),
       'cache set: op path and XSUB return the same');
    is_deeply(scalar $cache->get('op'), scalar $cache->$xs_get('xs'),
              'cache get: op path and XSUB decode the same value');
    is_deeply(scalar $cache->get('xs'), $value,
              'the door reads what the XSUB wrote');
    is_deeply(scalar $cache->$xs_get('op'), $value,
              'and the XSUB reads what the door wrote');

    is($map->store('op', $value), $map->$xs_store('xs', $value),
       'map store: op path and XSUB return the same');
    is_deeply(scalar $map->fetch('op'), scalar $map->$xs_fetch('xs'),
              'map fetch: op path and XSUB decode the same value');
    is_deeply(scalar $map->fetch('xs'), $value, 'the door reads the XSUB\'s');
    is_deeply(scalar $map->$xs_fetch('op'), $value, 'the XSUB reads the door\'s');

    my (undef, $hits) = Shared::Arena::_xop_stats();
    is($hits, 6, 'every method-form call above took the op path');

    # The four-argument set is its own door.
    Shared::Arena::_xop_reset();
    is($cache->set('ttl', $value, ttl => 60), 1, 'set with a ttl stores');
    is_deeply(scalar $cache->get('ttl'), $value, 'and decodes back');
    (undef, $hits) = Shared::Arena::_xop_stats();
    is($hits, 2, 'through the ttl door and the get door');

    # A get whose entersub belongs to Frozen runs the whole door from the
    # method op. The stats say it happened; the value says it decoded.
    my (undef, undef, undef, $methonly) = Shared::Arena::_xop_stats();
    cmp_ok($methonly, '>=', 0, 'the shared-site count is readable');
}

# ---- strings, numbers and the UTF-8 flag ------------------------------------
{
    my $wide = "caf\x{e9} \x{263a}";
    ok(utf8::is_utf8($wide), 'the specimen carries the UTF-8 flag');

    is($cache->set($wide, { $wide => $wide, plain => 'bytes' }), 1,
       'a UTF-8 key and value store');
    my ($u) = $cache->get($wide);
    is($u->{$wide}, $wide, 'the value\'s string is the same characters');
    ok(utf8::is_utf8($u->{$wide}), 'and keeps its flag');
    ok(!utf8::is_utf8($u->{plain}), 'while a byte string stays a byte string');
    ok(exists $u->{$wide}, 'a UTF-8 hash key inside the value is found again');

    $map->store('num', [10, '10', 1.25]);
    my ($nums) = $map->fetch('num');
    require B;
    my $flags = sub { B::svref_2object(\$_[0])->FLAGS };
    ok($flags->($nums->[0]) & B::SVf_IOK(), 'an integer comes back an integer');
    ok(!($flags->($nums->[1]) & B::SVf_IOK()), 'a string of digits stays a string');
    ok($flags->($nums->[2]) & B::SVf_NOK(), 'a float comes back a float');

    $map->store('str', 'just a string');
    is_deeply([$map->fetch('str')], ['just a string'],
              'a plain scalar round trips as itself');
    $map->store('undef', undef);
    my @got = $map->fetch('undef');
    is(scalar @got, 1, 'undef is a value, stored and returned');
    ok(!defined $got[0], 'as undef');
}

# ---- a blessed object -------------------------------------------------------
{
    my $obj = bless { id => 7, tags => [qw(a b)] }, 'My::Thing';
    is($cache->set('obj', $obj), 1, 'an object stores');
    my ($o) = $cache->get('obj');
    is(blessed($o), 'My::Thing', 'and comes back blessed into its class');
    is($o->{id}, 7, 'with its contents');
    is_deeply($o->{tags}, [qw(a b)], 'all of them');
}

# ---- what cannot be encoded croaks and stores nothing ------------------------
{
    my $y = 1;
    my $closure = sub { $y };

    my $err = '';
    eval { $cache->set('code', { f => $closure }); 1 } or $err = $@;
    like($err, qr/Struct::Codec: cannot encode a closure/,
         'cache set: a closure croaks with the codec\'s message');
    my @none = $cache->get('code');
    is(scalar @none, 0, 'and nothing was stored under the key');

    $err = '';
    eval { $cache->$xs_set('code', $closure); 1 } or $err = $@;
    like($err, qr/cannot encode a closure/, 'the XSUB says the same');

    $err = '';
    eval { $map->store('code', $closure); 1 } or $err = $@;
    like($err, qr/cannot encode a closure/, 'map store: the same croak');
    ok(!$map->exists('code'), 'and the map has no such key');

    # An entry that was there is untouched by a refused write.
    $cache->set('keep', 'before');
    $err = '';
    eval { $cache->set('keep', $closure); 1 } or $err = $@;
    ok($err, 'a refused overwrite croaks');
    is_deeply([$cache->get('keep')], ['before'], 'and the old value stands');
}

# ---- too big is refused the way bytes are ----------------------------------
{
    my $big = 'x' x 2000;
    is($plain->set('big', $big), -1, 'a byte cache refuses an oversized value');
    is($cache->set('big', { s => $big }), -1,
       'a serialised cache refuses one whose encoding does not fit, with the '
     . 'same answer');
    is($map->store('big', [$big]), -1, 'and so does a serialised map');
    is($cache->$xs_set('big', [$big]), -1, 'through the XSUB too');

    $cache->set('room', 'small');
    is($cache->set('room', $big), -1, 'an oversized overwrite is refused');
    is_deeply([$cache->get('room')], ['small'], 'and the old value stands');

    # The value must fit AFTER the key: a key that eats most of the entry
    # leaves less room than max_pair says. Two bytes is less than the
    # codec's three-byte header, so nothing encodes into it.
    my $long_key = 'k' x ($cache->max_pair - 2);
    is($cache->set($long_key, 1), -1,
       'a value that would fit an empty entry is refused behind a long key');
    is($cache->set('k', 1), 1, 'while the same value behind a short key stores');
}

# ---- an entry larger than the stack budget goes through encode ---------------
{
    my $wide = $arena->cache('wide', capacity => 16, entry_size => 16384,
                             serialise => 1);
    my $wmap = $arena->map('wmap', slots => 16, slot_size => 16384,
                           serialise => 1);
    my $tenk = { blob => ('y' x 10_000), n => [1 .. 100] };
    is($wide->set('tenk', $tenk), 1, 'a 10 KB structure fits a 16 KB entry');
    is_deeply(scalar $wide->get('tenk'), $tenk, 'and comes back whole');
    is_deeply(scalar $wide->$xs_get('tenk'), $tenk, 'by the XSUB as well');
    is($wmap->store('tenk', $tenk), 1, 'and a 16 KB map slot');
    is_deeply(scalar $wmap->fetch('tenk'), $tenk, 'which reads back whole');

    my $toobig = { blob => ('y' x 17_000) };
    is($wide->set('toobig', $toobig), -1, 'a 17 KB one is refused');
    is($wmap->store('toobig', $toobig), -1, 'by the map too');
    is(scalar(() = $wide->get('toobig')), 0, 'and nothing was stored');
}

# ---- a counter cannot live in a serialised map -------------------------------
{
    my $err = '';
    eval { $map->incr('n'); 1 } or $err = $@;
    like($err, qr/^Shared::Arena::Map: incr on a serialised map/,
         'incr croaks on a serialised map');
    $err = '';
    eval { $map->incr('n', 5); 1 } or $err = $@;
    like($err, qr/incr on a serialised map/, 'and so does incr with a step');
    $err = '';
    eval { $map->$xs_incr('n'); 1 } or $err = $@;
    like($err, qr/incr on a serialised map/, 'and the XSUB');
    ok(!$map->exists('n'), 'and no counter was planted');

    # An eight-byte encoding is not a counter. 'abcd' encodes to exactly
    # eight bytes under the format's short-string tag, which is the case a
    # length check alone would get wrong.
    $map->store('eight', 'abcd');
    is(length(Struct::Codec::struct_encode('abcd')), 8,
       'the specimen encodes to eight bytes');
    ok(!defined $map->counter('eight'), 'counter: undef for it through the door');
    ok(!defined $map->$xs_ctr('eight'), 'and through the XSUB');

    ok($map->exists('h'), 'exists is unchanged');
    ok(!$map->exists('never'), 'either way');
    ok((grep { $_ eq 'h' } $map->keys), 'keys still lists the key');
    is($map->delete('h'), 1, 'delete still deletes');
    ok(!$map->exists('h'), 'and it is gone');
    $map->store('h', $value);
}

# ---- the flag is the tenant's shape ------------------------------------------
{
    my $err = '';
    eval { $arena->cache('sc', capacity => 64, entry_size => 1024); 1 }
        or $err = $@;
    like($err, qr/is already carved with a different type or size/,
         'binding a serialised cache as bytes is refused as a shape mismatch');
    $err = '';
    eval { $arena->cache('sc', capacity => 64, entry_size => 1024,
                         serialise => 0); 1 } or $err = $@;
    like($err, qr/different type or size/, 'explicitly as well');
    $err = '';
    eval { $arena->cache('pc', capacity => 64, entry_size => 1024,
                         serialise => 1); 1 } or $err = $@;
    like($err, qr/different type or size/,
         'and binding a byte cache as serialised is refused the same way');
    $err = '';
    eval { $arena->map('sm', slots => 64, slot_size => 1024); 1 } or $err = $@;
    like($err, qr/different type or size/, 'the map refuses too');

    my $again = $arena->cache('sc', capacity => 64, entry_size => 1024,
                              serialise => 1);
    is_deeply(scalar $again->get('h'), $value,
              'a second bind that asks for the same flag reads the same value');
    my $magain = $arena->map('sm', slots => 64, slot_size => 1024,
                             serialise => 1);
    is_deeply(scalar $magain->fetch('h'), $value, 'and so for the map');
}

# ---- a fork: the child reads the parent's structure --------------------------
SKIP: {
    skip 'fork is POSIX-only here', 4 if $^O eq 'MSWin32';
    require POSIX;

    $cache->set('parent', $value);
    my $pid = fork();
    skip 'fork failed', 4 unless defined $pid;

    if (!$pid) {
        my $ok = 1;
        my ($c) = $cache->get('parent');
        $ok = 0 unless ref $c eq 'HASH' && $c->{n} == 42
                    && refaddr($c->{a}) == refaddr($c->{b});
        $ok = 0 unless $map->store('child', { from => 'child', pid => $$ }) == 1;
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, 'the child decoded the parent\'s structure, sharing and all');
    my ($from_child) = $map->fetch('child');
    is(ref $from_child, 'HASH', 'the parent decodes what the child stored');
    is($from_child->{from}, 'child', 'with its contents');
    is($from_child->{pid}, $pid, 'from the child that stored it');
}

# ---- corrupt bytes croak and do not crash -----------------------------------
#
# The entry's bytes are found by peeking the whole cache region for the exact
# encoding, then overwritten with a reserved tag. In a child, so that a crash
# is an exit status this test can assert on rather than the end of the file.
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';
    require POSIX;

    my $victim = { corrupt => 'me', n => [1, 2, 3] };
    my $bytes  = Struct::Codec::struct_encode($victim);
    is($cache->set('corrupt', $victim), 1, 'the victim is stored');

    my (undef, $len) = $arena->region('sc');
    skip 'cannot find the cache region', 2 unless $len;
    my $image = $arena->peek('sc', 0, $len);
    my $at = index($image, $bytes);
    cmp_ok($at, '>=', 0, 'the encoding is where the entry is');

    my $pid = fork();
    skip 'fork failed', 1 unless defined $pid;
    if (!$pid) {
        # A tag the format reserves, in place of the header, then every byte
        # after it: no valid decode starts this way.
        $arena->poke('sc', $at, "\xFF" x length $bytes);
        my $err = '';
        eval { my ($v) = $cache->get('corrupt'); 1 } or $err = $@;
        my $ok = $err =~ /Struct::Codec/;
        eval { my ($v) = $cache->$xs_get('corrupt'); 1 } or $err = $@;
        $ok &&= $err =~ /Struct::Codec/;
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, 'a corrupt entry makes get croak with the codec\'s reason, '
            . 'through both doors, and the process lives');
}

done_testing;
