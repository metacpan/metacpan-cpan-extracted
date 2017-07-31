use Test2::V0 -no_srand => 1;
use Test::Clustericious::Cluster;
use Path::Class qw( file );
use File::Glob qw( bsd_glob );

my $cluster = Test::Clustericious::Cluster->new;

is(
  intercept { $cluster->extract_data_section },
  array {
    event Note => sub {
      call message => match qr{\[extract\] DIR  };
    };
    event Note => sub {
      call message => match qr{\[extract\] FILE };
    };
    event Note => sub {
      call message => match qr{\[extract\] DIR  };
    };
    event Note => sub {
      call message => match qr{\[extract\] FILE };
    };
    end;
  },
  "extract 'em all",
);

my @files = map { file( bsd_glob('~'), @$_ ) } [ qw( some dir foo.txt ) ], [ qw( and another bar.txt ) ];

ok -f $_, $_ for @files;

like $files[0]->slurp, qr{hello there}, "content for $files[0]";
like $files[1]->slurp, qr{and some more}, "content for $files[1]";

done_testing;

__DATA__

@@ some/dir/foo.txt
hello there

@@ and/another/bar.txt
and some more
