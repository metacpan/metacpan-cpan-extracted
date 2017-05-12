#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('Notifications' => {
  Alertify => 1
});

my $co = $app->build_controller;

ok(!$co->notifications('alertify'), 'No alert');

$co->notify(warn => 'warning');
$co->notify(error => q/That's an error/);
$co->notify(success => q/That's <a success/);

my $notes = $co->notifications('alertify');
like($notes, qr/warn.+?error.+?succes/s, 'Notification is fine');
like($notes, qr/noscript/s, 'Notification is fine');
ok(!$co->notifications('alertify'), 'No notifications');

# $c->include_notification_center
get '/damn' => sub {
  my $c = shift;
  return $c->render(text => $c->notifications('alertify') || 'nope');
};

get '/' => sub {
  my $c = shift;
  $c->notify(warn => 'flasherror');
  return $c->redirect_to('/damn');
};

$t->get_ok('/')->status_is(302)->content_is('');
$t->ua->max_redirects(1);
$t->get_ok('/')->status_is(200)->content_like(qr/flasherror/);
$t->ua->max_redirects(0);
$t->get_ok('/')->status_is(302)->content_is('');
$t->get_ok('/damn')->status_is(200)->content_like(qr/flasherror/);
$t->get_ok('/damn')->status_is(200)->content_is('nope');


$co->notify(warn => 'test');
$co->notify(error => { timeout => 2000 } => q/That's an error/);
$co->notify(success => q/That's <an error/);
$co->notify(trial => { timeout => 23 } => q/That's <an error/);

my $string = $co->notifications('alertify' => 'bootstrap', -no_include);
# Test this using Mojo::JSON::Pointer
like($string, qr/\"That\'s an error\",\"error\",2000/, 'JSON');
like($string, qr/log\(\"That\'s \<an error\",\"success\"/, 'JSON');
like($string, qr/log\(\"That\'s \<an error\",\"trial\",23/, 'JSON');

is(($co->notifications->scripts)[0], '/alertify/alertify.min.js', 'Javascripts');
is(($co->notifications->styles)[0], '/alertify/alertify.core.css', 'Styles');
is(($co->notifications->styles)[1], '/alertify/alertify.default.css', 'Styles');

done_testing;
__END__
