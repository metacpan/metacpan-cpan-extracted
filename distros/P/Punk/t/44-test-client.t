#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The installed test client, exercised against small real applications: the
# request builders, the response accessors, the chained assertions, the RFC
# 6901 pointer walker, and - the part a hand-built env cannot give you - the
# cookie jar that makes one client one browser, proven through the session
# and single-use CSRF flows the dist's own earlier tests drive by hand.

{
    package TApp;
    use Punk;
    session secret => 'test-key';

    get '/json' => sub {
        $_[0]->json({
            books  => [ { title => 'Neuromancer' } ],
            page   => 1,
            'a/b'  => 'slash',
            'ti~de' => 'tilde',
        });
    };
    get  '/text' => sub { $_[0]->text('plain') };
    get  '/q'    => sub { my ($c) = @_; $c->text($c->param('x') // '-') };
    get  '/hdr'  => sub { my ($c) = @_; $c->text($c->req->header('x-req') // '-') };
    post '/echo-form' => sub {
        my ($c) = @_;
        $c->json({ a => $c->param('a'), b => $c->param('b') });
    };
    post '/echo-json' => sub { my ($c) = @_; $c->json({ got => $c->req->json }) };
    post '/login'  => sub {
        my ($c) = @_;
        $c->session->{user} = $c->param('user');
        $c->redirect('/me');
    };
    get  '/me'   => sub {
        my ($c) = @_;
        $c->text('hello ' . ($c->session->{user} // 'nobody'));
    };
    get  '/boom' => sub { die "handler exploded\n" };
}

# ---- construction ------------------------------------------------------------

my $t = Punk::Test->new('TApp');
isa_ok($t, 'Punk::Test', 'built from a class name');

{
    # to_app compiles once per class, so the coderef case gets its own app
    package RawApp;
    use Punk;
    get '/' => sub { $_[0]->text('raw') };
    package main;
    my $coderef = Punk::Test->new(RawApp->to_app);
    isa_ok($coderef, 'Punk::Test', 'built from a PSGI coderef');
    $coderef->get_ok('/')->content_is('raw');
}

{
    my $err = '';
    eval { Punk::Test->new('No::Such::App::Here') } or $err = $@;
    like($err, qr/could not load No::Such::App::Here/,
        'an unloadable class dies naming the class');
}

# ---- requests, accessors, assertions -----------------------------------------

$t->get_ok('/text')
  ->status_is(200)
  ->status_isnt(404)
  ->content_is('plain')
  ->content_like(qr/pla/)
  ->content_unlike(qr/nope/)
  ->header_exists('Content-Type')
  ->header_like('Content-Type' => qr{^text/plain});

is($t->status, 200, 'the status accessor reads the last response');
is($t->body, 'plain', 'so does body');
like($t->header('content-type'), qr{^text/plain},
    'header() is case-insensitive');

$t->get_ok('/json')
  ->header_is('Content-Type' => 'application/json')
  ->json_is('/books/0/title' => 'Neuromancer')
  ->json_like('/books/0/title' => qr/Neuro/)
  ->json_has('/page')
  ->json_is('/page' => 1)
  ->json_is('/books' => [ { title => 'Neuromancer' } ])
  ->json_is('' => { books => [ { title => 'Neuromancer' } ], page => 1,
                    'a/b' => 'slash', 'ti~de' => 'tilde' })
  ->json_is('/a~1b'  => 'slash')
  ->json_is('/ti~0de' => 'tilde');

is($t->json->{page}, 1, 'the json accessor hands back the decoded body');

# ---- query, headers, bodies --------------------------------------------------

$t->get_ok('/q?x=7')->content_is('7', 'a ?query in the path is split out');
$t->get_ok('/q', query => 'x=8')->content_is('8', 'or passed as query =>');
$t->get_ok('/hdr', headers => { 'X-Req' => '42' })
  ->content_is('42', 'headers => {} reaches the app as HTTP_*');

$t->post_ok('/echo-form', form => { a => 1, b => 'x y&z' })
  ->json_is('/a' => 1)
  ->json_is('/b' => 'x y&z', 'form values are url-encoded on the way in');

$t->post_ok('/echo-json', json => { n => 2, deep => { k => 'v' } })
  ->json_is('/got/n' => 2)
  ->json_is('/got/deep/k' => 'v');

# ---- a dying handler is the same 500 a server would send ---------------------

$t->get_ok('/boom', name => 'a dying handler still answers')
  ->status_is(500)
  ->json_like('/errors/0/message' => qr/handler exploded/);

# ---- the jar: sessions -------------------------------------------------------

$t->get_ok('/me')->content_is('hello nobody', 'no session yet');
$t->post_ok('/login', form => { user => 'ada' })
  ->status_is(302)
  ->header_like(Location => qr{/me$});
ok(defined $t->cookie('punk.sid'), 'the session cookie landed in the jar');
$t->get_ok('/me')->content_is('hello ada', 'the jar carried the session');

{
    my $other = Punk::Test->new('TApp');
    $other->get_ok('/me')->content_is('hello nobody',
        'a second client is a second browser');
}

$t->reset_session;
$t->get_ok('/me')->content_is('hello nobody', 'reset_session forgets it all');

# ---- the jar: single-use CSRF, the flow t/28 drives by hand ------------------

{
    package CsrfApp;
    use Punk;
    session secret => 'test-key';
    csrf;
    get  '/'     => sub { my ($c) = @_; $c->text($c->csrf_token) };
    post '/save' => sub { my ($c) = @_; $c->text('saved:' . ($c->param('a') // '-')) };
}

my $c = Punk::Test->new('CsrfApp');
$c->get_ok('/')->status_is(200);
my $token = $c->csrf_token;
like($token, qr/\A[A-Za-z0-9_-]{43}\z/,
    'csrf_token reads the mirror cookie from the jar');
is($c->body, $token, 'and it is the same token the handler sees');

$c->post_ok('/save', form => { a => 1 }, csrf => 1)
  ->status_is(200)
  ->content_is('saved:1', 'csrf => 1 sends the token');
isnt($c->csrf_token, $token, 'the rotated mirror replaced it in the jar');

$c->post_ok('/save', form => { a => 2 },
            headers => { 'X-CSRF-Token' => $token })
  ->status_is(403, 'a spent token is refused');

$c->post_ok('/save', form => { a => 3 }, csrf => 1)
  ->status_is(200, 'and csrf => 1 always sends the current one');

$c->post_ok('/save', form => { a => 4 })
  ->status_is(403, 'no token, no save');

done_testing();
