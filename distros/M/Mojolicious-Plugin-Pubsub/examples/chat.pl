use Mojolicious::Lite;
use Mojo::EventEmitter;
use Mojo::Util qw/ xml_escape /;

my $messages = Mojo::EventEmitter->new;

plugin Pubsub => { cb => sub { $messages->emit(mojochat => shift) } };

get '/' => 'chat';

websocket '/channel' => sub {
  my $c = shift;

  $c->inactivity_timeout(3600);

  # Forward messages from the browser to the socket
  $c->on(message => sub { shift->pubsub->publish(shift) });

  # Forward messages from the socket to the browser
  my $cb = $messages->on(mojochat => sub { $c->send(xml_escape(pop)) });
  $c->on(finish => sub { $messages->unsubscribe(mojochat => $cb) });
};

app->start;

__DATA__

@@ chat.html.ep
<!doctype html>
<html>
<head>
  <title>Pubsub chat example</title>
</head>
<body>
  <form onsubmit="sendChat(this.children[0]); return false"><input></form>
  <div id="log"></div>
  <script>
    var ws  = new WebSocket('<%= url_for('channel')->to_abs %>');
    ws.onmessage = function (e) {
      document.getElementById('log').innerHTML += '<p>' + e.data + '</p>';
    };
    function sendChat(input) { ws.send(input.value); input.value = '' }
  </script>
</body>
