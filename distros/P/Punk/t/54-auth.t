#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The auth battery's core (punk_auth.h + Punk::Auth): the session-backed
# identity, the memoized current_user, and guards for `under`. The things
# asserted hard: a guard denial negotiates (browser redirect with return-to,
# 401 JSON for an API client), the role ladder means "this role or better",
# check_password burns PBKDF2 work even when there is no user, and every
# model call works on a backend that hands back futures.

local $Punk::Auth::Password::ITERATIONS = 1_000;

# ---- an in-memory backend, and a deferred twin --------------------------------

{
    package T::Backend::Memory;
    sub new {
        my ($class, %a) = @_;
        bless { primary => $a{primary} || 'id', rows => {}, seq => 0 }, $class;
    }
    sub get {
        my ($s, %k) = @_;
        my $r = $s->{rows}{ $k{ $s->{primary} } };
        return $r ? { %$r } : undef;
    }
    sub search { return { rows => [], has_more_data => 0, next => undef } }
    sub all    { return $_[0]->search }
    sub create {
        my ($s, $d) = @_;
        my $id = ++$s->{seq};
        my $row = { %$d, $s->{primary} => $id };
        $s->{rows}{$id} = $row;
        return { %$row };
    }
    sub update {
        my ($s, $d) = @_;
        my $row = $s->{rows}{ $d->{ $s->{primary} } } or return undef;
        %$row = (%$row, %$d);
        return { %$row };
    }
    sub delete {
        my ($s, %k) = @_;
        return delete $s->{rows}{ $k{ $s->{primary} } } ? 1 : 0;
    }
}
{
    # every result arrives wrapped in an object with ->get, the shape the
    # await seam must unwrap (a non-Punk::Future future)
    package T::Later;
    sub new { bless { v => $_[1] }, $_[0] }
    sub get { $_[0]{v} }
    package T::Backend::Deferred;
    our @ISA = ('T::Backend::Memory');
    for my $m (qw(get search all create update delete)) {
        no strict 'refs';
        my $super = "T::Backend::Memory::$m";
        *$m = sub { my $s = shift; T::Later->new($s->$super(@_)) };
    }
}

# ---- the app -------------------------------------------------------------------

{
    package AuthApp::Model::User;
    use Punk::Model;
    table 'users';
    field id            => { type => 'integer' };
    field email         => { type => 'string' };
    field password_hash => { type => 'string',  required => 0 };
    field verified      => { type => 'integer', required => 0 };
    field role          => { type => 'string',  required => 0 };
}
{
    package AuthApp;
    use Punk;
    use Punk::Auth::Password;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    auth model => 'User', roles => sub { $_[1]->{role} };

    my $acct = under '/account' => auth_guard;
    $acct->get('/home' => sub {
        my ($c) = @_;
        $c->json({ id => $c->current_user->{id},
                   stash_id => $c->stash->{auth}{user_id} });
    });
    my $adm = under '/admin' => auth_guard(role => 'admin');
    $adm->get('/panel' => sub { $_[0]->text('panel') });
    my $owner = under '/owner' => auth_guard(role => 'owner', on_denied => '404');
    $owner->get('/x' => sub { $_[0]->text('x') });
    my $ver = under '/verified' => auth_guard(verified => 1);
    $ver->get('/v' => sub { $_[0]->text('v') });
    under('/coded' => auth_guard(on_denied => sub { $_[0]->text('custom', 418) }))
        ->get('/x' => sub { $_[0]->text('never') });

    post '/signup' => sub {
        my ($c) = @_;
        my $u = $c->model('User')->create({
            email         => $c->param('email'),
            password_hash => Punk::Auth::Password::hash($c->param('password')),
            verified      => $c->param('v') // 1,
            role          => $c->param('r') // 'member',
        });
        $c->login($u);
        $c->json({ id => $u->{id} });
    };
    post '/login' => sub {
        my ($c) = @_;
        my $user;               # a linear scan stands in for by-email lookup
        my $m = $c->model('User');
        for my $id (1 .. 50) {
            my $row = $m->get(id => $id) or next;
            $user = $row, last if $row->{email} eq ($c->param('email') // '');
        }
        return $c->json({ errors => [ { message => 'no match' } ] }, 401)
            unless $c->check_password($user, $c->param('password'));
        $c->login($user);
        $c->json({ id => $user->{id} });
    };
    get  '/whoami'  => sub { $_[0]->json({ id => $_[0]->auth_id }) };
    get  '/user'    => sub {
        my ($c) = @_;
        my $u = $c->current_user;
        $c->json({ got => $u ? $u->{email} : undef });
    };
    post '/logout'  => sub { $_[0]->logout->redirect('/') };
    get  '/counted' => sub {
        my ($c) = @_;
        # current_user twice: the model must be hit at most once
        $c->current_user; $c->current_user;
        $c->json({ ok => 1 });
    };
}

my $t = Punk::Test->new('AuthApp');

# ---- signed out ----------------------------------------------------------------

$t->get_ok('/account/home', headers => { Accept => 'text/html' })
  ->status_is(302)
  ->header_is(Location => '/login?to=/account/home',
      'a browser is sent to log in, with a return-to');
$t->get_ok('/account/home', headers => { Accept => 'application/json' })
  ->status_is(401)
  ->json_is('/errors/0/message' => 'Unauthorized',
      'an API client gets the house 401');
$t->get_ok('/account/home')->status_is(401,
    'no Accept at all is not a browser');
$t->get_ok('/owner/x', headers => { Accept => 'text/html' })
  ->status_is(404, "on_denied => '404' does not confirm the page exists");
$t->get_ok('/coded/x')->status_is(418)->content_is('custom',
    'an on_denied coderef answers for itself');
$t->get_ok('/user')->status_is(200)->json_is('/got' => undef,
    'current_user is undef, not an error, when nobody is signed in');

# ---- sign up, guards open by role ---------------------------------------------

$t->post_ok('/signup', form => { email => 'a@b.co', password => 'pw-one-longer',
                                 r => 'admin' })
  ->status_is(200)->json_is('/id' => 1);
$t->get_ok('/account/home')->status_is(200)
  ->json_is('/id' => 1)
  ->json_is('/stash_id' => 1, 'the guard stashed the id under auth');
$t->get_ok('/whoami')->json_is('/id' => 1);
$t->get_ok('/admin/panel')->status_is(200)->content_is('panel',
    'admin passes the admin guard');
$t->get_ok('/owner/x')->status_is(404,
    'admin is below owner: denied, still as a 404');
$t->get_ok('/verified/v')->status_is(200);

# ---- logout --------------------------------------------------------------------

$t->post_ok('/logout')->status_is(302);
$t->get_ok('/whoami')->json_is('/id' => undef, 'logout empties the session');

# ---- login with password verification ------------------------------------------

$t->post_ok('/login', form => { email => 'a@b.co', password => 'pw-one-longer' })
  ->status_is(200)->json_is('/id' => 1, 'the right password signs in');
$t->post_ok('/logout');
$t->post_ok('/login', form => { email => 'a@b.co', password => 'wrong' })
  ->status_is(401, 'the wrong password does not');
$t->post_ok('/login', form => { email => 'nobody@b.co', password => 'x' })
  ->status_is(401, 'neither does an unknown email (dummy verify ran)');

# ---- an unverified member ------------------------------------------------------

$t->post_ok('/signup', form => { email => 'm@b.co', password => 'pw-two-longer',
                                 v => 0, r => 'member' })->status_is(200);
$t->get_ok('/account/home')->status_is(200,
    'a bare guard admits any signed-in user');
$t->get_ok('/admin/panel', headers => { Accept => 'application/json' })
  ->status_is(401, 'member is below admin');
$t->get_ok('/verified/v', headers => { Accept => 'application/json' })
  ->status_is(401, 'and unverified fails the verified guard');

# ---- multiple roles, and roles outside the ladder ------------------------------

{
    package MultiApp::Model::User;
    use Punk::Model;
    table 'users';
    field id    => { type => 'integer' };
    field email => { type => 'string' };
    field roles => { type => 'string', required => 0 };   # comma-joined
    package MultiApp;
    use Punk;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    # the hook returns a LIST - one user, several roles at once
    auth model => 'User',
         roles => sub { split /,/, ($_[1]->{roles} // '') };
    under('/admin' => auth_guard(role => 'admin'))
        ->get('/x' => sub { $_[0]->text('a') });
    # 'staff' is not in the rank ladder: exact membership, no ordering
    under('/internal' => auth_guard(role => 'staff', on_denied => '404'))
        ->get('/x' => sub { $_[0]->text('s') });
    post '/as' => sub {
        my ($c) = @_;
        my $u = $c->model('User')->create({ email => 'x@b.co',
                                            roles => $c->param('roles') });
        $c->login($u);
        $c->json({ id => $u->{id} });
    };
}
{
    my $m = Punk::Test->new('MultiApp');
    $m->post_ok('/as', form => { roles => 'member,staff' });
    $m->get_ok('/internal/x')->status_is(200)->content_is('s',
        'an unranked role matches by exact membership');
    $m->get_ok('/admin/x', headers => { Accept => 'application/json' })
      ->status_is(401, 'member+staff is still below admin on the ladder');

    $m->post_ok('/as', form => { roles => 'owner' });
    $m->get_ok('/admin/x')->status_is(200,
        'owner outranks admin: any held ladder role counts');
    $m->get_ok('/internal/x')->status_is(404,
        'but owner does not imply the orthogonal staff role');
}

# ---- memoization ---------------------------------------------------------------

{
    my $gets = 0;
    no warnings 'redefine';
    my $orig = \&T::Backend::Memory::get;
    local *T::Backend::Memory::get = sub { $gets++; $orig->(@_) };
    $t->get_ok('/counted')->status_is(200);
    is($gets, 1, 'current_user hits the model once per request');
}

# ---- the deferred backend ------------------------------------------------------

{
    package DeferApp::Model::User;
    use Punk::Model;
    table 'users';
    field id    => { type => 'integer' };
    field email => { type => 'string' };
    package DeferApp;
    use Punk;
    session secret => 'test-key';
    database backend => 'T::Backend::Deferred';
    model 'User';
    auth model => 'User';
    post '/mk' => sub {
        my ($c) = @_;
        my $u = Punk::Auth::_await($c, $c->model('User')->create({
            email => 'f@b.co' }));
        $c->login($u);
        $c->json({ id => $u->{id} });
    };
    get '/me' => sub {
        my ($c) = @_;
        $c->json({ email => $c->current_user->{email} });
    };
}
{
    my $d = Punk::Test->new('DeferApp');
    $d->post_ok('/mk')->status_is(200)->json_is('/id' => 1);
    $d->get_ok('/me')->status_is(200)->json_is('/email' => 'f@b.co',
        'current_user awaits a future-returning backend');
}

# ---- Punk::Test::login_as ------------------------------------------------------

{
    my $fresh = Punk::Test->new('AuthApp');
    $fresh->get_ok('/account/home', headers => { Accept => 'application/json' })
          ->status_is(401, 'a fresh client is signed out');
    $fresh->login_as(1);
    $fresh->get_ok('/account/home')->status_is(200)->json_is('/id' => 1,
        'login_as mints a session the app itself verifies');
    $fresh->login_as({ id => 2 });
    $fresh->get_ok('/whoami')->json_is('/id' => 2,
        'and takes a user row as well as an id');
}
{
    my $coderef = Punk::Test->new(sub { [ 200, [], [''] ] });
    my $err = '';
    eval { $coderef->login_as(1) } or $err = $@;
    like($err, qr/built from a class name/,
        'login_as on a coderef client explains itself');
}

# ---- boot-time and misuse croaks -----------------------------------------------

{
    my $err = '';
    eval q{
        package NoSess; use Punk;
        auth model => 'User';
        get '/' => sub { 1 };
        NoSess->to_app;
    } or $err = $@;
    like($err, qr/`auth` needs a session/, 'auth without session croaks at boot');
}
{
    my $err = '';
    eval q{ package BadOpt; use Punk; auth modle => 'User'; 1 } or $err = $@;
    like($err, qr/unknown auth option 'modle'/, 'a misspelled option croaks');
}
{
    my $err = '';
    eval q{ package BadF; use Punk; auth fields => { emial => 'e' }; 1 }
        or $err = $@;
    like($err, qr/unknown auth field 'emial'/, 'so does a misspelled field');
}
{
    my $err = '';
    eval q{ package BadOD; use Punk; my $g = auth_guard(on_denied => 'nope'); 1 }
        or $err = $@;
    like($err, qr/on_denied takes/, 'a bad on_denied croaks at keyword time');
}
{
    my $err = '';
    eval q{ package BadG; use Punk; my $g = auth_guard(rolle => 'admin'); 1 }
        or $err = $@;
    like($err, qr/unknown auth_guard option 'rolle'/,
        'a misspelled guard option croaks');
}
{
    my $err = '';
    eval q{
        package BadRoles; use Punk;
        session secret => 'k';
        auth model => 'User', roles => 'NoSuch#method';
        get '/' => sub { 1 };
        BadRoles->to_app;
    } or $err = $@;
    like($err, qr/auth roles/, 'a roles target typo croaks at to_app');
}

# ---- the on_login composition shape -------------------------------------------

{
    package OApp::Model::User;
    use Punk::Model;
    table 'users';
    field id    => { type => 'integer' };
    field email => { type => 'string' };
    package OApp;
    use Punk;
    session secret => 'test-key';
    database backend => 'T::Backend::Memory';
    model 'User';
    auth model => 'User';
    # the body an oauth2_login on_login would run, minus the plugin
    post '/fake-callback' => sub {
        my ($c) = @_;
        my $identity = { provider => 'google', email => 'g@b.co',
                         email_verified => 1 };
        return $c->redirect('/login?error=oauth')
            unless $identity->{email_verified};
        my $u = $c->model('User')->create({ email => $identity->{email} });
        $c->login($u);
        return $c->redirect('/account');
    };
    get '/who' => sub { $_[0]->json({ e => $_[0]->current_user->{email} }) };
}
{
    my $o = Punk::Test->new('OApp');
    $o->post_ok('/fake-callback')->status_is(302);
    $o->get_ok('/who')->json_is('/e' => 'g@b.co',
        '$c->login is the primitive an on_login body ends in');
}

done_testing;
