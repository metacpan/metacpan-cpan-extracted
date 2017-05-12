use strict;
use warnings;
use Test2::Bundle::More;
use Test::Mojo;
use Mojolicious::Lite;

plan 11;

plugin 'plug_auth_lite', {
  auth => sub {
    my($user, $pass) = @_;
    return 1 if $user eq 'foo' && $pass eq 'bar';
    return;
  },
  authz => sub {
    my($user, $action, $resource) = @_;
    return 1;
  }, 
};

my $t = Test::Mojo->new;

$t->get_ok('/')
  ->status_is(404);

my $port = eval { $t->ua->server->url->port } // $t->ua->app_url->port;

$t->get_ok("http://127.0.0.1:$port/auth")
  ->status_is(401)
  ->content_like(qr[authenticate], 'got authenticate header');

$t->get_ok("http://foo:bar\@127.0.0.1:$port/auth")
  ->status_is(200)
  ->content_is('ok', 'auth succeeded');

$t->get_ok("http://foo:foo\@127.0.0.1:$port/auth")
  ->status_is(403)
  ->content_is('not ok', 'auth failed');
