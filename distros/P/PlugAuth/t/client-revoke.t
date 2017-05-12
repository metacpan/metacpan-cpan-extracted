use strict;
use warnings;
use Test::Clustericious::Log diag => 'FATAL', note => 'INFO..ERROR';
use Test::Clustericious::Cluster;
use Test::More tests => 8;
use PlugAuth::Client;

die 'Clustericious 1.05 required' unless ($Clustericious::Client::VERSION//1.05) >= 1.05;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client->new;

isa_ok $client, 'PlugAuth::Client';
$client->login('primus', 'primus');

is $client->authz('optimus', 'dies', 'alot'), 'ok',   "optimus dies a lot";
is $client->authz('bogus',   'dies', 'alot'), undef,  "bogus does NOT die a lot";

is $client->revoke('optimus', 'dies', 'alot'), 1,  'revoke returns 1';
is $client->revoke('bogus',   'dies', 'alot'), undef, 'revoke returns undef';

is $client->authz('optimus', 'dies', 'alot'), undef,  "optimus dies a lot";
is $client->authz('bogus',   'dies', 'alot'), undef,  "bogus does NOT die a lot";

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
primus:Keg/Qb1qXKY7M
optimus:Tz0NVrTUxIjeI


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
/ (accounts): primus
/alot (dies): optimus

