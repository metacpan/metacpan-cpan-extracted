use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$url->userinfo('primus:spark');
$url->path('/grant');
$t->get_ok($url)
  ->status_is(200);

my $expected = [
  '/user/#u (change_password): #u',
  '/torpedo/photon (fire): kirk',
  '#/xyz (pdq): grimlock',
  '/grant (accounts): primus',
];

is_deeply $t->tx->res->json, $expected, 'GET /grant';

__DATA__
@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
user_file: <%= home %>/var/data/user
group_file: <%= home %>/var/data/group
host_file: <%= home %>/var/data/host
resource_file: <%= home %>/var/data/resource
plug_auth:
  url: <%= cluster->url %>


@@ var/data/user
primus:$apr1$Z7Ez/rcT$La4iCiCkNcNEb3vFtDdS60


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
/user/#u (change_password): #u
/torpedo/photon (fire): kirk
 #/xyz (pdq): grimlock
/grant (accounts): primus

