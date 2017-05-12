use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Clustericious::Cluster;
use File::HomeDir;
use Path::Class qw( file );

my $cluster = Test::Clustericious::Cluster->new;

is(
  intercept { $cluster->extract_data_section(qr{foo\.txt}) },
  array {
    event Note => sub {
      call message => match qr{\[extract\] DIR  .*some[/\\]dir};
    };
    event Note => sub {
      call message => match qr{\[extract\] FILE .*some[/\\]dir[/\\]foo.txt};
    };
    end;
  },
  "extract 'em all",
);

my @files = map { file( File::HomeDir->my_home, @$_ ) } [ qw( some dir foo.txt ) ];

ok -f $_, $_ for @files;

like $files[0]->slurp, qr{hello there}, "content for $files[0]";

done_testing;

__DATA__

@@ some/dir/foo.txt
hello there

@@ and/another/bar.txt
and some more
