use strict;
use warnings;
use Test::Clustericious::Log;
use Test::Clustericious::Config;
use Test::Clustericious::Cluster;
use Test::More tests => 6;

create_directory_ok 'data';

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( PlugAuth ));

my $app = $cluster->apps->[0];
eval { 
  $app->auth->create_user('roger', 'rabit');
  $app->auth->create_user('bugs', 'bunny');
  $app->authz->create_group('foo', 'roger');
};
diag $@ if $@;

my $url = $cluster->url;
my $t   = $cluster->t;

$url->userinfo('bugs:bunny');
$url->path('/auth');
$t->get_ok($url)
  ->status_is(200);

$url->userinfo('roger:rabit');
$t->get_ok($url)
  ->status_is(403);

__DATA__

@@ etc/PlugAuth.conf
---
% use File::Touch;
url: <%= cluster->url %>
plugins:
  - PlugAuth::Plugin::DisableGroup:
      group: foo
  - PlugAuth::Plugin::FlatAuth: {}

% foreach my $file (qw( user group resource )) {
% touch(join '/', home, 'data', $file);
<%= $file %>_file: <%= home %>/data/<%= $file %>
% }
