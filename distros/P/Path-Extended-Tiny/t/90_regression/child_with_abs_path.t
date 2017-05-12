use strict;
use warnings;
use Test::More;
use Path::Extended::Tiny;

# Unlike the equivalents of Path::Class, and ->child method of
# Path::Tiny, file/subdir methods of Path::Extended don't simply
# append everything. If their first argument is absolute, it is
# used regardless of the original path.

my @volumes = ('');
push @volumes, 'C:' if $^O eq 'MSWin32';
for my $volume (@volumes) {
  my $path  = dir($volume.'/foo/bar');
  my $path2 = file($volume.'/baz');

  ok $path->is_absolute;
  ok $path2->is_absolute;

  my $new_path = $path->file($path2);

  ok $new_path->is_absolute;
  is "$new_path" => "$path2";
}

done_testing;
