use strict;
use warnings;
use FindBin;
use Test::More;
use File::Path;
use File::Temp qw/tempdir/;
use Parse::LocalDistribution;

my $pid = $$;
my $dir;
eval {
  $dir = tempdir();
  $dir =~ s|\\|/|g;
  for ($dir, "$dir/lib", "$dir/inc") {
    unless (-d $_) {
      mkpath $_ or die "failed to create a temporary directory: $_ $!";
    }
  }
  {
    open my $fh, '>', "$dir/lib/ParseLocalDistTest.pm" or die "failed to open a temp file: $!";
    print $fh "package " . "ParseLocalDistTest;\n";
    print $fh "our \$VERSION = '0.01';\n";
    print $fh "1;\n";
    close $fh;
  }
  {
    open my $fh, '>', "$dir/inc/ParseLocalDistInc.pm" or die "failed to open a temp file: $!";
    print $fh "package " . "ParseLocalInc;\n";
    print $fh "our \$VERSION = '0.02';\n";
    print $fh "1;\n";
    close $fh;
  }
  {
    open my $fh, '>', "$dir/META.json" or die "failed to open a temp file: $!";
    print $fh '{"abstract": "", "author": ["me"], "name": "ParseLocalDistTest", "no_index": {"directory": ["t", "inc"]}, "version": "0.01"}';
    close $fh;
  }
};
plan skip_all => $@ if $@;

for my $fork (0..1) {
  my $p = Parse::LocalDistribution->new({FORK => $fork});
  my $provides = $p->parse($dir);
  ok $provides && $provides->{ParseLocalDistTest}{version} eq '0.01', "correct version";
  ok $provides && !$provides->{ParseLocalInc}, "TestParseLocalInc is ignored";
  note explain $provides;
  note explain $p;
}

done_testing;

END {
  if ($dir && -d $dir && $pid eq $$) {
    rmtree $dir;
  }
}
