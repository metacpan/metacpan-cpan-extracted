#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use lib 't/lib';
use PunkTest;

# The session, on the store.
#
# $c->session keeps working and the hashref behind it comes from a store
# instead of from the cookie. What is proven here is that no application code
# moves, that the round trip is paid only by requests that ask for a session,
# and that a write which did not happen says so.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub dir { "$root/s" . $n++ }

# A store that counts what it is asked to do. The round-trip claims in this
# phase are claims about CALLS, so they are asserted by counting them.
{
    package T::Counting::Store;
    our %C;
    sub new       { my ($c, %o) = @_; bless { h => {}, %o }, $c }
    sub is_shared { 1 }
    sub get       { $C{get}++;    $_[0]{h}{ $_[1] } }
    sub set       { $C{set}++;    return 0 if $_[0]{refuse}; $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete    { $C{delete}++; defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear     { %{ $_[0]{h} } = (); 1 }
    sub stats     { (entries => scalar keys %{ $_[0]{h} }) }
    sub reset     { %C = () }
    package main;
}

sub set_cookie {
    my ($r) = @_;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        return $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return undef;
}
sub cookie_val { my ($sc) = @_; $sc // return; my ($v) = $sc =~ /punk\.sid=([^;]+)/; $v }

# ---- a file store, end to end ------------------------------------------------
my $fdir = dir();
eval qq{
    package SApp;
    use Punk;
    cache 'file', dir => '$fdir';
    session secret => 's3kr3t', expires => '7d', store => 'cache';

    get '/login'  => sub { my \$c = shift; \$c->session->{user_id} = 42;
                           \$c->session->{basket} = [ 1 .. 3 ]; \$c->text('in') };
    get '/me'     => sub { my \$c = shift;
                           \$c->text('me:' . (\$c->session->{user_id} // 'none')) };
    get '/noop'   => sub { my \$c = shift; my \$x = \$c->session->{user_id};
                           \$c->text('read') };
    get '/bump'   => sub { my \$c = shift;
                           \$c->session->{n} = (\$c->session->{n} // 0) + 1;
                           \$c->text('bump') };
    get '/plain'  => sub { \$_[0]->text('plain') };
    1;
} or die $@;

my $app = SApp->to_app;

my $login = hit($app, path => '/login');
my $sc    = set_cookie($login);
my $val   = cookie_val($sc);

ok(defined $val, 'a stored session still sets a cookie on creation');
like($sc, qr/Max-Age=604800/, "and `expires` is still the cookie's Max-Age");
like($sc, qr/HttpOnly/, 'with the attributes the keyword configures');

# The whole point: the payload is not on the wire.
unlike($sc, qr/user_id|basket/,
    'the session contents are NOWHERE in the cookie - it carries an id, and '
  . 'the id is the only thing the client is trusted with');
cmp_ok(length($val), '<', 200,
    'so the cookie is small whatever the session weighs');

{
    my $r = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$val" });
    is($r->[2][0], 'me:42', 'and the session comes back on the next request');
}

# A basket in a session used to be a croak at ~4KB. It is the example the
# documentation leads with, so it is a test.
{
    my $big = 'x' x 40_000;
    eval qq{
        package SBig;
        use Punk;
        cache 'file', dir => '@{[ dir() ]}';
        session secret => 'k', store => 'cache';
        get '/fill' => sub { \$_[0]->session->{blob} = '$big'; \$_[0]->text('filled') };
        get '/read' => sub { \$_[0]->text(length(\$_[0]->session->{blob} // '')) };
        1;
    } or die $@;
    my $a  = SBig->to_app;
    my $r  = hit($a, path => '/fill');
    my $cv = cookie_val(set_cookie($r));
    my $r2 = hit($a, path => '/read', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r2->[2][0], 40_000,
        'a 40KB session round-trips - ten times the ceiling the cookie had');
}

# ---- what a request actually costs -------------------------------------------
{
    eval qq{
        package SCount;
        use Punk;
        session secret => 'k', expires => '1h',
                store  => { backend => 'T::Counting::Store' };

        get '/login' => sub { \$_[0]->session->{user_id} = 7; \$_[0]->text('in') };
        get '/me'    => sub { \$_[0]->text(\$_[0]->session->{user_id} // 'none') };
        get '/plain' => sub { \$_[0]->text('plain') };
        1;
    } or die $@;
    my $a = SCount->to_app;

    T::Counting::Store::reset();
    hit($a, path => '/plain');
    is($T::Counting::Store::C{get}, undef,
        'a route that never touches $c->session performs ZERO store reads - '
      . 'the round trip is paid by the requests that want a session, not by '
      . 'every request');
    is($T::Counting::Store::C{set}, undef, 'and zero writes');

    T::Counting::Store::reset();
    my $cv = cookie_val(set_cookie(hit($a, path => '/login')));
    is($T::Counting::Store::C{set}, 1, 'a login writes once');

    T::Counting::Store::reset();
    my $r = hit($a, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r->[2][0], '7', 'a read gets the session back');
    is($T::Counting::Store::C{get}, 1, 'with one read');
    is($T::Counting::Store::C{set}, undef,
        'and NO write - an unchanged session is what keeps a read-mostly '
      . 'application off the store write path');
    is(set_cookie($r), undef,
        'and no Set-Cookie either: the id in the cookie still names the same '
      . 'session, whatever the session now contains');
}

# ---- a guess never reaches the store -----------------------------------------
# Phase 1 proved the signature refuses a forged id. This is the consequence
# that made the signature worth keeping: the refusal happens BEFORE the lookup,
# so an attacker cannot make the server work by guessing.
{
    eval qq{
        package SGuess;
        use Punk;
        session secret => 'k', store => { backend => 'T::Counting::Store' };
        get '/me' => sub { \$_[0]->text(\$_[0]->session->{user_id} // 'none') };
        1;
    } or die $@;
    my $a = SGuess->to_app;

    T::Counting::Store::reset();
    my $r = hit($a, path => '/me',
                env => { HTTP_COOKIE => 'punk.sid=' . ('a' x 32) });
    is($r->[2][0], 'none', 'a guessed id is not a session');
    is($T::Counting::Store::C{get}, undef,
        'and the store was never asked - the keyspace cannot be probed at the '
      . "store's expense");

    T::Counting::Store::reset();
    hit($a, path => '/me', env => { HTTP_COOKIE => 'punk.sid=not.a.cookie' });
    is($T::Counting::Store::C{get}, undef, 'nor by a malformed one');
}

# ---- an entry that is gone ---------------------------------------------------
# The cookie verifies perfectly and names nothing. That is a logout, an expiry
# or an eviction, and all three have to come out as an empty session rather
# than an error.
{
    eval qq{
        package SGone;
        use Punk;
        session secret => 'k', store => { backend => 'T::Counting::Store' };
        get '/login' => sub { \$_[0]->session->{user_id} = 1; \$_[0]->text('in') };
        get '/me'    => sub { \$_[0]->text(\$_[0]->session->{user_id} // 'none') };
        1;
    } or die $@;
    my $a     = SGone->to_app;
    my $store = SGone->punk_app->{session}{'punk.store'};
    my $cv    = cookie_val(set_cookie(hit($a, path => '/login')));

    $store->clear;
    my $r = hit($a, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r->[2][0], 'none',
        'a valid cookie over a missing entry is an empty session, not a 500');

    # And the id is not revived: a write mints a new one rather than reusing a
    # name whose entry was deleted.
    eval qq{
        package SGone2;
        use Punk;
        session secret => 'k', store => { backend => 'T::Counting::Store' };
        get '/login' => sub { \$_[0]->session->{user_id} = 1; \$_[0]->text('in') };
        get '/again' => sub { \$_[0]->session->{user_id} = 2; \$_[0]->text('in') };
        1;
    } or die $@;
    my $b   = SGone2->to_app;
    my $st2 = SGone2->punk_app->{session}{'punk.store'};
    my $c1  = cookie_val(set_cookie(hit($b, path => '/login')));
    $st2->clear;
    my $r2 = hit($b, path => '/again', env => { HTTP_COOKIE => "punk.sid=$c1" });
    my $c2 = cookie_val(set_cookie($r2));
    ok(defined $c2 && $c2 ne $c1,
        'and a revoked id is never brought back to life as the name of a new '
      . 'session - a fresh one is minted and the client told');
}

# ---- a write that did not happen ---------------------------------------------
# The failure this phase most needs to catch: a store refuses, and the request
# returns 200 as though somebody logged in.
{
    eval qq{
        package SRefuse;
        use Punk;
        session secret => 'k',
                store  => { backend => 'T::Counting::Store', refuse => 1 };
        get '/login' => sub { \$_[0]->session->{user_id} = 9; \$_[0]->text('in') };
        1;
    } or die $@;
    my $a = SRefuse->to_app;

    my @warn;
    my $r = do { local $SIG{__WARN__} = sub { push @warn, @_ }; hit($a, path => '/login') };
    like(join('', @warn), qr/refused the write/,
        'a store that refuses is not ignored - the write-back says so');
    is(set_cookie($r), undef,
        'and no cookie is set, so the client is not handed an id naming '
      . 'nothing');
}

# Over the ceiling. The cookie's ~4KB limit goes; unbounded is not what
# replaces it, because a session an application can grow without limit is a
# way to fill somebody's store from a login form.
{
    eval qq{
        package SHuge;
        use Punk;
        cache 'file', dir => '@{[ dir() ]}', max_bytes => '64M';
        session secret => 'k', store => 'cache';
        get '/huge' => sub { \$_[0]->session->{blob} = 'x' x (2 * 1024 * 1024);
                             \$_[0]->text('tried') };
        1;
    } or die $@;
    my $a = SHuge->to_app;

    my @warn;
    my $r = do { local $SIG{__WARN__} = sub { push @warn, @_ }; hit($a, path => '/huge') };
    like(join('', @warn), qr/over the 1048576-byte limit/,
        'a session over the ceiling is refused, with both numbers in the '
      . 'message');
    is(set_cookie($r), undef, 'and nothing is saved');
}

# ---- flash, over a store -----------------------------------------------------
# The case where the session changes on a request the handler thought was
# read-only: reading the inbound flash moves it out of the session.
{
    eval qq{
        package SFlash;
        use Punk;
        cache 'file', dir => '@{[ dir() ]}';
        session secret => 'k', store => 'cache';
        get '/set'  => sub { \$_[0]->flash(notice => 'Saved.'); \$_[0]->text('set') };
        get '/read' => sub { \$_[0]->text(\$_[0]->flash('notice') // 'empty') };
        1;
    } or die $@;
    my $a  = SFlash->to_app;
    my $cv = cookie_val(set_cookie(hit($a, path => '/set')));
    ok(defined $cv, 'a flash on an anonymous visitor creates a session');

    my $r1 = hit($a, path => '/read', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r1->[2][0], 'Saved.', 'the flash is readable on the NEXT request');
    is(set_cookie($r1), undef,
        'and consuming it writes the store, not the cookie - the id has not '
      . 'changed');

    my $r2 = hit($a, path => '/read', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r2->[2][0], 'empty', 'and it is gone on the one after');
}

# ---- login_as, against a store -----------------------------------------------
# Punk::Test signs a user straight into the jar. It used to seal the session
# INTO the cookie, which is no session at all to an application with a store -
# so every suite using it would have broken the day its application gained one.
{
    eval qq{
        package SAuth;
        use Punk;
        cache 'file', dir => '@{[ dir() ]}';
        session secret => 'k', store => 'cache';
        get '/me' => sub { \$_[0]->text(\$_[0]->session->{user_id} // 'none') };
        1;
    } or die $@;

    require Punk::Test;
    my $t = Punk::Test->new('SAuth');
    $t->login_as(99);
    $t->get_ok('/me');
    $t->content_is('99',
        'login_as reaches a guarded page on a store-backed application, '
      . 'because the session was written where the application looks for it');
    SKIP: {
        skip 'needs MIME::Base64 to read the cookie payload', 1
            unless eval { require MIME::Base64; 1 };
        # Asserted on the DECODED claims rather than by searching the cookie
        # for "99". The cookie's second half is an HMAC - 43 characters of
        # base64url that contain any given pair of digits often enough to fail
        # a run on nothing, which is what a 5.12 smoker did here on "Aum99w".
        my ($p) = split /\./, $t->{jar}{'punk.sid'}, 2;
        $p =~ tr{-_}{+/};
        $p .= '=' x ((4 - length($p) % 4) % 4);
        my $claims = MIME::Base64::decode_base64($p);
        unlike($claims, qr/user_id/,
            'with the id in the cookie and nothing else');
    }

    # Sealing before the application is compiled is the one way this can be
    # wrong, and it is now an error rather than a cookie the compiled
    # application would not recognise.
    eval qq{
        package SUncompiled;
        use Punk;
        cache 'file', dir => '@{[ dir() ]}';
        session secret => 'k', store => 'cache';
        1;
    } or die $@;
    my $err = do {
        local $@;
        eval { Punk::Session::_seal_session(SUncompiled->punk_app, { u => 1 }) };
        $@;
    };
    like($err, qr/has not been compiled yet/,
        'sealing before to_app says which mistake it is');
}

# ---- the cookie session is untouched -----------------------------------------
{
    package SPlain;
    use Punk;
    session secret => 'k', expires => '7d';
    get '/login' => sub { $_[0]->session->{user_id} = 5; $_[0]->text('in') };
    package main;

    my $a  = SPlain->to_app;
    my $sc = set_cookie(hit($a, path => '/login'));
    like($sc, qr/punk\.sid=[\w-]+\.[\w-]+/,
        'an application that did not ask for a store still carries its '
      . 'session in the cookie, exactly as before');
}

done_testing;
