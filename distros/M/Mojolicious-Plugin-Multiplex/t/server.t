use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

plugin 'Multiplex';

my ($event, $topic, $data);

websocket '/protocol' => sub {
  my $c = shift;
  my $drain = $c->param('drain');
  my $m = $c->multiplex;
  $c->tx->unsubscribe('text'); # disable default listener

  $c->on(json => sub {
    my (undef, $json) = @_;
    my $method = shift @$json;
    $m->$method(@$json, $drain ? sub { $m->send(othertopic => 'ok') } : ());
  });
};

websocket '/socket' => sub {
  my $c = shift;
  my $m = $c->multiplex;

  for my $e (qw/subscribe message unsubscribe status error/) {
    $m->on($e => sub {
      $event = $e;
      (undef, $topic, $data) = @_;
    });
  }
};

my $t = Test::Mojo->new;
$t->websocket_ok('/protocol')
  # send_status
  ->send_ok({json => ['send_status', 'mytopic', 1]})
  ->message_ok
  ->message_is('sta,mytopic,true')
  ->send_ok({json => ['send_status', 'mytopic', 0]})
  ->message_ok
  ->message_is('sta,mytopic,false')
  ->send_ok({json => ['send_status', 'mytopic']})
  ->message_ok
  ->message_is('sta,mytopic')
  # send
  ->send_ok({json => ['send', 'mytopic', 'data']})
  ->message_ok
  ->message_is('msg,mytopic,data')
  ->send_ok({json => ['send', 'mytopic', '']})
  ->message_ok
  ->message_is('msg,mytopic,')
  ->send_ok({json => ['send', 'mytopic', undef]})
  ->message_ok
  ->message_is('msg,mytopic,')
  ->send_ok({json => ['send', 'mytopic']})
  ->message_ok
  ->message_is('msg,mytopic,')
  # send_error
  ->send_ok({json => ['send_error', 'mytopic', 'data']})
  ->message_ok
  ->message_is('err,mytopic,data')
  ->send_ok({json => ['send_error', 'mytopic', '']})
  ->message_ok
  ->message_is('err,mytopic,')
  ->send_ok({json => ['send_error', 'mytopic', undef]})
  ->message_ok
  ->message_is('err,mytopic,')
  ->send_ok({json => ['send_error', 'mytopic']})
  ->message_ok
  ->message_is('err,mytopic,')
  ->finish_ok;

$t->websocket_ok('/protocol?drain=1')
  ->send_ok({json => ['send', 'thistopic', 'hi']})
  ->message_ok
  ->message_is('msg,thistopic,hi')
  ->message_ok
  ->message_is('msg,othertopic,ok')
  ->finish_ok;

my $send_event_ok = sub {
  my ($t, $message, $desc) = @_;
  $desc ||= 'event sent';
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  $event = undef;
  $topic = undef;
  $data  = undef;
  my $sent = 0;
  $t->tx->send($message, sub { $sent = 1 });
  my $timeout = Mojo::IOLoop->timer(1 => sub { $event = 'TIMEOUT' });
  Mojo::IOLoop->one_tick until $event;
  Mojo::IOLoop->remove($timeout);
  $t->success(ok $sent && $event ne 'TIMEOUT');
};

$t->websocket_ok('/socket')
  ->$send_event_ok('sub,mytopic');
is $event, 'subscribe', 'right event';
is $topic, 'mytopic',   'right topic';

$t->$send_event_ok('msg,mytopic,hello world');
is $event, 'message', 'right event';
is $topic, 'mytopic', 'right topic';
is $data, 'hello world', 'right payload';

$t->$send_event_ok('uns,mytopic');
is $event, 'unsubscribe', 'right event';
is $topic, 'mytopic',     'right topic';

$t->$send_event_ok('sta,mytopic,true');
is $event, 'status', 'right event';
is $topic, 'mytopic',     'right topic';
ok $data, 'right payload';

$t->$send_event_ok('sta,mytopic,false');
is $event, 'status', 'right event';
is $topic, 'mytopic',     'right topic';
ok defined $data && !$data, 'right payload';

$t->$send_event_ok('sta,mytopic');
is $event, 'status', 'right event';
is $topic, 'mytopic',     'right topic';
ok !defined $data, 'right payload';

$t->$send_event_ok('sta,mytopic,wat');
is $event, 'error',   'right event';
is $topic, 'mytopic', 'right topic';
is $data->{error}, 'Status payload not understood', 'correct error message';

$t->$send_event_ok('err,mytopic,argh');
is $event, 'error',   'right event';
is $topic, 'mytopic', 'right topic';
is $data->{error}, 'Client error', 'correct error message';
is $data->{message}{payload}, 'argh', 'correct error payload';

$t->$send_event_ok('wat,mytopic,argh');
is $event, 'error',   'right event';
is $topic, 'mytopic', 'right topic';
is $data->{error}, 'Message type not understood', 'correct error message';

$t->finish_ok;

done_testing;

