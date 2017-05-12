#!/usr/bin/env perl
use Test::Mojo::Session;
use Test::More;
use Mojolicious::Lite;

use lib 't';

my $t = Test::Mojo::Session->new;

my $app = $t->app;

$app->plugin('Notifications' => {
  'Plugin::MyEngine' => 1
});

my $co = $app->build_controller;

$co->notify(warn => q/That's a warning/);
$co->notify(error => q/That's an error message/);
$co->notify(success => q/That's <a success story/);
my $note = $co->notifications('Plugin::MyEngine');

like($note, qr/notifications\.push/s, 'Notification is fine');
like($note, qr/warn.+?error.+?success/s, 'Notification is fine');
like($note, qr/warning.+?error message.+?success story/s, 'Notification is fine');


done_testing;
__END__
