package PubSub;
use Mojo::Base 'Mojo::EventEmitter';
use JSON::PP;

my $jsoner   = JSON::PP->new->utf8(0);

has [qw(pubsub)];
has ws => sub { [] };
has chans => sub { {} };

sub listen {
  my $self = shift;
  my $channel = shift;
  
  $self->pubsub
    ->json($channel)
    ->listen(
  $channel => sub {
    my ($pubsub, $payload) = @_;
    $payload->{channel} = $channel;
    
    $_->send($jsoner->encode( $payload))
      for grep $channel ~~ $_->{chans}, @{$self->ws};# grep etc
  })
    unless $self->chans->{$channel}++;
  $self;
}

# Subcribe/unsubscribe websockets
sub subws {
  my ($self, $ws) = @_;
  my $n = push @{$self->ws}, $ws;
  $self->pubsub->notify($_ => {msg=>sprintf('Subcribed socket number #%s, pid %s', $n, $$)})
    for @{$ws->{chans}};
  return $n;
}
sub unsubws {
  my ($self, $n) = @_;
  my $ws = splice(@{$self->ws}, $n - 1, 1);
  $self->pubsub->notify($_ => {msg=>sprintf('Unsubcribed socket number #%s, pid %s', $n, $$)})
    for @{$ws->{chans}};
}

#====================================================================
package main;
use Mojolicious::Lite;
use Mojo::Pg::Che;

helper pubsub => sub {
  state $pubsub = PubSub->new->pubsub(Mojo::Pg::Che->new("postgres://guest@/test")->pubsub)
  ->listen('channel');
};

get '/' => 'index';

websocket '/notify' => sub {
  my $c = shift;
  $c->inactivity_timeout(3600);
  my $custom = $c->param('custom');
  $c->pubsub->listen($custom)
    if $custom;
  $c->{chans} = ['channel', $custom // ()];
  
  my $n = $c->pubsub->subws($c);
  $c->on(finish => sub { shift->pubsub->unsubws($n) });
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
  <title>PubSub PostgreSQL</title>
</head>
<body>
<style>
h1 {text-align: center;}
.col1 {float:left; width: 50%;}
.col2 {margin-left:50%; border-left: 3px double; padding: 0.3rem;}
code {background-color: grey; color: white;  padding: 0.3rem;}
</style>

<h1>Notifications from SQL</h1>

<div class="col1">
  <h2>Main channel</h2>
  <code>select pg_notify('channel', '{"msg":"♥ ok ♥"}');</code>
  <ul id="channel"></ul>
</div>

<div class="col2">
  <h2>Custom channel: <%= param('custom') %>
  <form method="get"><input name="custom"><input type="submit" value="Subcribe"></form></h2>
  % if (param('custom')) {
  <code>select pg_notify('<%= param('custom') %>', '{"msg":"..."}');</code>
  <ul id="<%= param('custom') %>"></ul>
  % }
</div>

<script src="/mojo/jquery/jquery.js"></script>
<script>
  var ws  = new WebSocket('<%= url_for('notify')->query('custom'=>param('custom'))->to_abs %>');
  ws.onmessage = function (e) {
    console.log(e.data);
    var data = JSON.parse(e.data);
    console.log(data);
    if (data['channel']) $('#'+data.channel).append($('<li>').html('['+(new Date).toString()+'] '+data['msg']));
  };
</script>
</body>
</html>