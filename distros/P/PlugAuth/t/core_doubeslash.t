use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 7;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$t->get_ok("$url/authz/resources/grimlock/view//archiveset/\\d+")
  ->status_is(200);

is_deeply $t->tx->res->json, [qw( /archiveset/1 /archiveset/3 )], "grimlock";

$t->get_ok("$url/authz/resources/prime/view//archiveset/\\d+")
  ->status_is(200);

is_deeply $t->tx->res->json, [qw( /archiveset/2 )], "prime";

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
grimlock:VA5WEetmxpZko
prime:K5VR4PrwbI6Q.


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
/archiveset/1 (view): grimlock
/archiveset/2 (view): prime
/archiveset/3 (view): grimlock

