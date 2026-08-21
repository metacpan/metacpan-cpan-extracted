#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The streaming half of the test client: SSE collected through the
# psgi.streaming driver, a blocking websocket held interactively over the
# in-process fork transport, and - where Hyperman can carry it - a plain
# websocket over the live transport.

# ---- SSE ---------------------------------------------------------------------

{
    package SseApp;
    use Punk;
    sse '/events' => sub {
        my ($c, $s) = @_;
        $s->send('hello');
        $s->id(7);
        $s->event(tick => 'hi');
        $s->send({ n => 2, deep => { k => 'v' } });
        $s->comment('ka');
        $s->send("a\nb");
        $s->close;
    };
    get '/plain' => sub { $_[0]->text('not a stream') };
}

my $t = Punk::Test->new('SseApp');

$t->sse_ok('/events')
  ->status_is(200)
  ->header_is('Content-Type' => 'text/event-stream')
  ->sse_data_is(0, 'hello')
  ->sse_event_is(1, tick => 'hi')
  ->sse_json_is(2, '/n' => 2)
  ->sse_json_is(2, '/deep/k' => 'v')
  ->sse_data_is(3, "a\nb", 'multi-line data reassembles');

is($t->sse_events->[1]{id}, 7, 'the id field rides the event it stamps');
is_deeply($t->sse_comments, ['ka'], 'comments are collected apart');
is(scalar @{ $t->sse_events }, 4, 'exactly the dispatched events');

# ---- websocket, in-process (blocking transport) ------------------------------

{
    package WsApp;
    use Punk;
    session secret => 'test-key';

    websocket '/echo' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("echo:$_[1]") });
        $ws->on(binary  => sub { $_[0]->send_binary("bin:$_[1]") });
    }, { blocking => 1 };

    websocket '/who' => sub {
        my ($c, $ws) = @_;
        my $user = $c->session->{user} // 'nobody';
        $ws->on(message => sub { $_[0]->send("user:$user") });
    }, { blocking => 1 };

    my $guarded = under '/private' => sub {
        my ($c) = @_;
        return $c->text('nope', 403)
            unless ($c->req->header('x-token') // '') eq 'let-me-in';
        return;
    };
    $guarded->websocket('/ws' => sub {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send('guarded ok') });
    }, { blocking => 1 });

    post '/login' => sub {
        my ($c) = @_;
        $c->session->{user} = $c->param('user');
        $c->text('in');
    };

    websocket '/loop-only' => sub { };   # no blocking - needs the live side
}

my $w = Punk::Test->new('WsApp');

$w->websocket_ok('/echo')
  ->send_ok('hello')
  ->message_is('echo:hello')
  ->send_ok('again')
  ->message_is('echo:again', 'the conversation is interactive')
  ->send_ok('raw', binary => 1)
  ->message_is('bin:raw', 'binary frames reach the binary handler')
  ->finish_ok;

# the jar rides the upgrade: a session set over HTTP is visible in the handler
$w->post_ok('/login', form => { user => 'ada' })->status_is(200);
$w->websocket_ok('/who')
  ->send_ok('?')
  ->message_is('user:ada', 'the cookie jar rode the upgrade request')
  ->finish_ok;

# a guard rejects before the upgrade, and the relayed status says why
{
    my $tb = Test::Builder->new;
    $tb->todo_start('a guarded upgrade without the token must fail');
    $w->websocket_ok('/private/ws');
    $tb->todo_end;
    ok(!($tb->details)[-1]->{actual_ok}, 'the 403 failed websocket_ok');
}
$w->websocket_ok('/private/ws', headers => { 'X-Token' => 'let-me-in' })
  ->send_ok('x')
  ->message_is('guarded ok', 'and the authorised upgrade works')
  ->finish_ok;

# ---- websocket, live transport ----------------------------------------------

SKIP: {
    skip 'Hyperman 0.11+ (the detach ABI) required for the live transport', 4
        unless Punk::Test::ws_live_available();

    {
        package LiveApp;
        use Punk;
        websocket '/echo' => sub {
            my ($c, $ws) = @_;
            $ws->on(message => sub { $_[0]->send("live:$_[1]") });
        };
        get '/plain' => sub { $_[0]->text('plain ok') };
    }

    my $l = Punk::Test->new('LiveApp');
    $l->websocket_ok('/echo')          # not blocking - falls through to live
      ->send_ok('hi')
      ->message_is('live:hi', 'a loop-backed route works over real TCP')
      ->finish_ok;
}

done_testing();
