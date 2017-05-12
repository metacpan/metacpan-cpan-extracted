#!/usr/bin/env perl
use Test::Mojo::Session;
use Test::More;
use Mojolicious::Lite;

my $t = Test::Mojo::Session->new;

my $app = $t->app;

$app->plugin('Notifications');

my $co = $app->build_controller;

$co->notify(warn => q/That's a warning/);
$co->notify(error => q/That's an error message/);
$co->notify(success => q/That's <a success story/);
my $note = $co->notifications('html');
like($note, qr/warn.+?error.+?succes/s, 'Notification is fine');
like($note, qr/warning.+?error message.+?success story/s, 'Notification is fine');
ok(!$co->notifications('html'), 'No notifications');

get '/damn' => sub {
  my $c = shift;
  $c->session(dont => 'be affected');
  return $c->render(text => $c->notifications('html') || 'nope');
};

get '/' => sub {
  my $c = shift;
  $c->notify(warn => 'flasherror');
  return $c->redirect_to('/damn');
};

get '/nested/path' => sub {
  my $c = shift;
  $c->notify(warn => 'nested');
  return $c->redirect_to('/');
};

get '/deep/in/the/:target' => sub {
  my $c = shift;
  $c->notify(warn => 'flasherror2000');
  $c->session(dont => 'be affected either');
  return $c->redirect_to('/' . $c->stash('target'));
};

get '/wood' => sub {
  my $c = shift;
  $c->notify(warn => 'yiahh');
  return $c->redirect_to('/damn')
};

$t->get_ok('/')->status_is(302)->content_is('');
$t->get_ok('/deep/in/the/damn')->status_is(302)->session_is('/dont' => 'be affected either');
$t->get_ok('/deep/in/the/wood')->status_is(302)->session_is('/dont' => 'be affected either');
$t->ua->max_redirects(1);
$t->get_ok('/')->status_is(200)->content_like(qr/flasherror/);
$t->get_ok('/deep/in/the/damn')->status_is(200)->content_like(qr/flasherror2000/);
$t->get_ok('/deep/in/the/wood')->status_is(302)->session_is('/dont' => 'be affected either');

$t->ua->max_redirects(2);
$t->get_ok('/deep/in/the/wood')->status_is(200)->content_like(qr/flasherror2000/)->content_like(qr/yiahh/);

$t->get_ok('/nested/path')
  ->status_is(200)
  ->content_like(qr/nested/)
  ->content_like(qr/flasherror/)
  ->session_is('/dont' => 'be affected');

$t->ua->max_redirects(0);
$t->get_ok('/')->status_is(302)->content_is('');
$t->get_ok('/damn')->status_is(200)->session_is('/dont' => 'be affected')->content_like(qr/flasherror/);
$t->get_ok('/damn')->status_is(200)->session_is('/dont' => 'be affected')->content_is('nope');


is ($co->notifications->scripts, (), 'Javascripts');
is ($co->notifications->styles, (), 'Styles');


done_testing;
__END__
