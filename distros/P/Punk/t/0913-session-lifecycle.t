#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use Test::More;
use lib 't/lib';
use PunkTest;

# The three moments a server-side session has that a cookie one cannot: being
# reissued, being revoked, and being kept alive.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub dir { "$root/s" . $n++ }

{
    package T::Store;
    sub new       { my ($c, %o) = @_; bless { h => {}, %o }, $c }
    sub is_shared { 1 }
    sub get       { $_[0]{h}{ $_[1] } }
    sub set       { $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete    { defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear     { %{ $_[0]{h} } = (); 1 }
    sub stats     { (entries => scalar keys %{ $_[0]{h} }) }
    sub keys_     { keys %{ $_[0]{h} } }
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
sub entries    { my ($app) = @_; scalar $app->punk_app->{session}{'punk.store'}->backend->keys_ }

# ---- rotation ----------------------------------------------------------------
{
    package RApp;
    use Punk;
    session secret => 'k', expires => '7d', store => { backend => 'T::Store' };

    # a session that exists before any login, which is what an attacker plants
    get '/visit' => sub { $_[0]->session->{seen} = 1; $_[0]->text('hi') };

    get '/login' => sub {
        my ($c) = @_;
        $c->session_rotate;
        $c->session->{user_id} = 42;
        $c->text('in');
    };
    get '/me' => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    get '/seen' => sub { $_[0]->text($_[0]->session->{seen} // 'no') };
    package main;

    my $app = RApp->to_app;

    my $c1 = cookie_val(set_cookie(hit($app, path => '/visit')));
    ok(defined $c1, 'an anonymous visit creates a session');
    is(entries('RApp'), 1, 'one entry in the store');

    my $r  = hit($app, path => '/login', env => { HTTP_COOKIE => "punk.sid=$c1" });
    my $c2 = cookie_val(set_cookie($r));
    ok(defined $c2, 'logging in with a rotation sets a new cookie');
    isnt($c2, $c1, 'a different one');
    is(entries('RApp'), 1,
        'and the store still holds ONE session - the old entry went with the '
      . 'old id, rather than being left to expire on its own');

    my $after = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$c2" });
    is($after->[2][0], '42', 'the new id names the logged-in session');

    my $seen = hit($app, path => '/seen', env => { HTTP_COOKIE => "punk.sid=$c2" });
    is($seen->[2][0], '1',
        'and the session CONTENTS survived the rotation - it is the same '
      . 'session under a new name, not a new session');

    # The attack, end to end.
    my $planted = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$c1" });
    is($planted->[2][0], 'none',
        'the id that was planted before the login resolves to nothing after '
      . 'it - which is the whole reason rotation exists');
}

# Rotating an unchanged session still writes it under the new name. Without
# that, the dirty check would skip the write and the new id would name nothing.
{
    package RQuiet;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    get '/start'  => sub { $_[0]->session->{a} = 1; $_[0]->text('s') };
    get '/rotate' => sub { $_[0]->session_rotate; $_[0]->text('r') };
    get '/read'   => sub { $_[0]->text($_[0]->session->{a} // 'none') };
    package main;

    my $app = RQuiet->to_app;
    my $c1  = cookie_val(set_cookie(hit($app, path => '/start')));
    my $r   = hit($app, path => '/rotate', env => { HTTP_COOKIE => "punk.sid=$c1" });
    my $c2  = cookie_val(set_cookie($r));

    ok(defined $c2 && $c2 ne $c1, 'a rotation that changes nothing still reissues');
    my $read = hit($app, path => '/read', env => { HTTP_COOKIE => "punk.sid=$c2" });
    is($read->[2][0], '1',
        'and the session is there under the new id - a rotation that skipped '
      . 'the write would have handed out a name for nothing');
}

# Rotating a brand-new session is the ordinary login case: there is no old id
# to retire, and it must not be an error.
{
    package RFresh;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    get '/login' => sub { $_[0]->session_rotate;
                          $_[0]->session->{user_id} = 7; $_[0]->text('in') };
    get '/me'    => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    package main;

    my $app = RFresh->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));
    ok(defined $cv, 'rotating a session that did not exist yet is fine');
    my $r = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r->[2][0], '7', 'and the login lands');
}

# Without a store there is nothing to rotate, and that is a no-op rather than
# an error: a cookie session's value changes wholesale when its contents do.
{
    package RCookie;
    use Punk;
    session secret => 'k', expires => '7d';
    get '/login' => sub { $_[0]->session_rotate;
                          $_[0]->session->{user_id} = 3; $_[0]->text('in') };
    get '/me'    => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    package main;

    my $app = RCookie->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));
    ok(defined $cv, 'session_rotate on a cookie session does not die');
    my $r = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r->[2][0], '3', 'and the session still works');
}

# ---- revocation --------------------------------------------------------------
# The headline. A signed cookie is good until it expires no matter what the
# server thinks; an entry can be deleted.
{
    package XApp;
    use Punk;
    session secret => 'k', expires => '7d', store => { backend => 'T::Store' };
    get '/login'  => sub { $_[0]->session->{user_id} = 5; $_[0]->text('in') };
    get '/me'     => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    get '/logout' => sub { $_[0]->session_expire; $_[0]->text('out') };
    package main;

    my $app = XApp->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));
    is(entries('XApp'), 1, 'a login leaves an entry');

    my $out = hit($app, path => '/logout', env => { HTTP_COOKIE => "punk.sid=$cv" });
    like(set_cookie($out), qr/punk\.sid=;|punk\.sid=""|Max-Age=0|Expires=/,
        'logging out still tells the browser to drop the cookie');
    is(entries('XApp'), 0,
        'and DELETES the entry - the route never read $c->session, so the id '
      . 'came from the cookie rather than from the stash');

    # The copy somebody already took.
    my $stolen = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($stolen->[2][0], 'none',
        'a cookie captured before the logout is dead on its next request - '
      . 'this is the sentence Punk::Session could not say before');
}

# $c->logout (the auth battery) goes through session_expire, so it revokes too.
{
    package XAuth;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    get '/login'  => sub { $_[0]->session->{user_id} = 1; $_[0]->text('in') };
    get '/logout' => sub { $_[0]->session_expire; $_[0]->text('out') };
    package main;

    my $app = XAuth->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));
    hit($app, path => '/logout', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is(entries('XAuth'), 0, 'a logout on a session that was never read revokes');
}

# ---- sliding expiry ----------------------------------------------------------
# Off by default: an active session expires a fixed period after it was
# created, which is what the cookie session does when nothing writes to it.
{
    package SOff;
    use Punk;
    session secret => 'k', expires => '2s', store => { backend => 'T::Store' };
    get '/touch' => sub { $_[0]->session->{a} //= 1; $_[0]->text('t') };
    package main;

    my $app = SOff->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/touch')));
    my $r   = hit($app, path => '/touch', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is(set_cookie($r), undef,
        'with sliding off, a read of an unchanged session writes nothing and '
      . 'reissues nothing');
}

# On, and throttled. The stamp inside the payload is what makes "how far
# through its life is this session" answerable without a sixth method on the
# backend contract.
{
    package SOn;
    use Punk;
    session secret  => 'k',
            expires => '1h',
            sliding => 1,
            store   => { backend => 'T::Store' };
    get '/touch' => sub { $_[0]->session->{a} //= 1; $_[0]->text('t') };
    package main;

    my $app = SOn->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/touch')));
    my $id1 = Punk::Session::_unseal_id(SOn->punk_app, $cv);
    my $st  = SOn->punk_app->{session}{'punk.store'};

    my $early = hit($app, path => '/touch', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is(set_cookie($early), undef,
        'a request early in the lifetime does NOT slide - sliding on every '
      . 'request would be a store write per request, which is the cost the '
      . 'read path was designed to avoid');

    # Age the session by moving its stamp back, rather than by sleeping
    # through half an hour. This is also the clearest statement of how the
    # throttle works: the answer to "how far through its life is this
    # session" is one integer in the payload, which is why the backend
    # contract did not need a sixth method.
    {
        my $raw = $st->get($id1);
        like($raw, qr/"punk\.at":\d+/, 'the entry carries its write stamp');
        my $old = time - 2000;                  # past half of an hour
        $raw =~ s/"punk\.at":\d+/"punk.at":$old/;
        $st->set($id1, $raw, 3600);
    }

    my $late = hit($app, path => '/touch', env => { HTTP_COOKIE => "punk.sid=$cv" });
    my $c2   = cookie_val(set_cookie($late));
    ok(defined $c2,
        'past the throttle point it slides, and reissues the COOKIE as well '
      . 'as rewriting the entry - a cookie that ran out while its entry lived '
      . 'would be exactly the logout sliding exists to prevent');

    is(Punk::Session::_unseal_id(SOn->punk_app, $c2), $id1,
        'and it is the SAME id inside - sliding moves the expiry, it does not '
      . 'rotate');

    # The stamp inside the reissued cookie is counted from now. Both writes
    # land in the same second here, so it can equal the original rather than
    # exceed it - what must never happen is it going backwards.
    SKIP: {
        eval { require MIME::Base64; 1 } or skip 'MIME::Base64', 1;
        my $stamp = sub {
            my ($p) = split /\./, $_[0];
            $p =~ tr{-_}{+/};
            $p .= '=' x ((4 - length($p) % 4) % 4);
            my ($e) = MIME::Base64::decode_base64($p) =~ /"punk\.exp":(\d+)/;
            return $e;
        };
        cmp_ok($stamp->($c2), '>=', $stamp->($cv),
            'with an expiry counted from the slide, not inherited from the '
          . 'original write');
    }

    like($st->get($id1), qr/"punk\.at":\d+/, 'the entry is still there');
    my ($at) = $st->get($id1) =~ /"punk\.at":(\d+)/;
    cmp_ok($at, '>', time - 5, 'with a fresh stamp, so it will not slide again');
}

# ---- the reserved stamp never reaches the application ------------------------
{
    package SKeys;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    get '/set'  => sub { $_[0]->session->{user_id} = 1; $_[0]->text('s') };
    get '/keys' => sub { $_[0]->text(join ',', sort keys %{ $_[0]->session }) };
    package main;

    my $app = SKeys->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/set')));
    my $r   = hit($app, path => '/keys', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($r->[2][0], 'user_id',
        'the write stamp is stripped before the application sees the hash, '
      . 'like the expiry the cookie carries');

    # And it does not make every request look dirty.
    my $again = hit($app, path => '/keys', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is(set_cookie($again), undef,
        'so a read-only request is still a read-only request');
}

done_testing;
