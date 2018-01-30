#!/usr/bin/env perl

use Mojolicious::Lite -signatures;
use Mojo::Redis2;

helper redis => sub { state $r = Mojo::Redis2->new };

get '/' => 'chat';

websocket '/socket' => sub ($c, $r = $c->redis) {
  $r->subscribe(['chat']);
  my $cb = $r->on(message => sub ($r, $msg, $chan) { $c->send($msg) });
  $c->on(finish => sub { $r->unsubscribe(message => $cb) });
  $c->on(message => sub ($c, $msg) { $r->publish(chat => $msg) });
  $c->inactivity_timeout(3600);
};

app->start;

__DATA__

@@ chat.html.ep

<!DOCTYPE html>
<html>
  <head><title>Mojo/Redis Chat Example</title></head>
  <body>
    <form onsubmit="sendChat(this.children[0]); return false"><input></form>
    <div id="log"></div>
    %= javascript begin
      var log = document.getElementById('log');
      var ws  = new WebSocket('<%= url_for('socket')->to_abs %>');
      ws.onmessage = function (e) { log.innerHTML = '<p>'+e.data+'</p>' + log.innerHTML };
      function sendChat(input) { ws.send(input.value); input.value = '' }
    % end
  </body>
</html>
