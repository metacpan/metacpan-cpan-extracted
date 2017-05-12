#!/usr/bin/env perl
use Mojolicious::Lite;

plugin 'Module', {
  conf_dir => './apps/lite_app/config',
  mod_dir => './apps/lite_app/module'
};

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

###

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/')->status_is(200)->content_like(qr/Welcome to the Mojolicious/);
$t->get_ok('/test1')->status_is(200)->content_like(qr/test1/);
$t->get_ok('/test2')->status_is(200)->content_like(qr/test2/);
$t->get_ok('/test3')->status_is(404);

done_testing();

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
Welcome to the Mojolicious real-time web framework!

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
