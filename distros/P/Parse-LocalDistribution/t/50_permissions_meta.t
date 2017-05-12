use strict;
use warnings;
use FindBin;
use Test::More;
use File::Path;
use File::Temp qw/tempdir/;
use Parse::LocalDistribution;

plan skip_all => "requires PAUSE::Permissions 0.08" unless eval "use PAUSE::Permissions 0.08; 1";

my $pid = $$;
my $dir;
eval {
  $dir = tempdir();
  $dir =~ s|\\|/|g;
  for ($dir, "$dir/lib", "$dir/tmp") {
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
    open my $fh, '>', "$dir/lib/ParseLocalDistTest2.pm" or die "failed to open a temp file: $!";
    print $fh "package " . "ParseLocalInc;\n";
    print $fh "our \$VERSION = '0.02';\n";
    print $fh "1;\n";
    close $fh;
  }
  {
    open my $fh, '>', "$dir/META.json" or die "failed to open a temp file: $!";
    print $fh '{"abstract": "", "author": ["me"], "name": "ParseLocalDistTest", "version": "0.01", "provides": {"ParseLocalDistTest": {"file": "lib/ParseLocalDistTest.pm", "version": "0.01"}, "ParseLocalDistTest2": {"file": "lib/ParseLocalDistTest2.pm", "version": "0.02"}}}';
    close $fh;
  }
  {
    open my $fh, '>', "$dir/tmp/06perms.txt" or die "failed to open a temp file: $!";
    print $fh "File:        06perms.txt\n";
    print $fh "\n";
    print $fh "ParseLocalDistTest,FIRSTCOME,f\n";
    print $fh "ParseLocalDistTest,MAINT,m\n";
    print $fh "ParseLocalDistTest,COMAINT,c\n";
    print $fh "ParseLocalDistTest,UNKNOWN,c\n";
    print $fh "ParseLocalDistTest2,FIRSTCOME,f\n";
    print $fh "ParseLocalDistTest2,MAINT,m\n";
    print $fh "ParseLocalDistTest2,COMAINT,c\n";
    close $fh;
  }
};
plan skip_all => $@ if $@;

my $permissions = PAUSE::Permissions->new(path => "$dir/tmp/06perms.txt");

for my $fork (0..1) {
  for my $user (qw/FIRSTCOME MAINT COMAINT UNKNOWN/) {
    my $p = Parse::LocalDistribution->new({FORK => $fork, USERID => $user, PERMISSIONS => $permissions});
    my $provides = $p->parse($dir);
    ok $provides && $provides->{ParseLocalDistTest}{version} eq '0.01', "correct version";
    if ($user eq 'UNKNOWN') {
      ok $provides && !$provides->{ParseLocalDistTest2}, "TestParseLocalTest is ignored";
    } else {
      ok $provides && $provides->{ParseLocalDistTest2}{version} eq '0.02', "TestParseLocalTest2 is not ignored";
    }
    note explain $provides;
    note explain $p;
  }
}

done_testing;

END {
  if ($dir && -d $dir && $pid eq $$) {
    rmtree $dir;
  }
}
