#!/usr/bin/env perl
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

my $t = Test::Mojo->new;

my $app = $t->app;

$app->plugin('Notifications' => {
  Humane => 1,
  Alertify => {
    base_class => 'bootstrap'
  }
});

my $co = Mojolicious::Controller->new;
$co->app($app);

is (($co->notifications->scripts)[0], '/alertify/alertify.min.js', 'Javascripts');
is (($co->notifications->scripts)[1], '/humane/humane.min.js', 'Javascripts');
ok (!($co->notifications->scripts)[2], 'No more Javascripts');

is (($co->notifications->styles)[0], '/alertify/alertify.bootstrap.css', 'Styles');
is (($co->notifications->styles)[1], '/alertify/alertify.core.css', 'Styles');
is (($co->notifications->styles)[2], '/humane/libnotify.css', 'Styles');
ok (!($co->notifications->styles)[3], 'No more Styles');

done_testing;
__END__
