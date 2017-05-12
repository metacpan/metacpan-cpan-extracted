use Mojolicious::Lite;

use Test::More;
use Test::Mojo;

use Browser::Open 'open_browser';

plugin 'Multiplex';

any '/' => 'test';

my $connects = 0; 
my @messages;
websocket '/socket' => sub {
  my $c = shift;
  my $multiplex = $c->multiplex;

  $multiplex->on(subscribe => sub { 
    my ($multiplex, $topic) = @_;
    warn 'in connect';
    $connects++;
    $multiplex->send_status($topic => 1);
  });
  $multiplex->on(message => sub {
    warn 'in message';
    push @messages, $_[2];
    $c->finish;
  });
};

my $t = Test::Mojo->new;

open_browser($t->ua->server->url->to_abs);
#warn($t->ua->server->url->to_abs);
Mojo::IOLoop->one_tick while $connects <= 2;

cmp_ok $connects, '>', 2, 'got multiple connects';
is $messages[0], 'Connect: 1', 'correct first message';
is $messages[1], 'Connect: 2', 'correct second message';

done_testing;

__DATA__

@@ test.html.ep

<p>Testing ...</p>

%= javascript '/websocket_multiplex.js'
%= javascript begin
  var ws = new WebSocket('<%= url_for('socket')->to_abs %>');
  var multiplex = new WebSocketMultiplex(ws);
  var channel = multiplex.channel('mytest');
  var i = 1;
  channel.onopen = function() {
    console.log('channel opened');
    channel.send('Connect: ' + i++);
  }
% end
