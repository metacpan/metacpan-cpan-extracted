#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# The session at the privilege boundary: what a login does to a stored id,
# what an anonymous request may leave behind, and what the cookie says about
# the transport it was set on.

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

sub set_cookies {
    my ($r) = @_;
    my @c;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        push @c, $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return @c;
}
sub sid {
    my ($r) = @_;
    for (set_cookies($r)) { return $1 if /\Apunk\.sid=([^;]*)/ }
    return undef;
}
sub with    { my ($v) = @_; return { HTTP_COOKIE => "punk.sid=$v" } }
sub entries {
    my ($pkg) = @_;
    return scalar $pkg->punk_app->{session}{'punk.store'}->backend->keys_;
}

# ---- a login renames a stored session -----------------------------------------

{
    package Fix;
    use Punk;
    session secret => 'k', expires => '7d', store => { backend => 'T::Store' };
    auth model => 'users';
    get  '/visit'  => sub { $_[0]->session->{seen} = 1; $_[0]->text('hi') };
    post '/login'  => sub { $_[0]->login(42); $_[0]->text('in') };
    post '/twice'  => sub { $_[0]->session_rotate->login(42)->session_rotate;
                            $_[0]->text('in') };
    get  '/me'     => sub { $_[0]->text($_[0]->auth_id // 'none') };
    get  '/seen'   => sub { $_[0]->text($_[0]->session->{seen} // 'no') };
    package main;
}
{
    my $app = Fix->to_app;
    my $planted = sid(hit($app, path => '/visit'));
    ok(defined $planted && length $planted, 'a visitor is given an id');
    is(entries('Fix'), 1, 'and one store entry');

    my $r = hit($app, method => 'POST', path => '/login', env => with($planted));
    my $fresh = sid($r);
    ok(defined $fresh && length $fresh, 'logging in on it issues a cookie');
    isnt($fresh, $planted, 'which names a different id');
    is(entries('Fix'), 1, 'the entry under the old id is gone');

    is(hit($app, path => '/me', env => with($planted))->[2][0], 'none',
        'the id held before the login signs nobody in');
    is(hit($app, path => '/me', env => with($fresh))->[2][0], '42',
        'the new one does');
    is(hit($app, path => '/seen', env => with($fresh))->[2][0], '1',
        'and the session kept what it held');

    my $again = hit($app, path => '/me', env => with($fresh));
    is(sid($again), undef, 'a later request is not renamed again');

    my $t = hit($app, method => 'POST', path => '/twice', env => with($fresh));
    my $third = sid($t);
    isnt($third, $fresh, 'rotating around a login still renames');
    is(entries('Fix'), 1, '...and still retires the id the request came with');
    is(hit($app, path => '/me', env => with($fresh))->[2][0], 'none',
        'which no longer signs in');
}

# ---- an anonymous denial leaves nothing behind --------------------------------

{
    package Flood;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    auth model => 'users';
    csrf;
    my $acct = under '/account' => auth_guard;
    $acct->get('/home' => sub { $_[0]->text('home') });
    post '/save' => sub { $_[0]->text('saved') };
    get  '/peek' => sub { $_[0]->session; $_[0]->text('peek') };
    get  '/note' => sub { $_[0]->session->{n} = 1; $_[0]->text('note') };
    get  '/wipe' => sub { %{ $_[0]->session } = (); $_[0]->text('wipe') };
    get  '/turn' => sub { $_[0]->session_rotate; $_[0]->text('turn') };
    package main;
}
{
    my $app = Flood->to_app;
    for (1 .. 5) {
        my $r = hit($app, path => '/account/home',
                    env => { HTTP_ACCEPT => 'text/html' });
        is($r->[0], 302, 'an anonymous guarded GET is denied') if $_ == 1;
        is(sid($r), undef, '...with no session cookie') if $_ == 1;
    }
    for (1 .. 5) {
        my $r = hit($app, method => 'POST', path => '/save', body => 'a=1',
                    type => 'application/x-www-form-urlencoded');
        is($r->[0], 403, 'a cookieless POST is refused by csrf') if $_ == 1;
        is(sid($r), undef, '...with no session cookie') if $_ == 1;
    }
    is(sid(hit($app, path => '/peek')), undef,
        'reading an empty session sets no cookie');
    is(entries('Flood'), 0, 'and none of it reached the store');

    my $id = sid(hit($app, path => '/note'));
    ok(defined $id, 'a session that holds something is stored');
    is(entries('Flood'), 1, '...as one entry');
    is(sid(hit($app, path => '/wipe', env => with($id))), undef,
        'emptying it keeps the id');
    is(entries('Flood'), 1, '...and writes the empty session over the old one');
    ok(defined sid(hit($app, path => '/turn')),
        'a rotation writes even an empty session');
}

# ---- the cookie session, the same two ways ------------------------------------

{
    package Plain;
    use Punk;
    session secret => 'k';
    auth model => 'users';
    get  '/peek'   => sub { $_[0]->session; $_[0]->text('peek') };
    get  '/note'   => sub { $_[0]->session->{n} = 1; $_[0]->text('note') };
    get  '/wipe'   => sub { %{ $_[0]->session } = (); $_[0]->text('wipe') };
    post '/login'  => sub { $_[0]->login(1); $_[0]->text('in') };
    post '/switch' => sub { $_[0]->logout->login(7); $_[0]->text('switched') };
    get  '/me'     => sub { $_[0]->text($_[0]->auth_id // 'none') };
    package main;
}
{
    my $app = Plain->to_app;
    is(sid(hit($app, path => '/peek')), undef,
        'cookie session: reading an empty one sets no cookie');
    my $v = sid(hit($app, path => '/note'));
    ok(defined $v, 'cookie session: a write sets one');
    my $w = sid(hit($app, path => '/wipe', env => with($v)));
    ok(defined $w && $w ne $v, 'cookie session: emptying it is still a write');

    my $one = sid(hit($app, method => 'POST', path => '/login'));
    my $r = hit($app, method => 'POST', path => '/switch', env => with($one));
    my ($sc) = grep { /\Apunk\.sid=/ } set_cookies($r);
    unlike($sc, qr/Max-Age=0/, 'cookie session: logout then login is a login');
    is(hit($app, path => '/me', env => with(sid($r)))->[2][0], '7',
        '...as the second user');
}

# ---- logout then login, on a store --------------------------------------------

{
    package Switch;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    auth model => 'users';
    post '/login'  => sub { $_[0]->login(1); $_[0]->text('in') };
    post '/switch' => sub { $_[0]->logout->login(7); $_[0]->text('switched') };
    post '/out'    => sub { $_[0]->login(7)->logout; $_[0]->text('out') };
    get  '/me'     => sub { $_[0]->text($_[0]->auth_id // 'none') };
    package main;
}
{
    my $app = Switch->to_app;
    my $one = sid(hit($app, method => 'POST', path => '/login'));
    is(hit($app, path => '/me', env => with($one))->[2][0], '1', 'signed in as 1');

    my $r = hit($app, method => 'POST', path => '/switch', env => with($one));
    my ($sc) = grep { /\Apunk\.sid=/ } set_cookies($r);
    unlike($sc, qr/Max-Age=0/, 'logout then login does not delete the cookie');
    my $two = sid($r);
    isnt($two, $one, 'it names a new id');
    is(entries('Switch'), 1, 'the first user\'s entry was deleted');
    is(hit($app, path => '/me', env => with($two))->[2][0], '7',
        'the new id is the second user');
    is(hit($app, path => '/me', env => with($one))->[2][0], 'none',
        'the old id is nobody');

    my $o = hit($app, method => 'POST', path => '/out', env => with($two));
    my ($del) = grep { /\Apunk\.sid=/ } set_cookies($o);
    like($del, qr/Max-Age=0/, 'login then logout is still a logout');
    is(entries('Switch'), 0, '...and the entry is gone');
}

# ---- Secure follows the scheme ------------------------------------------------

{
    package Scheme;
    use Punk;
    session secret => 'k';
    csrf;
    get '/note' => sub { $_[0]->session->{n} = 1; $_[0]->csrf_token;
                         $_[0]->text('note') };
    get '/out'  => sub { $_[0]->session_expire; $_[0]->text('out') };
    package SchemeOff;
    use Punk;
    session secret => 'k', secure => 0;
    get '/note' => sub { $_[0]->session->{n} = 1; $_[0]->text('note') };
    package SchemeOn;
    use Punk;
    session secret => 'k', secure => 1;
    get '/note' => sub { $_[0]->session->{n} = 1; $_[0]->text('note') };
    package SchemeStore;
    use Punk;
    session secret => 'k', store => { backend => 'T::Store' };
    get '/note' => sub { $_[0]->session->{n} = 1; $_[0]->text('note') };
    package main;
}
{
    my $https = { 'psgi.url_scheme' => 'https' };
    my $http  = { 'psgi.url_scheme' => 'http' };
    my $app = Scheme->to_app;
    my @c = set_cookies(hit($app, path => '/note', env => $https));
    is(scalar(grep { /; Secure/ } @c), 2,
        'over https the session cookie and the csrf mirror are both Secure');
    @c = set_cookies(hit($app, path => '/note', env => $http));
    is(scalar @c, 2, 'over http both are still set');
    is(scalar(grep { /; Secure/ } @c), 0, '...and neither is Secure');
    my ($d) = set_cookies(hit($app, path => '/out', env => $https));
    like($d, qr/Max-Age=0.*; Secure/, 'the deletion cookie matches over https');

    my ($off) = set_cookies(hit(SchemeOff->to_app, path => '/note', env => $https));
    unlike($off, qr/Secure/, 'secure => 0 holds over https');
    my ($on) = set_cookies(hit(SchemeOn->to_app, path => '/note', env => $http));
    like($on, qr/; Secure/, 'secure => 1 holds over http');
    my ($st) = set_cookies(hit(SchemeStore->to_app, path => '/note', env => $https));
    like($st, qr/; Secure/, 'a stored session id is Secure over https');
}

# ---- what counts as an id -----------------------------------------------------

{
    package Ids;
    use Punk;
    session secret => 'k';
    auth model => 'users';
    post '/login' => sub {
        my ($c) = @_;
        my $how = $c->param('how') // '';
        my $ok = eval {
            $how eq 'empty' ? $c->login('')
          : $how eq 'zero'  ? $c->login(0)
          : $how eq 'row'   ? $c->login({ id => '' })
          :                   $c->login('0e0');
            1;
        };
        $c->text($ok ? 'in' : "refused: $@");
    };
    get '/forge' => sub { $_[0]->session->{user_id} = $_[0]->param('v');
                          $_[0]->text('forged') };
    my $acct = under '/account' => auth_guard;
    $acct->get('/home' => sub { $_[0]->text('home') });
    get '/me' => sub { $_[0]->text($_[0]->auth_id // 'none') };
    package main;
}
{
    my $app = Ids->to_app;
    for my $how (qw(empty zero row)) {
        my $r = hit($app, method => 'POST', path => '/login',
                    query => "how=$how");
        like($r->[2][0], qr/\Arefused: Punk: login needs a user id/,
            "login refuses the $how id");
    }
    my $r = hit($app, method => 'POST', path => '/login', query => 'how=other');
    is($r->[2][0], 'in', 'a true string is an id');
    is(hit($app, path => '/me', env => with(sid($r)))->[2][0], '0e0',
        '...and comes back as given');

    for my $v ('', '0') {
        my $c = sid(hit($app, path => '/forge', query => "v=$v"));
        is(hit($app, path => '/account/home', env => with($c))->[0], 401,
            "a session whose user_id is '$v' does not pass the guard");
        is(hit($app, path => '/me', env => with($c))->[2][0], 'none',
            '...and auth_id is undef');
    }
}

# ---- a login replaces the CSRF token with the session id ----------------------------
# The token minted for the anonymous session used to ride into the logged-in
# one: a token planted before the login validated for the user after it.
{
    package FixTok;
    use Punk;
    session secret => 'k', expires => '7d', store => { backend => 'T::Store' };
    csrf exempt => ['/login'];
    auth model => 'users';
    get  '/tok'   => sub { $_[0]->text($_[0]->csrf_token) };
    post '/login' => sub { $_[0]->login(42); $_[0]->text('in') };
    package main;
}
{
    my $app = FixTok->to_app;
    my $r0  = hit($app, path => '/tok');
    my ($planted, $t0) = (sid($r0), $r0->[2][0]);
    my $r1  = hit($app, method => 'POST', path => '/login', env => with($planted));
    my $r2  = hit($app, path => '/tok', env => with(sid($r1)));
    my $t1  = $r2->[2][0];
    ok(length $t0 && length $t1, 'a token before and after the login');
    isnt($t1, $t0, 'the login replaced it');
}

done_testing;
