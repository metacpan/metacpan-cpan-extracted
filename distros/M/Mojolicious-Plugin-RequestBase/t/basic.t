#!/usr/bin/env perl
use Mojo::Base -strict;
use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

my @before;

plugin 'RequestBase';

hook before_dispatch => sub {
  my $c = shift;
  @before = ($c->url_for->to_abs, $c->url_for($c->req->url->path)->to_abs);
};

get '/' => sub {
  my $c = shift;
  $c->render(text => $c->url_for('login'));
};

get '/redirect' => sub {
  my $c    = shift;
  my $path = $c->param('path');
  my $url  = $c->url_for($path ? ($path) : ())->to_abs;
  $c->redirect_to("http://example.com?from=$url");
};

get '/some/path' => sub {
  my $c = shift;
  $c->render(
    json => {
      canonicalize     => $c->req->url->path->canonicalize,
      abs_canonicalize => $c->url_for->to_abs->path->canonicalize,
    }
  );
  },
  'some_path';


get '/login', 'login';

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('/login');

$t->get_ok('/', {'X-Request-Base' => 'http://example.com/foo'})->status_is(200)
  ->content_is('/foo/login');

$t->get_ok('/redirect', {'X-Request-Base' => 'http://mojolicio.us/foo'})
  ->status_is(302)
  ->header_is(
  Location => 'http://example.com?from=http://mojolicio.us/foo/redirect');

$t->get_ok('/redirect?path=some_path',
  {'X-Request-Base' => 'http://mojolicio.us/foo'})->status_is(302)
  ->header_is(
  Location => 'http://example.com?from=http://mojolicio.us/foo/some/path');

$t->get_ok('/some/path', {'X-Request-Base' => 'http://example.com/foo'})
  ->status_is(200)->json_is('/abs_canonicalize', '/foo/some/path')
  ->json_is('/canonicalize', '/some/path');

is $before[0], "http://example.com/foo",           "before_dispatch url_for";
is $before[1], "http://example.com/foo/some/path", "before_dispatch url";

$t->get_ok('/redirect?path=some_path', {'X-Request-Base' => '/foo'})
  ->status_is(302)
  ->header_like(
  Location => qr(example\.com\?from=http.+27.0.0.1:\d+\/foo\/some\/path));


done_testing;
