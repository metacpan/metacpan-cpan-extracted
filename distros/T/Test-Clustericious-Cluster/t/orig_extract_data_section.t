use strict;
use warnings;
use 5.010001;
use Test::Clustericious::Cluster;
use Test2::Bundle::More;
use File::HomeDir;

plan 2;

my $cluster = Test::Clustericious::Cluster->new;

my $home = File::HomeDir->my_home;

subtest 'selection' => sub {
  plan 5;
  $cluster->extract_data_section(qr{^data2});
  ok -d "$home/data2", "data2 dir exists";
  ok -f "$home/data2/foo2.txt", "data2/foo2.txt exists";
  ok ! -d "$home/data", "data dir does NOT exist";
  ok ! -f "$home/data/foo.txt", "data/foo.txt does NOT exist";
  
  open my $fh, '<', "$home/data2/foo2.txt";
  my $content = <$fh>;
  close $fh;
  like $content, qr{^some more data}, "content matches";
};

subtest 'selection' => sub {
  plan 5;
  $cluster->extract_data_section;
  ok -d "$home/data2", "data2 dir exists";
  ok -f "$home/data2/foo2.txt", "data2/foo2.txt exists";
  ok -d "$home/data", "data dir does NOT exist";
  ok -f "$home/data/foo.txt", "data/foo.txt does NOT exist";

  open my $fh, '<', "$home/data/foo.txt";
  my $content = <$fh>;
  close $fh;
  like $content, qr{^some data}, "content matches";
};

__DATA__

@@ data/foo.txt
some data

@@ data2/foo2.txt
some more data
