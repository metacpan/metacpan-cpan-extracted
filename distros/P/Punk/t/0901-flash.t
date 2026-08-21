#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# Flash messages (punk_flash.h): one request's lifetime, riding the session
# under the reserved punk.flash key. The property that matters is the
# rotation - set on a POST, present on the redirected GET, gone on the one
# after - and that it falls out of the session's ordinary change-detected
# write-back, driven here through the cookie jar exactly as a browser would.

{
    package FlashApp;
    use Punk;
    session secret => 'test-key';

    post '/save' => sub {
        my ($c) = @_;
        $c->flash(notice => 'Saved.', level => 'info');
        $c->redirect('/list');
    };
    get '/list' => sub {
        my ($c) = @_;
        my $f = $c->flash;
        $c->json({ notice => scalar $c->flash('notice'),
                   level  => scalar $c->flash('level'),
                   all    => $f });
    };
    get '/peek' => sub {                # reads, so it consumes
        my ($c) = @_;
        $c->text($c->flash('notice') // '-');
    };
    get '/quiet' => sub {               # never touches flash
        $_[0]->text('quiet');
    };
    get '/hold' => sub {                # consumes, but re-arms
        my ($c) = @_;
        $c->flash_keep;
        $c->text($c->flash('notice') // '-');
    };
    get '/both' => sub {                # set and read in one request
        my ($c) = @_;
        $c->flash(notice => 'new');
        $c->text($c->flash('notice') // '-');
    };
    get '/session' => sub {             # ordinary session data, for isolation
        my ($c) = @_;
        $c->session->{plain} = 'kept';
        $c->text($c->session->{plain} . ':' . ($c->flash('notice') // '-'));
    };
    get '/chain' => sub {
        my ($c) = @_;
        $c->flash(a => 1)->flash(b => 2);   # chainable, merging
        $c->text('set');
    };
    get '/read-chain' => sub {
        my ($c) = @_;
        $c->json($c->flash);
    };
}

my $t = Punk::Test->new('FlashApp');

# ---- the lifetime -------------------------------------------------------------

$t->post_ok('/save', name => 'set flash and redirect')
  ->status_is(302)
  ->header_like(Location => qr{/list$});

$t->get_ok('/list')
  ->json_is('/notice' => 'Saved.')
  ->json_is('/level'  => 'info')
  ->json_is('/all' => { notice => 'Saved.', level => 'info' },
      'the bare flash call hands over the whole inbound hash');

$t->get_ok('/list')
  ->json_is('/notice' => undef, 'consumed - gone on the next request')
  ->json_is('/all' => {});

# ---- an intervening request that never reads leaves it riding -----------------

$t->post_ok('/save')->status_is(302);
$t->get_ok('/quiet')->content_is('quiet');
$t->get_ok('/peek')->content_is('Saved.',
    'a non-reading request in between did not consume it');
$t->get_ok('/peek')->content_is('-', 'but the read did');

# ---- flash_keep re-arms for one more ------------------------------------------

$t->post_ok('/save')->status_is(302);
$t->get_ok('/hold')->content_is('Saved.', 'flash_keep still reads');
$t->get_ok('/peek')->content_is('Saved.', 'and the next request reads it again');
$t->get_ok('/peek')->content_is('-', 'exactly one more time');

# ---- set and read in one request do not meet ----------------------------------

$t->post_ok('/save')->status_is(302);
$t->get_ok('/both')->content_is('Saved.',
    'a read beside a write still sees the inbound value');
$t->get_ok('/peek')->content_is('new', 'and the write fed the next request');

# ---- ordinary session data is untouched by the rotation -----------------------

$t->post_ok('/save')->status_is(302);
$t->get_ok('/session')->content_is('kept:Saved.',
    'session data and flash coexist under one cookie');
$t->get_ok('/session')->content_is('kept:-',
    'the flash rotated away, the session data stayed');

# ---- chained setters merge ----------------------------------------------------

$t->get_ok('/chain')->content_is('set');
$t->get_ok('/read-chain')
  ->json_is('' => { a => 1, b => 2 }, 'chained flash calls merge pairs');

# ---- csrf and flash ride the same session cookie ------------------------------

{
    package FlashCsrfApp;
    use Punk;
    session secret => 'test-key';
    csrf;
    get  '/'     => sub { $_[0]->text($_[0]->csrf_token) };  # mints the mirror
    post '/save' => sub {
        my ($c) = @_;
        $c->flash(notice => 'ok');
        $c->redirect('/done');
    };
    get  '/done' => sub { $_[0]->text($_[0]->flash('notice') // '-') };
}
{
    my $c = Punk::Test->new('FlashCsrfApp');
    $c->get_ok('/')->status_is(200);
    $c->post_ok('/save', form => { x => 1 }, csrf => 1)->status_is(302);
    $c->get_ok('/done')->content_is('ok',
        'flash survives beside the rotating csrf token');
}

# ---- it needs somewhere to live -----------------------------------------------

{
    package NoSessionFlash;
    use Punk;
    get '/' => sub { $_[0]->flash(n => 1); $_[0]->text('x') };
}
{
    my $n = Punk::Test->new('NoSessionFlash');
    $n->get_ok('/', name => 'flash without a session still answers')
      ->status_is(500)
      ->json_like('/errors/0/message' => qr/no session configured/);
}

# ---- pairs are pairs ----------------------------------------------------------

{
    package OddFlash;
    use Punk;
    session secret => 'k';
    get '/' => sub { $_[0]->flash(1, 2, 3); $_[0]->text('x') };
}
{
    my $o = Punk::Test->new('OddFlash');
    $o->get_ok('/')->status_is(500)
      ->json_like('/errors/0/message' => qr/takes pairs/);
}

done_testing();
