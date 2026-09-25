use strict;
use warnings;
use Test::More;

use YAML::PP;
use Rex::Rancher::Agent;

# The agent config.yaml builder: same keys on rke2 and k3s, node-label shaped
# like the server's. Pure, no file I/O; nothing here says the node joins.

sub cfg { Rex::Rancher::Agent::_build_agent_config(@_) }

my %join = ( server => 'https://cp:9345', token => 'K10abc::server:xyz' );

is_deeply(cfg(%join), { server => 'https://cp:9345', token => 'K10abc::server:xyz' },
  'server and token only');

is_deeply(cfg(%join, node_name => 'w1', node_labels => [ 'role=gpu', 'zone=a' ]),
  { %join, 'node-name' => 'w1', 'node-label' => [ 'role=gpu', 'zone=a' ] },
  'node_name and node_labels arrayref');

is_deeply(cfg(%join, node_labels => 'role=gpu')->{'node-label'}, ['role=gpu'],
  'single node_labels string becomes a list');

is_deeply(cfg(%join)->{'node-label'}, undef, 'no node_labels: no node-label key');

# Same key as the server writes.
my $server = Rex::Rancher::Server::_build_server_config('rke2', 't', undef, undef, ['role=gpu'], 1);
is_deeply(cfg(%join, node_labels => ['role=gpu'])->{'node-label'}, $server->{'node-label'},
  'node-label matches the server config');

# What _write_config puts on disk reads back as the same structure.
my $want = cfg(%join, node_labels => [ 'a=b' ], node_name => 'w1');
is_deeply(YAML::PP->new->load_string(YAML::PP->new->dump_string($want)), $want,
  'YAML round trip');

done_testing;
