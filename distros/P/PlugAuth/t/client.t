use strict;
use warnings;
use 5.010001;
use Test::Clustericious::Log diag => 'FATAL', note => 'INFO..ERROR';
use Test::Clustericious::Cluster;
use Test::More  tests => 17;
use PlugAuth::Client;

die 'Clustericious 1.05 required' unless ($Clustericious::Client::VERSION//1.05) >= 1.05;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client->new;

isa_ok $client, 'PlugAuth::Client';

# The basics
subtest basics => sub {
  is $client->welcome, 'welcome to plug auth', 'client.welcome';
  is $client->version->[0], PlugAuth->VERSION // 'dev', 'client.version';
};

# Good password
$client->login('optimus', 'matrix');
ok $client->auth,  'client.login(optimus, matrix); client.auth';

# Bad password
$client->login('bogus', 'bogus');
ok !$client->auth, 'client.login(bogus, bogus); client.auth';

# Good authorization
ok $client->authz('optimus', 'open', '/matrix'), 'client.authz(optimus, open, /matrix)';
ok $client->authz('optimus', 'open', 'matrix'), 'client.authz(optimus, open, matrix)';

# Bad authorization
ok !$client->authz('galvatron', 'open', '/matrix'), 'client.authz(galvatron, open, /matrix)';

is $client->host_tag('1.2.3.4', 'trusted'), 'ok', 'client.host_tag';
is $client->host_tag('1.1.1.1', 'trusted'), undef, 'client.host_tag';

is_deeply [sort @{ $client->groups('optimus') }], [sort qw( optimus transformer autobot)], 'client.groups(optimus)';
is_deeply [sort @{ $client->groups('starscream') }], [sort qw( starscream transformer decepticon)], 'client.groups(starscream)';

is_deeply [sort @{ $client->actions } ], [sort qw( open fly lead transform )], 'client.actions';
is_deeply [sort @{ $client->user }], [sort qw( optimus grimlock starscream galvatron )], 'client.user';
is_deeply [sort @{ $client->group }], [sort qw( transformer autobot decepticon )], 'client.group';

is_deeply [sort @{ $client->users('autobot') }], [sort qw( optimus grimlock )], 'client.users(autobot)';

my %table;
foreach my $action (@{ $client->actions })
{
  my $resources = $client->resources('galvatron', $action, '.*');
  $table{$action} = $resources if @$resources > 0;
}

is_deeply 
  eval { $client->action_resources('galvatron') }//{}, 
  { fly => ['/sky'], lead => ['/troops'], 'transform' => ['/body'] },
  'client.action_resources';
diag $@ if $@;

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
optimus:IOuzB7YXmBSZk
grimlock:YyRXFbRpJiCLk
galvatron:3l17w9z1qOGxo
starscream:lLUnXzT8Zzozs


@@ var/data/group
transformer: *
autobot: optimus,grimlock
decepticon: galvatron,starscream


@@ var/data/host
1.2.3.4: trusted
5.6.7.8: trusted


@@ var/data/resource
/matrix (open): optimus
/sky (fly): galvatron,starscream
/troops (lead): galvatron,optimus
/body (transform): transformer

