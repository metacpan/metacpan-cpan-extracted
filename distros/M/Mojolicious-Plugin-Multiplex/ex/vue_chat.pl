use Mojolicious::Lite;
use Mojo::Pg;

die 'set MULTIPLEX_PG_URL to use this demo'
  unless my $url = $ENV{MULTIPLEX_PG_URL};

plugin 'Multiplex';
helper pg => sub { state $pg = Mojo::Pg->new($url) };

get '/' => 'chat';

websocket '/channel' => sub {
  my $c = shift;
  $c->inactivity_timeout(3600);

  my $pubsub = $c->pg->pubsub;
  my $multiplex = $c->multiplex;

  #NOTE these implementation respond when already subscribe,
  # they could also send error if so desired
  my %channels;
  $multiplex->on(subscribe => sub {
    my ($multiplex, $channel) = @_;
    unless(exists $channels{$channel}) {
      $channels{$channel} = $pubsub->listen($channel => sub {
        my ($pubsub, $payload) = @_;
        $c->multiplex->send($channel => $payload);
      });
    }
    $multiplex->send_status($channel, 1);
  });

  $multiplex->on(message => sub {
    my (undef, $channel, $payload) = @_;
    $pubsub->notify($channel => $payload);
  });

  $multiplex->on(unsubscribe => sub {
    my (undef, $channel) = @_;
    if(my $cb = delete $channels{$channel}) {
      $pubsub->unlisten($channel => $cb);
    }
    $multiplex->send_status($channel, 0);
  });

  $multiplex->on(finish => sub {
    $pubsub->unlisten($_ => $channels{$_}) for keys %channels;
  });
};

app->start;

__DATA__

@@ chat.html.ep

<!DOCTYPE html>
<html>
<head>
  %= stylesheet 'https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css'
</head>
<body>

<div id="chat" class="container">
  <div class="row">
    <div class="col-md-3">
      <ul class="list-group">
        <li v-for="c in channels" class="list-group-item" @click.prevent="select_channel(c)">
          <span class="badge">{{c.unread}}</span>
          <button type="button" @click.prevent="remove_channel(c)">&times;</button>
          {{c.name}}
        </li>
        <li class="list-group-item">
          Add Channel: <form @submit.prevent="add_channel"><input v-model="new_channel"></form>
        </li>
      </ul>
    </div>
    <div class="col-md-9">
      <div class="page-header" v-if="current.name"><h1>Chatting on {{current.name}}</h1></div>
      <div id="log"><p v-for="m in current.messages">{{m.username}}: {{m.message}}</p></div>
    </div>
    <div class="navbar-fixed-bottom">
      <div class="container">
        <div class="col-md-3">
          <div class="input-group">
            <div class="input-group-addon">Username</div>
            <input class="form-control" v-model="username">
          </div>
        </div>
        <div class="col-md-9">
          <form class="form" @submit.prevent="send">
            <div class="form-group">
              <div class="input-group">
                <div class="input-group-addon">Send</div>
                <input class="form-control" v-model="message">
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</div>

%= javascript 'https://cdnjs.cloudflare.com/ajax/libs/vue/1.0.20/vue.js'
%= javascript '/websocket_multiplex.js'
<script>
  var vm = new Vue({
    el: '#chat',
    data: {
      username: '',
      new_channel: '',
      url: '<%= url_for('channel')->to_abs %>',
      channels: [],
      current: {},
      message: '',
    },
    computed: {
      ws: function() {
        var ws = new WebSocket(this.url);
        ws.onopen = function() { console.log('websocket open') };
        return ws;
      },
      multiplexer: function() { return new WebSocketMultiplex(this.ws) },
    },
    methods: {
      add_channel: function() {
        var name = this.new_channel;
        this.new_channel = '';
        var channel = {'name': name, messages: [], unread: 0};
        var socket = this.multiplexer.channel(name);
        var self = this;
        socket.onmessage = function (e) {
          channel.messages.push(JSON.parse(e.data));
          if ( channel !== self.current ) { channel.unread++ }
        };
        channel.socket = socket;
        this.channels.push(channel);
        this.current = channel;
      },
      remove_channel: function(channel) {
        channel.socket.close();
        this.channels.$remove(channel);
      },
      select_channel: function(channel) {
        this.current = channel;
        channel.unread = 0;
      },
      send: function() {
        this.current.socket.send(JSON.stringify({username: this.username, message: this.message}));
        this.message = '';
      },
    },
    ready: function() { this.ws },
  });
</script>

</body>
</html>
