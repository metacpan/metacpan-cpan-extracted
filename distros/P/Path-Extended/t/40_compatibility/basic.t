use strict;
use warnings;
use Test::More;
use Path::Extended::Class;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

# ripped from Path::Class' t/01-basic.t

$Path::Extended::IgnoreVolume = 1;

subtest 'file1' => sub {
  my $file = file('foo.txt');

  ok $file eq 'foo.txt', 'test 02';
  ok !$file->is_absolute, 'test 03';
  ok $file->dir eq '.',   'test 04';
  ok $file->basename eq 'foo.txt', 'test 05';
};

subtest 'file2' => sub {
  my $file = file('dir', 'bar.txt');

  ok $file eq 'dir/bar.txt', 'test 06';
  ok !$file->is_absolute, 'test 07';
  ok $file->dir eq 'dir',   'test 08';
  ok $file->basename eq 'bar.txt', 'test 09';
};

subtest 'dir1' => sub {
  my $dir = dir('tmp');
  ok $dir eq 'tmp', 'test 10';
  ok !$dir->is_absolute, 'test 11';
  ok $dir->basename eq 'tmp', 'RT 17312';

  my $cat = file($dir, 'foo');
  ok $cat eq 'tmp/foo', 'test 14';
  $cat = $dir->file('foo');
  ok $cat eq 'tmp/foo', 'test 15';
  ok $cat->dir eq 'tmp', 'test 16';
  ok $cat->basename eq 'foo', 'test 17';
};

subtest 'dir2' => sub {
  my $dir = dir('/tmp');
  ok $dir eq '/tmp', 'test 12';
  ok $dir->is_absolute, 'test 13';

  my $cat = file($dir, 'foo');
  ok $cat eq '/tmp/foo', 'test 18';
  $cat = $dir->file('foo');
  ok $cat eq '/tmp/foo', 'test 19';
  ok $cat->isa('Path::Extended::Class::File'), 'test 20';
  ok $cat->dir eq '/tmp', 'test 21';

  $cat = $dir->subdir('foo');
  ok $cat eq '/tmp/foo', 'test 22';
  ok $cat->isa('Path::Extended::Class::Dir'), 'test 23';
  ok $cat->basename eq 'foo', 'RT 17312';
};

subtest 'cleanup' => sub {
  my $file = file('/foo//baz/./foo')->cleanup;
  ok $file eq '/foo/baz/foo', 'test 24';
  ok $file->dir eq '/foo/baz', 'test 25';
  ok $file->parent eq '/foo/baz', 'test 26';
};

subtest 'parents' => sub {
  my $dir = dir('/foo/bar/baz');
  ok $dir->parent eq '/foo/bar', 'test 27';
  ok $dir->parent->parent eq '/foo', 'test 28';
  ok $dir->parent->parent->parent eq '/', 'test 29';
  ok $dir->parent->parent->parent->parent eq '/', 'test 30';

  $dir = dir('foo/bar/baz');
  ok $dir->parent eq 'foo/bar', 'test 31';
  ok $dir->parent->parent eq 'foo', 'test 32';
  ok $dir->parent->parent->parent eq '.', 'test 33';
  ok $dir->parent->parent->parent->parent eq '..', 'test 34';
  ok $dir->parent->parent->parent->parent->parent eq '../..', 'test 35';
};

subtest 'trailing_slash' => sub {
  my $dir = dir("foo/");
  ok $dir eq 'foo', 'test 36';
  ok $dir->parent eq '.', 'test 37';

  # Special cases
  ok dir('') eq '/', 'test 38';
  ok dir() eq '.', 'test 39';
  ok dir('', 'var', 'tmp') eq '/var/tmp', 'test 40';
  ok dir()->absolute->resolve eq dir(Cwd::cwd())->resolve, 'test 41';
  ok !defined dir(undef), 'dir(undef)'; # added
};

subtest 'relative' => sub {
  my $file = file('/tmp/foo/bar.txt');
  ok $file->relative('/tmp') eq 'foo/bar.txt', 'test 42';
  ok $file->relative('/tmp/foo') eq 'bar.txt', 'test 43';
  ok $file->relative('/tmp/') eq 'foo/bar.txt', 'test 44';
  ok $file->relative('/tmp/foo/') eq 'bar.txt', 'test 45';

  $file = file('one/two/three');
  ok $file->relative('one') eq 'two/three', 'test 46';
};

subtest 'dir_list' => sub {
  my $dir = dir('one/two/three/four/five');
  my @d = $dir->dir_list();
  ok "@d" eq "one two three four five", 'test 47';

  @d = $dir->dir_list(2);
  ok "@d" eq "three four five", 'test 48';

  @d = $dir->dir_list(-2);
  ok "@d" eq "four five", 'test 49';

  @d = $dir->dir_list(2, 2);
  ok "@d" eq "three four", 'test 50';

  @d = $dir->dir_list(-3, 2);
  ok "@d" eq "three four", 'test 51';

  @d = $dir->dir_list(-3, -2);
  ok "@d" eq "three", 'test 52';

  @d = $dir->dir_list(-3, -1);
  ok "@d" eq "three four", 'test 53';

  my $d = $dir->dir_list();
  ok $d == 5, 'test 54';

  $d = $dir->dir_list(2);
  ok $d eq "three", 'test 55';

  $d = $dir->dir_list(-2);
  ok $d eq "four", 'test 56';

  $d = $dir->dir_list(2, 2);
  ok $d eq "four", 'test 57';
};

subtest 'is_dir' => sub {
  ok  dir('foo')->is_dir == 1, 'test 58';
  ok file('foo')->is_dir == 0, 'test 59';
};

subtest 'subsumes' => sub {
  ok dir('foo/bar')->subsumes('foo/bar/baz') == 1, 'test 60';
  ok dir('/foo/bar')->subsumes('/foo/bar/baz') == 1, 'test 61';
  ok dir('foo/bar')->subsumes('bar/baz') == 0, 'test 62';
  ok dir('/foo/bar')->subsumes('foo/bar') == 0, 'test 63';
  ok dir('/foo/bar')->subsumes('/foo/baz') == 0, 'test 64';
  ok dir('/')->subsumes('/foo/bar') == 1, 'test 65';
};

done_testing;

END {
  $Path::Extended::IgnoreVolume = 0;

  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
