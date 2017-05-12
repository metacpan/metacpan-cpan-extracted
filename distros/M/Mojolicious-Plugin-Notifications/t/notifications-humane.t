#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('Notifications' => {
  Humane => 1
});

my $co = $app->build_controller;

like($co->notifications(humane => [qw/warn/]), qr/humane-libnotify-warn/, 'No center');

$co->notify(warn => 'warning');
$co->notify(error => q/That's an error/);
$co->notify(success => q/That's <a success/);

my $notes = $co->notifications('humane');
like($notes, qr/warn.+?error.+?succes/s, 'Notification is fine');
like($notes, qr/noscript/s, 'Notification is fine');
ok(!$co->notifications('humane'), 'No notifications');

# $c->include_notification_center
get '/damn' => sub {
  my $c = shift;
  return $c->render(text => $c->notifications('humane') || 'nope');
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
$co->notify(success => { clickToClose => Mojo::JSON->true } => q/That's <an error/);
$co->notify(trial => { clickToClose => Mojo::JSON->true, timeout => 23 } => q/That's <an error/);

my $string = $co->notifications('humane' => 'jackedup');
# Test this using Mojo::JSON::Pointer
like($string, qr/addnCls\:\'humane\-jackedup\-warn\'/, 'JSON');
like($string, qr/\"That\'s an error\", \{\"timeout\"\:2000\}/, 'JSON');
like($string, qr/success\(\"That\'s \<an error\", \{\"clickToClose\"\:true\}/, 'JSON');
like($string, qr/(?:"timeout":23,|,"timeout":23)/, 'JSON');

is (($co->notifications->scripts)[0], '/humane/humane.min.js', 'Javascripts');
is (($co->notifications->styles)[0], '/humane/libnotify.css', 'Styles');

done_testing;
__END__
