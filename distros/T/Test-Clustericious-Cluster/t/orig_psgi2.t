use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;

skip_all 'test requires Mojolicious::Plugin::MountPSGI'
  unless eval q{ use Mojolicious::Plugin::MountPSGI (); 1 };

my $cluster = Test::Clustericious::Cluster->new;
$cluster->create_cluster_ok('myapp.psgi');

my $t = $cluster->t;
my $url = $cluster->url;

$t->get_ok("$url/foo")
  ->status_is(200)
  ->content_is('Hello World!');

done_testing;

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
