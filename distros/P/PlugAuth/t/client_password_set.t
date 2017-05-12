use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 5;
use PlugAuth::Client;

die 'Clustericious 1.01 required' unless ($Clustericious::Client::VERSION//1.01) >= 1.01;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client->new;

isa_ok $client, 'PlugAuth::Client';

$client->login('optimus', 'matrix');
ok $client->auth, 'client.login(optimus, matrix); client.auth';

$client->login('primus', 'cybertron');
ok eval { $client->change_password('optimus', 'matrix1') }, 'client.change_password(optimus, matrix1)';
diag $@ if $@;

$client->login('optimus', 'matrix1');
ok $client->auth, 'client.login(optimus, matrix1); client.auth';

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
primus:gRJIIIdOSXKEQ
optimus:wXxQZBUrszRkg


@@ var/data/group
# empty


@@ var/data/host
# empty


@@ var/data/resource
/user (change_password): primus

