use strict;
use warnings;
use Test2::Bundle::More;
use Test::Mojo;
use Mojolicious::Lite;

plan 14;

plugin 'plug_auth_lite';

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(404);

my $port = eval { $t->ua->server->url->port } // $t->ua->app_url->port;

$t->get_ok("http://127.0.0.1:$port/auth")
  ->status_is(401)
  ->content_like(qr[authenticate], 'got authenticate header');

$t->get_ok("http://foo:bar\@127.0.0.1:$port/auth")
  ->status_is(403)
  ->content_is('not ok', 'auth failed');

$t->get_ok("http://foo:foo\@127.0.0.1:$port/auth")
  ->status_is(403)
  ->content_is('not ok', 'auth failed');

$t->get_ok("/authz/user/foo/bar/baz")
  ->status_is(200)
  ->content_is('ok', 'authz succeeded');

