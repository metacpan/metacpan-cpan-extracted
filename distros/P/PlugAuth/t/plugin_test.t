use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 22;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

sub url ($$@) {
  my($url, $path,@rest) = @_;
  $url = $url->clone;
  $url->path($path);
  wantarray ? ($url, @rest) : $url;
}

$url->userinfo('primus:spark');
$t->get_ok(url $url, "/auth")
  ->status_is(403);

$url->userinfo(undef);
$t->post_ok(url $url, "/test/setup/basic")
  ->status_is(200);

$url->userinfo('primus:spark');
$t->get_ok(url $url, "auth")
  ->status_is(200);

$url->userinfo('optimus:matrix');
$t->get_ok(url $url, "auth")
  ->status_is(200);

$url->userinfo(undef);
$t->get_ok(url $url, "users/admin")
  ->status_is(200)
  ->json_is('/0', 'primus');

$t->get_ok(url $url, "authz/user/primus/accounts/user")
  ->status_is(200);

$t->get_ok(url $url, "authz/user/optimus/accounts/user")
  ->status_is(403);

$url->userinfo('primus:spark');
$t->get_ok(url $url, "grant")
  ->status_is(200);

$url->userinfo(undef);
$t->post_ok(url $url, "test/setup/reset")
  ->status_is(200);

$url->userinfo('primus:spark');
$t->get_ok(url $url, "auth")
  ->status_is(403);

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
plug_auth:
  url: <%= cluster->url %>
plugins:
  - PlugAuth::Plugin::Test: {}

