use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 11;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$t->post_ok("$url/test/setup/basic");

$t->post_ok("$url/grant/optimus/view/service/filefeed")
  ->status_is(200);

$t->get_ok("$url/authz/user/optimus/view/service/filefeed")
  ->status_is(200);
$t->get_ok("$url/authz/user/optimus/view/service/filefeed/foo/bar/baz.png")
  ->status_is(200);

# wtf?
$t->get_ok("$url/grant");

$t->get_ok("$url/authz/resources/optimus/view/.*");

is_deeply $t->tx->res->json, ['/service/filefeed'], 'avoid autovivification';

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
plugins:
  - PlugAuth::Plugin::Test: {}

