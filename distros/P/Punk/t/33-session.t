#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# Signed cookie sessions: round-trip, tamper rejection, dirty write-back, expiry,
# and (when Digest::SHA is present) a cross-check that the bundled HMAC-SHA256 is
# byte-correct.

{
    package SApp;
    use Punk;
    session secret => 's3kr3t', expires => '7d';
    get '/login'  => sub { my $c = shift; $c->session->{user_id} = 42; $c->text('in') };
    get '/me'     => sub { my $c = shift; $c->text('me:' . ($c->session->{user_id} // 'none')) };
    get '/noop'   => sub { my $c = shift; my $x = $c->session->{user_id}; $c->text('read') };
    get '/bump'   => sub { my $c = shift; $c->session->{n} = ($c->session->{n} // 0) + 1; $c->text('bump') };
    get '/logout' => sub { my $c = shift; $c->session_expire; $c->text('out') };
    get '/plain'  => sub { my $c = shift; $c->text('plain') };
    package main;
}

my $app = SApp->to_app;
sub set_cookie {
    my ($r) = @_;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        return $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return undef;
}
sub cookie_val { my ($sc) = @_; $sc // return; my ($v) = $sc =~ /punk\.sid=([^;]+)/; $v }

my $login = hit($app, path => '/login');
my $sc = set_cookie($login);
like($sc, qr/^punk\.sid=\S+\.\S+;/, 'login sets a signed session cookie');
like($sc, qr/Max-Age=604800/, "expires => '7d' becomes a week of Max-Age");
like($sc, qr/HttpOnly/, 'HttpOnly by default');
my $val = cookie_val($sc);

SKIP: {
    skip 'Digest::SHA / MIME::Base64 for the crypto cross-check', 1
        unless eval { require Digest::SHA; require MIME::Base64; 1 };
    my ($b64p, $sig) = split /\./, $val, 2;
    # encode_base64url arrived in MIME::Base64 3.11; older smokers have the
    # module but not the function, and the require guard above cannot see the
    # difference. Derive it from encode_base64 so the cross-check still runs
    # there instead of dying.
    my $expect = MIME::Base64::encode_base64(
        Digest::SHA::hmac_sha256($b64p, 's3kr3t'), '');
    $expect =~ tr{+/}{-_};
    $expect =~ s/=+$//;
    is($sig, $expect, 'the bundled HMAC-SHA256 matches Digest::SHA byte for byte');
}

my $me = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$val" });
is($me->[2][0], 'me:42', 'the session round-trips through the cookie');

(my $bad = $val) =~ s/(.)$/ $1 eq 'A' ? 'B' : 'A' /e;
my $t = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$bad" });
is($t->[2][0], 'me:none', 'a tampered cookie is rejected (empty session)');

my $noop = hit($app, path => '/noop', env => { HTTP_COOKIE => "punk.sid=$val" });
is(set_cookie($noop), undef, 'an unchanged session writes no Set-Cookie');

my $bump = hit($app, path => '/bump', env => { HTTP_COOKIE => "punk.sid=$val" });
ok(set_cookie($bump), 'a changed session is written back');

my $out = hit($app, path => '/logout', env => { HTTP_COOKIE => "punk.sid=$val" });
like(set_cookie($out), qr/punk\.sid=; .*Max-Age=0/, 'session_expire deletes the cookie');

is(set_cookie(hit($app, path => '/plain')), undef,
    'a request that never touches the session sets no cookie');

# a session too large for a signed cookie is dropped (with a warning), never
# silently truncated
{
    package BigApp;
    use Punk;
    session secret => 'k';
    get '/big' => sub { my $c = shift; $c->session->{blob} = 'x' x 5000; $c->text('ok') };
    package main;
    my $big = BigApp->to_app;
    my @warn; local $SIG{__WARN__} = sub { push @warn, "@_" };
    my $r = hit($big, path => '/big');
    is($r->[0], 200, 'the request still succeeds');
    is(set_cookie($r), undef, 'the over-4KB session is not written to a cookie');
    ok((grep { /too large/ } @warn), 'and it warns rather than truncating');
}

# A session with no secret used to sign with an empty HMAC key, which anyone
# who knew the cookie format could reproduce offline - a forged cookie
# carrying any user id or role the application trusts (CVE-2026-75870).
# Nothing looked wrong at runtime, so the keyword refuses at boot instead.
{
    my $n = 0;
    for my $decl ('session expires => "7d"',       # omitted entirely
                  'session secret => undef',       # present but undefined
                  'session secret => ""',          # present but empty
                  'session { expires => "7d" }',   # the hashref form
                  'session { secret => "" }') {
        my $pkg = 'NoSecretApp' . $n++;
        my $ok = eval "package $pkg; use Punk; $decl; 1";
        my $err = $@;
        ok(!$ok, "refused at boot: $decl");
        like($err, qr/non-empty secret/, 'and says what is wrong');
    }

    # the same declarations with a real secret are still fine, in both forms
    ok(eval 'package YesSecretA; use Punk; session secret => "k", expires => "7d"; 1',
        'a non-empty secret is accepted');
    ok(eval 'package YesSecretB; use Punk; session { secret => "k" }; 1',
        'in the hashref form too');
}

# The lifetime is the server's, not the browser's. `expires` used to set only
# Max-Age, which is a request to a client that is free to ignore it: the
# signature carried no time, so a cookie captured once was good until the
# secret changed. The expiry now rides inside the signed payload.
{
    package ExpApp;
    use Punk;
    session secret => 'k', expires => '7d';
    get '/in' => sub { my $c = shift; $c->session->{uid} = 42; $c->text('in') };
    get '/me' => sub { my $c = shift;
        $c->text('uid:' . ($c->session->{uid} // 'none')
               . ' keys:' . join(',', sort keys %{ $c->session })) };
    get '/noop' => sub { my $c = shift; my $x = $c->session->{uid}; $c->text('read') };
    package main;

    my $ea = ExpApp->to_app;
    my $login = hit($ea, path => '/in');
    my ($val) = set_cookie($login) =~ /punk\.sid=([^;]+)/;

    my $me = hit($ea, path => '/me', env => { HTTP_COOKIE => "punk.sid=$val" });
    is($me->[2][0], 'uid:42 keys:uid', 'the session round-trips');
    # the stamp is ours: the application must never see it in its own hash
    unlike($me->[2][0], qr/punk\.exp/, 'the expiry is not visible to the app');

    # and stripping it must not make every request look dirty
    is(set_cookie(hit($ea, path => '/noop', env => { HTTP_COOKIE => "punk.sid=$val" })),
        undef, 'an unchanged session still writes no cookie');

    SKIP: {
        skip 'needs Digest::SHA and MIME::Base64', 3
            unless eval { require Digest::SHA; require MIME::Base64; 1 };
        # mint payloads by hand so the clock does not have to move
        my $mint = sub {
            my ($exp) = @_;
            my $p = MIME::Base64::encode_base64url(qq({"punk.exp":$exp,"uid":42}), '');
            return "$p." . MIME::Base64::encode_base64url(
                Digest::SHA::hmac_sha256($p, 'k'), '');
        };
        my $uid = sub {
            my ($cookie) = @_;
            hit($ea, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cookie" })->[2][0];
        };
        like($uid->($mint->(time + 3600)), qr/^uid:42/, 'an unexpired payload loads');
        like($uid->($mint->(time - 1)),    qr/^uid:none/, 'one second past expiry does not');
        like($uid->($mint->(time - 86400)), qr/^uid:none/, 'nor does a day past it');
    }

    # a session cookie with no `expires` is still bounded: "until the browser
    # closes" is the client's promise, not a limit on the value
    {
        package NoExpApp;
        use Punk;
        session secret => 'k';
        get '/in' => sub { my $c = shift; $c->session->{uid} = 1; $c->text('in') };
        package main;
        my ($v) = set_cookie(hit(NoExpApp->to_app, path => '/in')) =~ /punk\.sid=([^;]+)/;
        my ($payload) = split /\./, $v;
        SKIP: {
            skip 'needs MIME::Base64', 1 unless eval { require MIME::Base64; 1 };
            like(MIME::Base64::decode_base64url($payload), qr/punk\.exp/,
                'a browser-session cookie is still stamped with an expiry');
        }
    }
}

done_testing;
