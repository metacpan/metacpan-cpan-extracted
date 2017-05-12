use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

skip_all 'test requires Mojolicious::Plugin::MountPSGI'
  unless eval q{ use Mojolicious::Plugin::MountPSGI (); 1 };
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
my $app = sub {
  my $env = shift;
  return [
    200,
    [ 'Content-Type' => 'text/plain' ],
    [ 'Hello World!' ],
  ];
};
