use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

skip_all 'test requires Dancer2 and Mojolicious::Plugin::MountPSGI'
  unless eval q{ use Dancer2 (); use Mojolicious::Plugin::MountPSGI (); 1 };
plan 4;

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('myapp');

my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url/foo")
  ->status_is(200)
  ->content_is('Hello World!');

__DATA__

@@ script/myapp.psgi
#!/usr/bin/perl
package MyApp;
use Dancer2;
get '/foo' => sub { 'Hello World!' };
package main;
MyApp->to_app;

