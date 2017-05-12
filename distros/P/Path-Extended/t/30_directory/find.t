use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'find' => sub {
  my $dir = dir("$tmpdir/find")->mkdir;
  ok $dir->exists, 'created '.$dir->relative;

  my $file1 = file("$tmpdir/find/some.txt");
     $file1->save('some content');
  ok $file1->exists, 'created '.$file1->relative;

  my $file2 = file("$tmpdir/find/other.txt");
     $file2->save('other content');
  ok $file2->exists, 'created '.$file2->relative;

  my @files = $dir->find('*.txt');
  ok @files, 'found '.(scalar @files).' files';

  ok((grep { defined $_ and $_->isa('Path::Extended::File') } @files),
    'files are Path::Extended::File objects');

  my @should_not_be_found = $dir->find('*.jpeg');
  ok @should_not_be_found == 0, 'found nothing';

  my @filtered = $dir->find('*.txt',
    callback => sub { grep { $_ =~ /some/ } @_ }
  );
  ok @filtered && $filtered[0]->basename eq 'some.txt',
    'found some.txt';

  $dir->rmdir;
};

subtest 'find_dir' => sub {
  my $dir  = dir("$tmpdir/find_dir");
  my $dir1 = dir("$tmpdir/find_dir/found")->mkdir;
  ok $dir1->exists, 'created '.$dir1->relative;

  my $dir2 = dir("$tmpdir/find_dir/not_found")->mkdir;
  ok $dir2->exists, 'created '.$dir2->relative;

  my $rule = '*';

  my @dirs = $dir->find_dir($rule);
  ok @dirs, 'found '.(scalar @dirs).' directories';

  ok((grep { defined $_ and $_->isa('Path::Extended::Dir') } @dirs),
    'directories are Path::Extended::Dir objects');

  my @should_not_be_found = $dir->find('yes');
  ok @should_not_be_found == 0, 'found nothing';

  my @filtered = $dir->find_dir($rule,
    callback => sub { grep { $_ =~ /not/ } @_ }
  );
  ok @filtered, 'found '.($filtered[0] ? $filtered[0]->relative : 'nothing');

  $dir->rmdir;
};

subtest 'private_error' => sub {
  my $dir = dir($tmpdir);
  ok !$dir->_find( dir => '*' ), 'invalid type';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
