#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::ByteStream 'b';

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('Notifications' => {
  JSON => 1,
#  HTML => 1
});

my $co = $app->build_controller;

ok(!$co->notifications('json'), 'No notification yet');

$co->notify(warn => q/That's a warning/);
$co->notify(error => q/That's an error message/);
$co->notify(success => q/That's <a success story/);
$co->notify(success => b('This is a bytestream'));

is_deeply(
  $co->notifications('json',{ text =>  'cool'}),
  { text => 'cool',
    notifications => [
      [warn => q/That's a warning/],
      [error => q/That's an error message/],
      [success => q/That's <a success story/],
      [success => q/This is a bytestream/]
    ]
  },
  'Notification is fine');

$co->notify(warn => 'test');
is_deeply($co->notifications('json'), { notifications => [[warn => 'test']]}, 'Empty object');


get '/damn' => sub {
  my $c = shift;
  my $obj = { text => 'my obj' };
  return $c->render(json => $c->notifications('json', $obj));
};

get '/damn_array' => sub {
  my $c = shift;
  $c->notify(warn => 'Yeah1');
  $c->notify(error => 'Yeah2');
  my $obj = [qw/a b c/];
  return $c->render(json => $c->notifications('json', $obj));
};

get '/' => sub {
  my $c = shift;
  $c->notify(warn => 'flasherror');
  return $c->redirect_to('/damn');
};

$t->get_ok('/')->status_is(302)->content_is('');
$t->ua->max_redirects(1);

$t->get_ok('/')->status_is(200)->json_has('/text' => 'my obj');

$t->ua->max_redirects(0);

$t->get_ok('/')->status_is(302)->content_is('');

$t->get_ok('/damn')->status_is(200)->json_has('/text' => 'my obj')
  ->json_hasnt('/notifications/warn' => 'flasherror');

$t->get_ok('/damn_array')
  ->status_is(200)
  ->json_has('/0' => 'a')
  ->json_has('/1' => 'b')
  ->json_has('/2' => 'c')
  ->json_has('/3/notifications/0' => [warn => 'Yeah1'])
  ->json_has('/3/notifications/0' => [error => 'Yeah2']);

is ($co->notifications->scripts, (), 'Javascripts');
is ($co->notifications->styles, (), 'Styles');

done_testing;

__END__
