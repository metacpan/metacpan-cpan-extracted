use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

dir("$tmpdir/dir")->mkdir;
file("$tmpdir/file")->touch;

subtest 'file_or_dir_for_an_existing_file' => sub {
  my $maybe_file = dir($tmpdir)->file_or_dir('file');
  ok $maybe_file->isa('Path::Extended::File'), 'got a File object for an existing file';
};

subtest 'file_or_dir_for_an_existing_dir' => sub {
  my $maybe_file = dir($tmpdir)->file_or_dir('dir');
  ok $maybe_file->isa('Path::Extended::Dir'), 'got a Dir object for an existing directory';
};

subtest 'file_or_dir_for_an_unknown_path' => sub {
  my $maybe_file = dir($tmpdir)->file_or_dir('unknown');
  ok $maybe_file->isa('Path::Extended::File'), 'got a File object for an unknown path';
};

subtest 'dir_or_file_for_an_existing_file' => sub {
  my $maybe_dir = dir($tmpdir)->dir_or_file('file');
  ok $maybe_dir->isa('Path::Extended::File'), 'got a File object for an existing file';
};

subtest 'dir_or_file_for_an_existing_dir' => sub {
  my $maybe_dir = dir($tmpdir)->dir_or_file('dir');
  ok $maybe_dir->isa('Path::Extended::Dir'), 'got a Dir object for an existing directory';
};

subtest 'dir_or_file_for_an_unknown_path' => sub {
  my $maybe_dir = dir($tmpdir)->dir_or_file('unknown');
  ok $maybe_dir->isa('Path::Extended::Dir'), 'got a Dir object for an unknown path';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
