#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

my $MPID = 0;

get '/'           => {text => $0};
get '/block'      => sub ($c) { $c->render_later; sleep 5 };
get '/pid'        => {text => "pid=$$"};
get '/ppid/:ppid' => sub ($c) { $MPID = $c->stash('ppid'); $c->render(text => $$); };

get '/slow' => sub ($c) {
  my $t = $c->param('t') || 2;
  $c->inactivity_timeout($t + 1);
  $c->render_later;
  Mojo::Promise->timer($t)->then(sub { $c->render(text => 'slow') });
};

app->hook(
  before_server_start => sub ($server, $app) {
    $app->log->debug(join ' ', ref $server, join ' ', @{$server->listen});
    Mojo::IOLoop->recurring(0.01 => sub { $server->manager_pid($MPID) if $MPID });
  }
);

app->log->level($ENV{MOJO_LOG_LEVEL} || 'error');
app->start;
