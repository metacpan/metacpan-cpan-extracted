#!/usr/bin/env perl
use Mojolicious::Lite;
BEGIN{ plugin 'Mojolicious::Plugin::EventSource', timeout => 300 }

get '/' => 'index';

event_source '/event' => sub {
  my $self = shift;

  my $id = Mojo::IOLoop->recurring(1 => sub {
    my $pips = int(rand 6) + 1;
    $self->emit("dice", $pips);
  });
  $self->on(finish => sub { Mojo::IOLoop->drop($id) });
} => "event";

app->start;
__DATA__

@@ index.html.ep
<!doctype html><html>
  <head><title>Roll The Dice</title></head>
  <body>
    <script>
      var events = new EventSource('<%= url_for 'event' %>');

      // Subscribe to "dice" event
      events.addEventListener('dice', function(event) {
        document.body.innerHTML += event.data + '<br/>';
      }, false);
    </script>
  </body>
</html>
