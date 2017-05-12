use strict;
use warnings;
use 5.010;
use Test::Clustericious::Log note => 'INFO..ERROR', diag => 'FATAL';
use Test::Clustericious::Cluster;
use EV;
use AE;
use AnyEvent::Finger::Client;
use PlugAuth::Client;
use Test::More tests => 6;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( PlugAuth ));

my $client = PlugAuth::Client->new;

$client->create_user(
  user     => 'foo',
  password => 'password1',
);

$client->create_group(group => 'autobot', users => '');
$client->create_group(group => 'good',    users => '');
$client->create_group(group => 'evil',    users => '');

$client->create_user(
  user     => 'bar',
  password => 'password1',
  groups   => 'autobot,good,evil',
);

$client->create_user(
  user     => 'baz',
  password => 'password1',
  groups   => 'autobot',
);

sub finger
{
  my($user) = @_;

  my $done = AE::cv;
  state $port;

  $port = $cluster->apps->[0]->config->plugins->[0]->{'PlugAuth::Plugin::Finger'}->{port}
    unless $port;
 

  AnyEvent::Finger::Client->new(
    hostname => 'localhost',
    port     => $port,
  )->finger($user, sub {
    $done->send(shift);
  }, on_error => sub {
    diag "FINGER ERROR $user: ", shift;
    $done->send([]);
  });
  
  $done->recv;
}

is_deeply finger('foo'),     ['user:foo','belongs to:','  foo'], 'finger foo@localhost';
is_deeply finger('bar'),     ['user:bar','belongs to:','  autobot, bar, evil, good'], 'finger foo@localhost';
is_deeply finger(''),        ['users:', '  bar', '  baz', '  foo', 'groups:', '  autobot', '  evil', '  good'], 'finger @localhost';
is_deeply finger('autobot'), ['group:autobot', 'members:', '  bar, baz'], 'finger autobot@localhost';
is_deeply finger('bogus'),   ['no such user or group'], 'finger bogus@localhost';

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
plugins:
  - PlugAuth::Plugin::Finger:
      port: <%= IO::Socket::INET->new(Listen => 5, LocalAddr => '127.0.0.1')->sockport %>
