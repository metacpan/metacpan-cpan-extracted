use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;

plan 4;

my $cluster = Test::Clustericious::Cluster->new;

$cluster->create_cluster_ok('myapp');

my $t = $cluster->t;

$t->get_ok($cluster->url)
  ->status_is(200)
  ->content_is('bar');

__DATA__

@@ script/myapp
#!/usr/bin/perl
use Mojolicious::Lite;
get '/' => sub { shift->render(text => 'bar') };
app->start;
