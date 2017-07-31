use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;
use File::Glob qw( bsd_glob );
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

my @files = map { file( bsd_glob('~'), @$_ ) } [ qw( some dir foo.txt ) ];

ok -f $_, $_ for @files;

like $files[0]->slurp, qr{hello there}, "content for $files[0]";

done_testing;

__DATA__

@@ some/dir/foo.txt
hello there

@@ and/another/bar.txt
and some more
