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

done_testing;
