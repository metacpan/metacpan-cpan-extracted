#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojolicious;
use utf8;

use Test::More;
use Test::Mojo;
use Mojo::Util 'url_escape';


my $CONFIG_KEY = 'redirect_host';

my $ROUTE       = '/f/b/д';
my $URL         = "$ROUTE?1=ы";
my $EXCEPT_PATH = '/robots.txt';
my $HOST        = 't.z';
my $OK          = 'http://t.z/f/b/%D0%B4?1=%D1%8B';


# permanent redirection (301) to the same url
DEFAULTS: {
  my $t   = Test::Mojo->new();
  my $app = Mojolicious->new();

  $app->plugin('RedirectHost', host => $HOST);
  $app->routes->get($ROUTE => sub { shift->render(text => 'ok') });

  $t->app($app);

  # redirect mirrors
  $t->get_ok($URL, {Host => 'mirror223'})->status_is(301)
    ->header_is(Location => $OK);

  # does not need a redirection
  $t->get_ok($URL, {Host => $HOST})->status_is(200)->content_is('ok');
}


RE_302: {
  my $t   = Test::Mojo->new();
  my $app = Mojolicious->new();

  $app->plugin('RedirectHost', host => $HOST, code => 302);
  $app->routes->get($ROUTE => sub { shift->render(text => 'ok') });

  $t->app($app);

  # redirect mirrors
  $t->get_ok($URL, {Host => 'mirror223'})->status_is(302)
    ->header_is(Location => $OK);
}

EXCEPT_ROBOTS: {
  my $t   = Test::Mojo->new();
  my $app = Mojolicious->new();

  $app->plugin('RedirectHost', host => $HOST, er => 1);
  $app->routes->get($ROUTE    => sub { shift->render(text => 'ok') });
  $app->routes->get('/robots' => sub { shift->render(text => 'robots') });

  $t->app($app);

  # redirect mirrors
  $t->get_ok($URL, {Host => 'mirror223'})->status_is(301)
    ->header_is(Location => $OK);

  # /robots.txt is an exception, don't redirect
  $t->get_ok($EXCEPT_PATH, {Host => 'mirror123'})->status_is(200)
    ->content_is('robots');
  $t->get_ok("$EXCEPT_PATH?ffff", {Host => 'mirror123'})->status_is(200)
    ->content_is('robots');

  #exception does not match
  $t->get_ok('/robots.txt2', {Host => 'mirror123'})->status_is(301)
    ->header_is(Location => "http://$HOST/robots.txt2");

  #exception does not match
  $t->get_ok('/2/robots.txt', {Host => 'mirror123'})->status_is(301)
    ->header_is(Location => "http://$HOST/2/robots.txt");
}

# app->config->{redirect_host}
CONFIG: {
  my $t   = Test::Mojo->new();
  my $app = Mojolicious->new();

  $app->config($CONFIG_KEY => {host => $HOST, code => 303, er => 1});
  $app->plugin('RedirectHost');

  $t->app($app)->get_ok('/foo?bar', {Host => 'mirror223'})->status_is(303)
    ->header_is(Location => "http://$HOST/foo?bar");

}

done_testing;
