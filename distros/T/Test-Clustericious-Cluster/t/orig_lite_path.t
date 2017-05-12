use strict;
use warnings;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
BEGIN {
  skip_all 'test requires Clustericious 1.24'
    unless eval q{
      use Clustericious 1.24;
      use Test::Clustericious::Config;
      1;
    };
}

plan 5;

my $bin = create_directory_ok 'bin';

do {
  open my $fh, '>', "$bin/myapp";
  eval { chmod 0755, $fh }; # in case OS does not support chmod
  print $fh "#!/usr/bin/perl\n";
  print $fh "use Mojolicious::Lite;\n";
  print $fh "get '/' => sub { shift->render( text => 'bar' ) };\n";
  print $fh "app->start;\n";
  close $fh;
};

my $cluster = Test::Clustericious::Cluster->new( lite_path => [ $bin ] );

$cluster->create_cluster_ok('myapp');

my $t = $cluster->t;

$t->get_ok($cluster->url)
  ->status_is(200)
  ->content_is('bar');

