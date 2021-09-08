#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::CHI::Route';

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('CHI');

$app->plugin('CHI::Route' => {
  namespace => 'xyz'
});

my $call = 1;

get('/cool')->requires('chi' => { key => sub { 'abc' } })->to(
  cb => sub {
    my $c = shift;
    $c->res->headers->header('X-Funny' => 'hi');
    return $c->render(
      text => 'works: cool: ' . $call++,
      format => 'txt'
    );
  }
);

my $err = $t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: cool: 1')
  ->header_is('X-Funny','hi')
  ->header_is('X-Cache-CHI', undef)
  ->tx->res->dom->at('#error')
  ;

if ($err) {
  is($err->text, '');
};

$err = $t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: cool: 2')
  ->header_is('X-Funny','hi')
  ->header_is('X-Cache-CHI', undef)
  ->tx->res->dom->at('#error')
  ;

if ($err) {
  is($err->text, '');
};

done_testing;
