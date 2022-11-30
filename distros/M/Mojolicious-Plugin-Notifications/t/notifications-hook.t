#!/usr/bin/env perl
use Test::Mojo::Session;
use Test::More;
use Mojolicious::Lite;
use utf8;

my $t = Test::Mojo->new;

my $co = $t->app->build_controller;

app->plugin(Notifications => {
  JSON => 1,
  HTML => 1
});

get '/example' => sub {
  my $c = shift;

  my $v = $c->validation;
  $v->optional('warn');
  $v->optional('info');

  # Info
  if ($v->param('info')) {
    foreach my $msg (@{$v->every_param('info')}) {
      $c->notify('info' => $msg);
    };
  };

  # Get warn info
  if ($v->param('warn')) {
    foreach my $msg (@{$v->every_param('warn')}) {
      $c->notify('warn' => $msg);
    };
  };

  return $c->respond_to(
    html => {
      inline => 'Here: <%= notifications "HTML" %>'
    },
    json => {
      json => $c->notifications(json => { msg => 'Hallo' })
    }
  );
};

my $err = $t->get_ok('/example')
  ->status_is(200)
  ->content_is("Here: \n")
  ->tx->res->dom->at('#error')
  ;
if ($err) {
  is($err->text, '');
};

$err = $t->get_ok('/example?_format=json')
  ->status_is(200)
  ->json_is("/msg", 'Hallo')
  ->tx->res->dom->at('#error')
  ;
if ($err) {
  is($err->text, '');
};

$t->get_ok('/example?_format=json&warn=Oh&warn=Hm&info=Hey!')
  ->status_is(200)
  ->json_is("/msg", 'Hallo')
  ->json_is("/notifications/0/0", 'info')
  ->json_is("/notifications/0/1", 'Hey!')
  ->json_is("/notifications/1/0", 'warn')
  ->json_is("/notifications/1/1", 'Oh')
  ->json_is("/notifications/2/0", 'warn')
  ->json_is("/notifications/2/1", 'Hm')
  ;

# Filter infos and inject a  new notification
$t->app->hook(
  before_notifications => sub {
    my ($c, $notes) = @_;

    # Filter info notes
    @$notes = @{$notes->grep(sub { $_->[0] ne 'info' } )};

    # Send a new message
    $c->notify(unknown => 'a new message');
  }
);

$t->get_ok('/example?_format=json&warn=Oh&warn=Hm&info=Hey!')
  ->status_is(200)
  ->json_is("/msg", 'Hallo')
  ->json_is("/notifications/0/0", 'warn')
  ->json_is("/notifications/0/1", 'Oh')
  ->json_is("/notifications/1/0", 'warn')
  ->json_is("/notifications/1/1", 'Hm')
  ->json_is("/notifications/2/0", 'unknown')
  ->json_is("/notifications/2/1", 'a new message')
  ;

$t->get_ok('/example?_format=json')
  ->status_is(200)
  ->json_is("/msg", 'Hallo')
  ->json_is("/notifications/0/0", 'unknown')
  ->json_is("/notifications/0/1", 'a new message')
  ;


done_testing;
__END__
