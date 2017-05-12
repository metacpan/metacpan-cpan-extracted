use strict;
use warnings;
use 5.010001;
use Test::Clustericious::Cluster;
use Test::More tests => 14;
use PlugAuth::Client;

die 'Clustericious 1.01 required' unless ($Clustericious::Client::VERSION//1.01) >= 1.01;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->extract_data_section(qr{^var/data});
$cluster->create_cluster_ok('PlugAuth');

my $client = PlugAuth::Client->new;

isa_ok $client, 'PlugAuth::Client';
$client->login('primus', 'primus');

# First check that the groups are right at start.
is_deeply [sort @{ $client->users('full1')}], [sort qw( foo bar baz primus )], "at start full1 = foo bar baz";
is_deeply [sort @{ $client->users('full2')}], [sort qw( foo bar baz primus )], "at start full2 = foo bar baz";
is_deeply [sort @{ $client->users('part1')}], [sort qw( foo )], "at start part1 = foo";
is_deeply [sort @{ $client->users('part2')}], [sort qw( baz )], "at start part2 = baz";

# next add bar to part1
eval { $client->group_add_user('part1', 'bar') };
diag $@ if $@;
is_deeply [sort @{ $client->users('part1') }], [sort qw( foo bar) ], "at start part1 = foo bar";

# next add to a non-existent group
is eval { $client->group_add_user('bogus', 'bar') }, undef, 'add to non existent group';
diag $@ if $@;
is $client->users('bogus'), undef, "add to non existent group doesn't create group";

# add bar and baz to part2
eval { $client->group_add_user('part2', 'bar') };
diag $@ if $@;
eval { $client->group_add_user('part2', 'foo') };
diag $@ if $@;
is_deeply [sort @{ $client->users('part2') }], [sort qw( foo bar baz) ], "part2 = foo bar baz";

# add foo to full1 and full2
eval { $client->group_add_user('full1', 'bar') };
diag $@ if $@;
is_deeply [sort @{ $client->users('full1') }], [sort qw( foo bar baz primus) ], "at start full1 = foo bar baz primus";
eval { $client->group_add_user('full2', 'bar') };
diag $@ if $@;
is_deeply [sort @{ $client->users('full2') }], [sort qw( foo bar baz primus) ], "at start full2 = foo bar baz primus";

# remove foo from full3 and full4
eval { $client->group_delete_user('full3', 'foo') };
diag $@ if $@;
is_deeply [sort @{ $client->users('full3') }], [sort qw( bar baz primus) ], "at start full3 = foo bar baz primus";
eval { $client->group_delete_user('full4', 'foo') };
diag $@ if $@;
is_deeply [sort @{ $client->users('full4') }], [sort qw( bar baz primus) ], "at start full4 = foo bar baz primus";

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
foo:kXdmy/G8gIr6E
bar:We/RNrO28Rd/E
baz:MsKrxsuIrbHLU
primus:73Dh1aWX7Sm2g


@@ var/data/group
full1: foo,bar,baz,primus
full2: *
part1: foo
part2: baz
full3: foo,bar,baz,primus
full4: *

@@ var/data/host


@@ var/data/resource
/group (accounts): primus

