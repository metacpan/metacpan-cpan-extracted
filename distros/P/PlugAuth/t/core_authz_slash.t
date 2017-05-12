use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 14;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');
my($url) = map { $_->clone } @{ $cluster->urls };
my $t = $cluster->t;

$t->get_ok("$url/authz/user/primus/accounts/foo/bar/baz")
  ->status_is(200)
  ->content_is('ok');
$t->get_ok("$url/authz/user/optimus/accounts/foo/bar/baz")
  ->status_is(403);

$t->get_ok("$url/authz/user/primus/accounts/")
  ->status_is(200);
$t->get_ok("$url/authz/user/optimus/accounts/")
  ->status_is(403);

$t->get_ok("$url/authz/user/primus/accounts")
  ->status_is(200);
$t->get_ok("$url/authz/user/optimus/accounts")
  ->status_is(403);

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
primus:$apr1$iC/RsYoC$EPKPSAC7PLRsj3k/o0Yjr/
optimus:$apr1$strYMlmb$iuk6sbN10w02H9ejDM0Xx/


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
/ (accounts): primus
/user (change_password): primus

