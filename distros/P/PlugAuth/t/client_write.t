use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More tests => 26;
use PlugAuth::Client;

die 'Clustericious 1.01 required' unless ($Clustericious::Client::VERSION//1.01) >= 1.01;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client->new;

isa_ok $client, 'PlugAuth::Client';

$client->login('primus', 'cybertron');
is_deeply [grep /^thrust$/, @{ $client->user }], [], 'user thrust does not exist';
ok $client->create_user(user => 'thrust', password => 'foo'), 'client.create_user(user: thrust, password: foo)';
is_deeply [grep /^thrust$/, @{ $client->user }], ['thrust'], 'user thrust was created';

is_deeply [grep /^wheelie$/, @{ $client->user }], ['wheelie'], 'user wheelie does exist';
ok $client->delete_user(user => 'wheelie'), 'client.delete_user(wheelie)';
is_deeply [grep /^wheelie$/, @{ $client->user }], [], 'user wheelie has been deleted';

is_deeply [grep /^seekers$/, @{ $client->group }], [], 'group seekers does not exist yet';
ok $client->create_group(group => 'seekers', users => 'starscream,thundercracker,skywarp,thrust,ramjet,dirge'), 'client.create_group(group: seekers, ...)';
is_deeply [grep /^seekers$/, @{ $client->group }], ['seekers'], 'group seekers has been created';
is_deeply [sort @{ $client->users('seekers') }], [sort qw( starscream thundercracker skywarp thrust ramjet dirge )], 'check seeker membership';

is_deeply [sort @{ $client->users('primes') }], ['optimus'], 'primes includes just optimus';
ok $client->update_group('primes', '--users' => 'optimus,rodimus'), 'add rodimus to the list of primes';
is_deeply [sort @{ $client->users('primes') }], [sort qw( optimus rodimus )], 'primes includes just optimus';

is_deeply [grep /^primes$/, @{ $client->group }], ['primes'], 'group primes does exist';
ok $client->delete_group('primes'), 'client.delete(primes)';
is_deeply [grep /^primes$/, @{ $client->group }], [], 'group primes has been deleted';

is_deeply [grep /^open$/, @{ $client->actions }], [], 'no such action yet, open';
ok $client->grant('optimus', 'open', 'matrix'), 'client.grant(optimus, open, matrix)';
is_deeply [grep /^open$/, @{ $client->actions }], ['open'], 'no such action yet, open';

is_deeply [sort @{ $client->users('cars') }], [sort qw( kup hotrod )], 'cars group = kup and hotrod';
ok $client->update_group('cars', { users => 'kup,hotrod,blurr' }), 'client.update_group(cars, ...)';
is_deeply [sort @{ $client->users('cars') }], [sort qw( kup hotrod blurr )], 'cars group = kup, hotrod and blurr';

is $client->resources('primus', 'accounts', '/')->[0], '/', 'client.resource 1';
is $client->resources('optimus', 'open', '/')->[0], '/matrix', 'client.resource 2';

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
primus:mVDnWYrxvX7n.
optimus:iqDjzhjKg27bI
rodimus:5bV4rqqBs7Rg.
kup:1bfYIuBAO6lP.
hotrod:1mAPk18xWKLLo
blurr:N5o2ww3lILwBM
megatron:wmEJgdt3i.yDA
starscream:PlWBGTu1oC9D6
skywarp:bWsMKiqibm3IE
thundercracker:8RvT7LoUzHpRw
ramjet:MYt7UBayHLEoo
dirge:S0vEsoRREaorI
wheelie:Bb7B2DrqelsDs


@@ var/data/group
primes: optimus
cars: kup,hotrod


@@ var/data/host


@@ var/data/resource
/ (accounts): primus


