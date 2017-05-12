
use strict;
use Test::More 0.98;
use FindBin;
use lib "$FindBin::Bin/pliftapp/lib";
use Test::Mojo;
use XML::LibXML::jQuery;

# Load application class
my $t = Test::Mojo->new('PliftApp');
$t->ua->max_redirects(1);

my $app = $t->app;
$app->defaults( username => 'Cafe' );

# my $c = $app->build_controller;
# $c->render('index');
# diag $c->res->body;

# index tempate
$t->get_ok('/index')
  ->status_is(200)
  ->element_exists('#main-content')
  ->content_like(qr/Hello, Cafe/);

# inline template
$t->get_ok('/inline')
  ->status_is(200)
  ->element_exists('#inline-content')
  ->content_like(qr/Hello, Cafe/);

# snippet helper object
$t->get_ok('/snippet')
  ->status_is(200)
  ->content_like(qr/PliftApp/);

# site layout
$t->get_ok('/layout')
  ->status_is(200)
  ->element_exists('head')
  ->element_exists('body')
  ->element_exists('header')
  ->element_exists('footer')
  ->element_exists('#content #main-content')
  ->content_like(qr/Hello, Cafe/);

# meta.layout
$t->get_ok('/meta')
  ->status_is(200)
  ->content_like(qr/<title>Title from meta/)
  ->element_exists('body')
  ->element_exists('#content #main-content')
  ->content_like(qr/Hello, Cafe/);

# x-link
subtest 'x-link' => sub {
    $t->get_ok('/tag/link')
      ->content_unlike(qr!<x-link!)
      ->content_like(qr!<a href="/tag/link">Reload</a>!)
      ->content_like(qr!<a href="/foo">Foo link</a>!);
};

# x-csrf-field
subtest 'x-csrf-field' => sub {
    $t->get_ok('/tag/csrf')
      ->content_unlike(qr!<x-csrf-field!);

    my $dom = j($t->tx->res->body);

    is $dom->find('input[name="csrf_token"]')->attr('type'), 'hidden';
    like $dom->find('input[name="csrf_token"]')->attr('value'), qr/[a-f0-9]+/;
    is $dom->find('input[name="my_csrf_token"]')->attr('type'), 'hidden';
};

done_testing();
