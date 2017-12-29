#!/usr/bin/env perl
use strict;
use warnings;
# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER}  = 'Mojo::IOWatcher';
  $ENV{MOJO_MODE}       = 'testing';
};

use Test::Mojo;
use Test::More;
use Mojolicious::Lite;

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin(Config => {
  default => {
    PubSubHubbub => {
      hub => 'https://myhub.example.com/',
      lease_seconds => 2000
    }
  }
});

$app->plugin('Util::Callback');
$app->plugin('Util::Endpoint');
$app->plugin('PubSubHubbub' => {
      lease_seconds => 2005
});

is($app->pubsub->_plugin->hub, 'https://myhub.example.com/', 'get plugin');
is($app->pubsub->_plugin->lease_seconds, 2000, 'get plugin');

ok(!$app->routes->route->pubsub('hub'), 'Hub is currently not supported');



done_testing;
__END__
