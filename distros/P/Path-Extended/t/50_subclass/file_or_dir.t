use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Extended::Test;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

dir("$tmpdir/dir")->mkdir;
file("$tmpdir/file")->touch;

subtest 'file_or_dir_for_an_existing_file' => sub {
  my $maybe_file = file_or_dir("$tmpdir/file");
  ok $maybe_file->isa('Path::Extended::Test::File'), 'got a File object for an existing file';
};

subtest 'file_or_dir_for_an_existing_dir' => sub {
  my $maybe_file = file_or_dir("$tmpdir/dir");
  ok $maybe_file->isa('Path::Extended::Test::Dir'), 'got a Dir object for an existing directory';
};

subtest 'file_or_dir_for_an_unknown_path' => sub {
  my $maybe_file = file_or_dir("$tmpdir/unknown");
  ok $maybe_file->isa('Path::Extended::Test::File'), 'got a File object for an unknown path';
};

subtest 'dir_or_file_for_an_existing_file' => sub {
  my $maybe_dir = dir_or_file("$tmpdir/file");
  ok $maybe_dir->isa('Path::Extended::Test::File'), 'got a File object for an existing file';
};

subtest 'dir_or_file_for_an_existing_dir' => sub {
  my $maybe_dir = dir_or_file("$tmpdir/dir");
  ok $maybe_dir->isa('Path::Extended::Test::Dir'), 'got a Dir object for an existing directory';
};

subtest 'dir_or_file_for_an_unknown_path' => sub {
  my $maybe_dir = dir_or_file("$tmpdir/unknown");
  ok $maybe_dir->isa('Path::Extended::Test::Dir'), 'got a Dir object for an unknown path';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
