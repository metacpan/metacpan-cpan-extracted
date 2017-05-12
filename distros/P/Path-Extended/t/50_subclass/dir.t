use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Path::Extended::Test;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'parents' => sub {
  my $dir = dir("$tmpdir/subclass");
  $dir->mkdir;
  ok $dir->exists, 'created tmpdir';

  my $parent = $dir->parent;
  ok $parent->isa('Path::Extended::Test::Dir'), 'parent is a ::Test::Dir';

  my $grandparent = $parent->parent;
  ok $grandparent->isa('Path::Extended::Test::Dir'), 'grand parent is a ::Test::Dir';

  $dir->rmdir;
};

subtest 'children' => sub {
  my $dir = dir("$tmpdir/subclass");
  $dir->mkdir;
  ok $dir->exists, 'created tmpdir';

  my $file = $dir->file('file');
  $file->save('content');
  ok $file->exists, 'created file';
  ok $file->isa('Path::Extended::Test::File'), 'file is a ::Test::File';

  my $subdir = $dir->subdir('dir');
  $subdir->mkdir;
  ok $subdir->exists, 'created subdir';
  ok $subdir->isa('Path::Extended::Test::Dir'), 'subdir is a ::Test::Dir';

  foreach my $entry ($dir->children) {
    ok $entry->_class eq 'Path::Extended::Test', 'entry is a Path::Extended::Test child';
  }

  $dir->rmdir;
};

subtest 'next' => sub {
  my $dir = dir("$tmpdir/subclass");
  $dir->mkdir;
  ok $dir->exists, 'created tmpdir';

  my $file = $dir->file('file');
  $file->save('content');
  ok $file->exists, 'created file';
  ok $file->isa('Path::Extended::Test::File'), 'file is a ::Test::File';

  my $subdir = $dir->subdir('dir');
  $subdir->mkdir;
  ok $subdir->exists, 'created subdir';
  ok $subdir->isa('Path::Extended::Test::Dir'), 'subdir is a ::Test::Dir';

  while( my $entry = $dir->next ) {
    ok $entry->_class eq 'Path::Extended::Test', 'entry is a Path::Extended::Test child';
  }

  $dir->rmdir;
};

subtest 'find' => sub {
  my $dir = dir("$tmpdir/subclass");
  $dir->mkdir;
  ok $dir->exists, 'created tmpdir';

  my $file = $dir->file('file');
  $file->save('content');
  ok $file->exists, 'created file';
  ok $file->isa('Path::Extended::Test::File'), 'file is a ::Test::File';

  my $subdir = $dir->subdir('dir');
  $subdir->mkdir;
  ok $subdir->exists, 'created subdir';
  ok $subdir->isa('Path::Extended::Test::Dir'), 'subdir is a ::Test::Dir';

  foreach my $file ( $dir->find('*') ) {
    ok $file->_class eq 'Path::Extended::Test', 'entry is a Path::Extended::Test child';
  }

  $dir->rmdir;
};

subtest 'find_dir' => sub {
  my $dir = dir("$tmpdir/subclass");
  $dir->mkdir;
  ok $dir->exists, 'created tmpdir';

  my $file = $dir->file('file');
  $file->save('content');
  ok $file->exists, 'created file';
  ok $file->isa('Path::Extended::Test::File'), 'file is a ::Test::File';

  my $subdir = $dir->subdir('dir');
  $subdir->mkdir;
  ok $subdir->exists, 'created subdir';
  ok $subdir->isa('Path::Extended::Test::Dir'), 'subdir is a ::Test::Dir';

  foreach my $subdir ( $dir->find_dir('*') ) {
    ok $subdir->_class eq 'Path::Extended::Test', 'entry is a Path::Extended::Test child';
  }

  $dir->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
