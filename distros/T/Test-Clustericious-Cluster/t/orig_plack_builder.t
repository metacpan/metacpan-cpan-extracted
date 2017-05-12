use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test::More;

plan skip_all => 'test requires Mojolicious::Plugin::MountPSGI'
  unless eval q{ use Mojolicious::Plugin::MountPSGI (); 1 };
plan skip_all => 'test requires Plack::Builder'
  unless eval q{ use Plack::Builder (); 1 };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('myapp');

my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url/foo")
  ->status_is(200)
  ->content_is('Hello World!');

$t->get_ok("$url/icky/foo")
  ->status_is(200)
  ->content_is('Hello World!');

done_testing;

__DATA__

@@ script/myapp.psgi
#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Plack::Builder;

my $app = sub {
  my $env = shift;
  note "running...\n";
  return [
    200,
    [ 'Content-Type' => 'text/plain' ],
    [ 'Hello World!' ],
  ];
};

builder {
  note "building...\n";
  mount '/icky' => $app;
  mount '/' => $app;
};
