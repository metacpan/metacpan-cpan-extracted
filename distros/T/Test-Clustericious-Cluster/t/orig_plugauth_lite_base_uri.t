use strict;
use warnings;
use Test2::Bundle::More;
use Test::Mojo;
use Mojolicious::Lite;

plugin 'plug_auth_lite', auth => sub { 1 }, url => "/foo/bar/baz";

my $t = Test::Mojo->new;

my $url = $t->ua->server->url;

$t->get_ok($url->path('/auth'))
  ->status_is(404);

$t->get_ok($url->path('/auth'))
  ->status_is(404);

$t->get_ok($url->path('/foo/bar/baz/auth'))
  ->status_is(401)
  ->content_like(qr[authenticate], 'got authenticate header');

$url->userinfo('foo:bar');

$t->get_ok($url->path('/foo/bar/baz/auth'))
  ->status_is(200)
  ->content_is('ok', 'auth succeeded');

done_testing;
