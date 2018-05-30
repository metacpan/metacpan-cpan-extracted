BEGIN {
  $^O = 'Unix'; # Test in Unix mode
}

use Test::Most 0.25;

use strict;
use Path::Class::Tiny;
use Cwd;


my $file1 = Path::Class::Tiny->new('foo.txt');
is $file1, 'foo.txt';
is $file1->is_absolute, '';
is $file1->dir, '.';
is $file1->basename, 'foo.txt';

my $file2 = file('dir', 'bar.txt');
is $file2, 'dir/bar.txt';
is $file2->is_absolute, '';
is $file2->dir, 'dir';
is $file2->basename, 'bar.txt';

my $dir = dir('tmp');
is $dir, 'tmp';
is $dir->is_absolute, '';
is $dir->basename, 'tmp';

my $dir2 = dir('/tmp');
is $dir2, '/tmp';
is $dir2->is_absolute, 1;

my $cat = file($dir, 'foo');
is $cat, 'tmp/foo';
$cat = $dir->file('foo');
is $cat, 'tmp/foo';
is $cat->dir, 'tmp';
is $cat->basename, 'foo';

$cat = file($dir2, 'foo');
is $cat, '/tmp/foo';
$cat = $dir2->file('foo');
is $cat, '/tmp/foo';
#isa_ok($cat, 'Path::Class::File');					# this probably *shouldn't* pass
is $cat->dir, '/tmp';

$cat = $dir2->subdir('foo');
is $cat, '/tmp/foo';
#isa_ok($cat, 'Path::Class::Dir');					# this probably *shouldn't* pass
is $cat->basename, 'foo';

my $file = file('/foo//baz/./foo')->cleanup;
is $file, '/foo/baz/foo';
is $file->dir, '/foo/baz';
is $file->parent, '/foo/baz';

{
  my $dir = dir('/foo/bar/baz');
  is $dir->parent, '/foo/bar';
  is $dir->parent->parent, '/foo';
  is $dir->parent->parent->parent, '/';
  is $dir->parent->parent->parent->parent, '/';

  $dir = dir('foo/bar/baz');
  is $dir->parent, 'foo/bar';
  is $dir->parent->parent, 'foo';
  is $dir->parent->parent->parent, '.';
  is $dir->parent->parent->parent->parent, '..';
  is $dir->parent->parent->parent->parent->parent, '../..';
}

{
  my $dir = dir("foo/");
  is $dir, 'foo';
  is $dir->parent, '.';
}

SKIP: { skip "special cases for `dir` handled elsewhere";

  # Special cases
  is dir(''), '/';
  is dir(), '.';
  is dir('', 'var', 'tmp'), '/var/tmp';
  is dir()->absolute->resolve, dir(Cwd::cwd())->resolve;
  is dir(undef), undef;
}

{
  my $file = file('/tmp/foo/bar.txt');
  is $file->relative('/tmp'), 'foo/bar.txt';
  is $file->relative('/tmp/foo'), 'bar.txt';
  is $file->relative('/tmp/'), 'foo/bar.txt';
  is $file->relative('/tmp/foo/'), 'bar.txt';

  $file = file('one/two/three');
  is $file->relative('one'), 'two/three';
}

SKIP: {	skip "dir_list() / is_dir() / subsumes() still need more work";

{
  # Try out the dir_list() method
  my $dir = dir('one/two/three/four/five');
  my @d = $dir->dir_list();
  is "@d", "one two three four five";

  @d = $dir->dir_list(2);
  is "@d", "three four five";

  @d = $dir->dir_list(-2);
  is "@d", "four five";

  @d = $dir->dir_list(2, 2);
  is "@d", "three four", "dir_list(2, 2)";

  @d = $dir->dir_list(-3, 2);
  is "@d", "three four", "dir_list(-3, 2)";

  @d = $dir->dir_list(-3, -2);
  is "@d", "three", "dir_list(-3, -2)";

  @d = $dir->dir_list(-3, -1);
  is "@d", "three four", "dir_list(-3, -1)";

  my $d = $dir->dir_list();
  is $d, 5, "scalar dir_list()";

  $d = $dir->dir_list(2);
  is $d, "three", "scalar dir_list(2)";

  $d = $dir->dir_list(-2);
  is $d, "four", "scalar dir_list(-2)";

  $d = $dir->dir_list(2, 2);
  is $d, "four", "scalar dir_list(2, 2)";
}

{
  # Test is_dir()
  is  dir('foo')->is_dir, 1;
  is file('foo')->is_dir, 0;
}

{
  # subsumes()
  is dir('foo/bar')->subsumes('foo/bar/baz'), 1;
  is dir('/foo/bar')->subsumes('/foo/bar/baz'), 1;
  is dir('foo/bar')->subsumes('bar/baz'), 0;
  is dir('/foo/bar')->subsumes('foo/bar'), 0;
  is dir('/foo/bar')->subsumes('/foo/baz'), 0;
  is dir('/')->subsumes('/foo/bar'), 1;
  is dir('/')->subsumes(file('/foo')), 1;
  is dir('/foo')->subsumes(file('/foo')), 0;
}

} # TODO block


done_testing;
