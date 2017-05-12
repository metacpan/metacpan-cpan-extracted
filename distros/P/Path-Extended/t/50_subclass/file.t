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
  my $file = file("$tmpdir/subclass/file");
  $file->save('content', mkdir => 1);
  ok $file->exists, 'created tmpfile';

  my $parent = $file->parent;
  ok $parent->isa('Path::Extended::Test::Dir'), 'parent is a ::Test::Dir';

  my $grandparent = $parent->parent;
  ok $grandparent->isa('Path::Extended::Test::Dir'), 'grand parent is a ::Test::Dir';

  dir($tmpdir)->rmdir;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
