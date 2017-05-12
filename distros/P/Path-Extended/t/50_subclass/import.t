use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Extended::Test;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'file_class' => sub {
  my $file = file("$tmpdir/import");
  ok $file->isa('Path::Extended::Test::File'), "isa ::Test::File";
  ok $file->isa('Path::Extended::File'), "isa ::File";
};

subtest 'dir_class' => sub {
  my $dir = dir("$tmpdir/import");
  ok $dir->isa('Path::Extended::Test::Dir'), "isa ::Test::Dir";
  ok $dir->isa('Path::Extended::Dir'), "isa ::Dir";
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
