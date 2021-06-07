#!/usr/bin/env perl
use Mojolicious::Lite;
use Test::More;
use Test::Mojo;

use_ok 'Mojolicious::Plugin::CHI::Route';

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('CHI' => {
  xyz => {
    driver => 'Memory',
    global => 1
  }
});

$app->plugin('CHI::Route' => {
  namespace => 'xyz',
  expires_in => '3 hours'
});

my $call = 1;

get('/cool')->requires('chi' => { key => sub { 'abc' } })->to(
  cb => sub {
    my $c = shift;
    $c->res->headers->header('X-Funny' => 'hi');
    return $c->render(
      text => 'works: cool: ' . $call++,
      'format' => 'txt'
    );
  }
);

get('/cool')->to(
  cb => sub {
    return shift->render(
      text => 'works: shouldn\'t',
      'format' => 'txt'
    );
  }
);

get '/foo' => ('chi' => {}) => sub {
  return shift->render(
    status => 404,
    text => 'works: not',
    'format' => 'txt'
  );
};


$t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: cool: 1')
  ->header_is('X-Funny','hi')
  ->header_is('Server','Mojolicious (Perl)')
  ->header_is('X-Cache-CHI', undef)
  ;

$t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: cool: 1')
  ->header_is('X-Funny','hi')
  ->header_is('Server','Mojolicious (Perl)')
  ->header_is('X-Cache-CHI','1')
  ;

$t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: cool: 1')
  ->header_is('X-Funny','hi')
  ->header_is('X-Cache-CHI','1')
  ;

$t->get_ok('/foo')
  ->status_is(404)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: not')
  ->header_is('X-Cache-CHI',undef)
  ;

$t->get_ok('/foo')
  ->status_is(404)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('works: not')
  ->header_is('X-Cache-CHI',undef)
  ;

get('/bar')->requires('chi' => { key => 'bar', expires_in => '3 min'})->to(
  cb => sub {
    return shift->render(
      text => 'Should expire after 3 minutes',
      'format' => 'txt'
    );
  }
);

$t->get_ok('/bar')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->content_is('Should expire after 3 minutes')
  ->header_is('X-Cache-CHI',undef)
  ;


$t->get_ok('/bar')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->text_is('#error','')
  ->content_is('Should expire after 3 minutes')
  ->header_is('X-Cache-CHI', 1)
  ;

my $c = $t->app->build_controller;
my $diff = $c->chi('xyz')->get_expires_at('bar') - time;
ok($diff > 0, 'key will expire in the future');
ok($diff <= 180, 'Key will expire in <= 3 minutes');

$diff = $c->chi('xyz')->get_expires_at('abc') - time;
ok($diff > 0, 'key will expire in the future');
ok($diff > 180, 'Key will expire in <= 3 hours');
ok($diff > 2 * 60 * 60, 'Key will expire in <= 3 hours');
ok($diff <= 3 * 60 * 60, 'Key will expire in <= 3 hours');


get('/ownkey')->requires('chi' => {
  key => sub {
    return shift->req->headers->header('random') // '000'
  }
})->to(
  cb => sub {
    my $c = shift;
    my $random = $c->req->headers->header('random') // '111';
    return $c->render(
      text => 'Has the name "'.$random.'"',
      'format' => 'txt'
    );
  }
);

$t->get_ok('/ownkey' => { random => 'okay'})
  ->status_is(200)
  ->text_is('#error','')
  ->content_is('Has the name "okay"')
  ;

my $value = $c->chi('xyz')->get('okay')->{body};
is($value, 'Has the name "okay"');

# Check with ETag
my $etag = $t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->text_is('#error','')
  ->content_is('works: cool: 1')
  ->header_is('X-Cache-CHI', 1)
  ->header_like('ETag',qr!^W/\"[^"]+?\"$!)
  ->tx->res->headers->header('ETag');
  ;

$t->get_ok('/cool' => { 'If-None-Match' => $etag })
  ->status_is(304)
  ->content_is('')
  ;

# Check with Last-Modified
my $lmod = $t->get_ok('/cool')
  ->status_is(200)
  ->content_type_is('text/plain;charset=UTF-8')
  ->text_is('#error','')
  ->content_is('works: cool: 1')
  ->header_is('X-Cache-CHI', 1)
  ->header_like('Last-Modified', qr!^.{3},!)
  ->tx->res->headers->header('Last-Modified');
  ;

$t->get_ok('/cool' => { 'If-Modified-Since' => $lmod })
  ->status_is(304)
  ->content_is('')
  ;

get('/ignore')->requires('chi' => {
  key => sub {
    return '' #undef
  }
})->to(
  cb => sub {
    my $c = shift;
    return $c->render(
      text => 'hui',
      'format' => 'txt'
    );
  }
);

$t->get_ok('/ignore')
  ->content_is('hui')
  ->header_exists_not('X-Cache-CHI')
  ;

$t->get_ok('/ignore')
  ->content_is('hui')
  ->header_exists_not('X-Cache-CHI')
  ;

done_testing;
