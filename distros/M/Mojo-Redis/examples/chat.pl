#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use lib 'lib';
use Mojo::Redis;

helper redis => sub { state $r = Mojo::Redis->new };

get '/' => 'chat';

websocket '/socket' => sub ($c) {
  my $pubsub = $c->redis->pubsub;
  my $cb = $pubsub->listen('chat:example' => sub ($pubsub, $msg) { $c->send($msg) });

  $c->inactivity_timeout(3600);
  $c->on(finish => sub { $pubsub->unlisten('chat:example' => $cb) });
  $c->on(message => sub ($c, $msg) { $pubsub->notify('chat:example' => $msg) });
};

app->start;

__DATA__
@@ chat.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title>Mojo::Redis Chat Example</title>
    <link rel="stylesheet" href="//fonts.googleapis.com/css?family=Roboto:300,300italic,700,700italic">
    <link rel="stylesheet" href="//cdn.rawgit.com/necolas/normalize.css/master/normalize.css">
    <link rel="stylesheet" href="//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css">
    <style>
      body {
        margin: 3rem 1rem;
      }
      pre {
        padding: 0.2rem 0.5rem;
      }
      .wrapper {
        max-width: 35em;
        margin: 0 auto;
      }
    </style>
  </head>
  <body>
    <div class="wrapper">
      <h1>Mojo::Redis Chat Example</h1>
      <form>
        <label>
          <span>Message:</span>
          <input type="search" name="message" value="Some message" placeholder="Write a message" autocomplete="off" disabled>
        </label>
        <button class="button" disabled>Send message</button>
      </form>
      <h2>Messages</h2>
      <pre id="messages">Connecting...</pre>
    </div>
    %= javascript begin
      var formEl = document.getElementsByTagName("form")[0];
      var inputEl = formEl.message;
      var messagesEl = document.getElementById("messages");
      var ws = new WebSocket("<%= url_for('socket')->to_abs %>");
      var id = Math.round(Math.random() * 1000);

      var hms = function() {
        var d = new Date();
        return [d.getHours(), d.getMinutes(), d.getSeconds()].map(function(v) {
          return v < 10 ? "0" + v : v;
        }).join(":");
      };

      formEl.addEventListener("submit", function(e) {
        e.preventDefault();
        if (inputEl.value.length) ws.send(hms() + " <" + id + "> " + inputEl.value);
        inputEl.value = "";
      });

      ws.onopen = function(e) {
        inputEl.disabled = false;
        document.getElementsByTagName("button")[0].disabled = false;
        messagesEl.innerHTML = hms() + " &lt;server> Connected.";
      };

      ws.onmessage = function(e) {
        messagesEl.innerHTML = e.data.replace(/</g, "&lt;") + "<br>" + messagesEl.innerHTML;
      };
    % end
  </body>
</html>
