use strict;
use warnings;
eval q{ use Test::Clustericious::Log };
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
use PlugAuth::Lite;
BEGIN {
  skip_all 'test requires Clustericious 1.24'
    unless eval q{ use Clustericious 1.24; 1 };
};
plan 12;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_plugauth_lite_ok(auth => sub { $_[0] eq 'optimus' && $_[1] eq 'matrix' });

$cluster->create_cluster_ok(qw( MyApp ));

my $url = $cluster->url->clone;
my $t   = $cluster->t;

$t->get_ok($url)
  ->status_is(200)
  ->content_is('public');

$url->path("/private");

$t->get_ok($url)
  ->status_is(401);

$url->userinfo('bad:bad');

$t->get_ok($url)
  ->status_is(401);

$url->userinfo('optimus:matrix');

$t->get_ok($url)
  ->status_is(200)
  ->content_is('secret');

__DATA__

@@ etc/MyApp.conf
---
url: <%= cluster->url %>
plug_auth:
  url: <%= cluster->auth_url %>

@@ lib/MyApp.pm
package MyApp;

use strict;
use warnings;
use MyApp::Routes;
use Mojo::Base qw( Clustericious::App );

our $VERSION = '1.00';

1;

@@ lib/MyApp/Routes.pm
package MyApp::Routes;

use strict;
use warnings;
use Clustericious::RouteBuilder;

get '/' => sub { shift->render(text => 'public') };
  
authenticate;
authorize 'foo';
  
get '/private' => sub { shift->render(text => 'secret') };

1;
