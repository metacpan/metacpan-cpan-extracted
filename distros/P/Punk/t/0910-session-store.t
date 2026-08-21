#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use lib 't/lib';

# `session store => ...`: where a server-side session lives.
#
# This is the resolution half - the store the session will use is chosen and
# checked AT BOOT. Nothing here reads or writes a session yet; what is proven
# is that every form of `store` reaches a Punk::Cache handle, that the
# configurations which would fail later as a random logout fail here instead,
# and that a backend nobody in this distribution wrote is a first-class option.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n    = 0;
sub dir { "$root/s" . $n++ }

# A store from outside this distribution, shared between workers. Written from
# the documented five-method contract and nothing else: if a session can be
# configured onto this, "the store is a seam" is a tested claim.
{
    package T::Shared::Store;
    sub new       { my ($c, %o) = @_; bless { h => {}, %o }, $c }
    sub is_shared { 1 }
    sub get       { $_[0]{h}{ $_[1] } }
    sub set       { $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete    { defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear     { %{ $_[0]{h} } = (); 1 }
    sub stats     { (entries => scalar keys %{ $_[0]{h} }) }
    package main;
}

sub store_of { $_[0]->punk_app->{session}{'punk.store'} }

# ---- absent: the cookie session, exactly as before ---------------------------
{
    package SS::None;
    use Punk;
    session secret => 'k', expires => '7d';
    get '/' => sub { $_[0]->text('ok') };
    package main;

    SS::None->to_app;
    is(store_of('SS::None'), undef,
        'no `store` leaves the session in the cookie - the default is what '
      . 'every existing application already has');
}

# ---- 'cache': the default store ---------------------------------------------
# `default` is the name it is built under internally, and nobody should have to
# know that. An application with one store calls it the cache.
{
    my $d = dir();
    eval qq{
        package SS::Default;
        use Punk;
        cache 'file', dir => '$d';
        session secret => 'k', store => 'cache';
        1;
    } or die \$@;

    SS::Default->to_app;
    my $store = store_of('SS::Default');
    isa_ok($store, 'Punk::Cache', "store => 'cache' resolves to a store");
    isa_ok($store->backend, 'Punk::Cache::File', 'the default one');
    is($store, SS::Default->punk_app->{cache}{default},
        'and it is the SAME handle the application caches through, not a '
      . 'second store over the same directory');
}

# ---- a named store -----------------------------------------------------------
# The ordering this proves: the session resolves AFTER the cache keyword's
# stores are built. Resolve first and this name looks like a typo.
{
    my ($d1, $d2) = (dir(), dir());
    eval qq{
        package SS::Named;
        use Punk;
        cache 'file', dir => '$d1';
        cache sessions => { backend => 'file', dir => '$d2' };
        session secret => 'k', store => 'sessions';
        1;
    } or die \$@;

    SS::Named->to_app;
    is(store_of('SS::Named'), SS::Named->punk_app->{cache}{sessions},
        'a name resolves to the store declared under it');
    isnt(store_of('SS::Named'), SS::Named->punk_app->{cache}{default},
        'and not to the default one, which is the whole point of naming it - '
      . 'a page store must not evict sessions to stay under its budget');
}

# ---- a hashref: built privately ----------------------------------------------
{
    package SS::Inline;
    use Punk;
    session secret => 'k',
            store  => { backend => 'T::Shared::Store', max_bytes => '4M' };
    package main;

    SS::Inline->to_app;
    my $store = store_of('SS::Inline');
    isa_ok($store, 'Punk::Cache', 'a hashref builds a store');
    isa_ok($store->backend, 'T::Shared::Store',
        'on a backend from outside this distribution, with no `cache` keyword '
      . 'anywhere - the seam is real');
    is(SS::Inline->punk_app->{cache}, undef,
        'and it is the SESSION store, not a cache the application can reach '
      . 'through $c->cache');
}

# ---- an object ---------------------------------------------------------------
{
    package SS::Object;
    use Punk;
    session secret => 'k', store => T::Shared::Store->new(tag => 'mine');
    package main;

    SS::Object->to_app;
    is(store_of('SS::Object')->backend->{tag}, 'mine',
        'the OBJECT handed to the keyword is the one that ends up in the app, '
      . 'with its own configuration intact');
}

# ---- what is refused at boot -------------------------------------------------

# A name that was never declared. A session store that silently never hits
# looks like a working login page that forgets everybody.
{
    my $d = dir();
    my $err = do {
        local $@;
        eval qq{
            package SS::Missing;
            use Punk;
            cache 'file', dir => '$d';
            session secret => 'k', store => 'nosuch';
            SS::Missing->to_app;
            1;
        };
        $@;
    };
    like($err, qr/never\s+declared/,
        'an undeclared store name is refused at boot');
    like($err, qr/nosuch/, 'naming the store it looked for');
}

# No stores at all - the likeliest version of the same mistake.
{
    my $err = do {
        local $@;
        eval q{
            package SS::NoCache;
            use Punk;
            session secret => 'k', store => 'cache';
            SS::NoCache->to_app;
            1;
        };
        $@;
    };
    like($err, qr/declares none|add a `cache` keyword/,
        'pointing at "the cache" when there is no cache says so');
}

# `store:` in a config file with nothing after it. Absent is a decision;
# empty is a line somebody meant to fill in.
{
    my $err = do {
        local $@;
        eval q{
            package SS::Empty;
            use Punk;
            session secret => 'k', store => '';
            SS::Empty->to_app;
            1;
        };
        $@;
    };
    like($err, qr/`session store` is empty/,
        'an empty store is a boot croak, not a quiet fall back to the cookie');
}

# `cache` is reserved for the default store, so a store actually declared under
# that name is an ambiguity. Refused, naming both readings, rather than guessed.
{
    my ($d1, $d2) = (dir(), dir());
    my $err = do {
        local $@;
        eval qq{
            package SS::Collide;
            use Punk;
            cache 'file', dir => '$d1';
            cache cache => { backend => 'file', dir => '$d2' };
            session secret => 'k', store => 'cache';
            SS::Collide->to_app;
            1;
        };
        $@;
    };
    like($err, qr/DEFAULT store/,
        'a store named `cache` collides with the reserved spelling');
    like($err, qr/rename/, 'and the message says what to do about it');
}

# A store that is not shared between workers. Under a prefork pool this is not
# staleness: the session written on worker A is ABSENT on worker B, so the user
# is logged out on whichever request the pool sends elsewhere.
{
    my $err = do {
        local $@;
        eval q{
            package SS::Unshared;
            use Punk;
            cache 'memory', max_bytes => '1M';
            session secret => 'k', store => 'cache';
            SS::Unshared->to_app;
            1;
        };
        $@;
    };
    like($err, qr/not shared between workers/,
        'an unshared store is refused at boot');
    like($err, qr/allow_unshared/,
        'and the message names the escape, because a single process is a real '
      . 'configuration');
}

# The escape, for the one-process case.
{
    package SS::Single;
    use Punk;
    cache 'memory', max_bytes => '1M';
    session secret => 'k', store => 'cache', allow_unshared => 1;
    package main;

    SS::Single->to_app;
    isa_ok(store_of('SS::Single')->backend, 'Punk::Cache::Memory',
        'allow_unshared => 1 permits a per-process store');
}

# ---- the keyword stopped accepting anything it is given ----------------------
# It used to copy every pair straight into the config, so a typo was silent.
# Survivable while every option was a cookie attribute with a safe default;
# not survivable for `store`, where the typo's failure is "everything works and
# the store stays empty".
{
    my $err = do {
        local $@;
        eval q{
            package SS::Typo;
            use Punk;
            session secret => 'k', stores => 'cache';
            1;
        };
        $@;
    };
    like($err, qr/does not understand `stores`/,
        'a misspelt `store` croaks at boot instead of quietly being a cookie '
      . 'session');
    like($err, qr/\bstore\b/, 'listing the options it does take');

    $err = do {
        local $@;
        eval q{
            package SS::Typo2;
            use Punk;
            session secret => 'k', htponly => 1;
            1;
        };
        $@;
    };
    like($err, qr/does not understand `htponly`/,
        'and the same for a cookie attribute, which was silent before');
}

# The options it does take still work, all of them, in both call forms.
{
    package SS::AllOpts;
    use Punk;
    session {
        secret   => 'k',
        cookie   => 'app.sid',
        expires  => '1h',
        path     => '/app',
        domain   => 'example.com',
        secure   => 1,
        httponly => 1,
        samesite => 'Strict',
    };
    package main;

    my $cfg = SS::AllOpts->punk_app->{session};
    is($cfg->{cookie}, 'app.sid', 'the hashref form still takes every option');
    is($cfg->{max_age}, 3600, "and `expires` still becomes seconds");
}

done_testing;
