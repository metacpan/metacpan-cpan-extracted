use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
BEGIN {
  skip_all 'test requires Clustericious 1.24'
    unless eval q{
      use Clustericious 1.24;
      use Clustericious::Config;
      use Test::Clustericious::Config;
      1;
    };
}

plan 15;

create_config_ok 'common';

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok(qw( MyApp MyApp ));

my $t = $cluster->t;

$t->get_ok($cluster->urls->[0])
  ->status_is(200)
  ->content_is('welcome');

$t->get_ok($cluster->urls->[1])
  ->status_is(200)
  ->content_is('welcome');

is(Clustericious::Config->new('MyApp')->url, $cluster->urls->[1], "config matches last MyApp url");

$t->get_ok($cluster->urls->[0] . "/number")
  ->status_is(200)
  ->content_is(0);

$t->get_ok($cluster->urls->[1] . "/number")
  ->status_is(200)
  ->content_is(1);

__DATA__

@@ etc/common.conf
---
url: <%= cluster->url %>

@@ etc/MyApp.conf
---
% extends_config 'common';
service_index: <%= cluster->index %>

@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use Mojo::Base qw( Clustericious::App );
use MyApp::Routes;

our $VERSON = '1.00';

@@ lib/MyApp/Routes.pm
package MyApp::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;
  
get '/' => sub { shift->render(text => 'welcome') };
get '/number' => sub {
  my $c = shift;
  $c->render(text => $c->config->service_index);
};
