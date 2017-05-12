use strict;
use warnings;
use 5.010001;
use Test::More;
BEGIN {
  plan skip_all => 'test requires Test::Clustericiou::Config'
    unless eval q{ use Test::Clustericious::Config; 1 };
  eval q{ use Test::Clustericious::Log };
  diag $@ if $@;
  plan skip_all => 'test requires Test::Clustericious::Cluster'
    unless eval q{ use Test::Clustericious::Cluster; 1 };
  plan skip_all => 'test requires PlugAuth 0.20_03'
    unless eval q{
      use PlugAuth;
      use PlugAuth::Plugin::FlatAuth;
      PlugAuth::Plugin::FlatAuth->can('create_user_cb');
    };
}
use PlugAuth::Client;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( PlugAuth ));

my $client = PlugAuth::Client->new;
#$client->client($cluster->t->ua);

$client->create_group( group => 'foo', users => '' );
eval { 
  $client->create_user( user => 'bar', password => 'password', groups => 'foo' );
};
diag $@ if $@;

is_deeply [ sort @{ $client->groups('bar') // []} ], [qw( bar foo )], "groups = bar foo";

done_testing();

__DATA__

@@ etc/PlugAuth.conf
---
url: <%= cluster->url %>
