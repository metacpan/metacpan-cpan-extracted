use strict;
use warnings;
use 5.008001;
use Shell::Config::Generate qw( win32_space_be_gone );
use Test::More;
use File::Temp qw( tempdir );
use File::Spec;

plan skip_all => 'test only for cygwin and MSWin32' unless $^O =~ /^(cygwin|MSWin32|msys)$/;

ok(Shell::Config::Generate->can('win32_space_be_gone'), 'has win32_space_be_gone function');

my $tmp = tempdir( CLEANUP => 1 );

my $dir = File::Spec->catdir($tmp, "dir with space");

mkdir $dir;
ok -d $dir, "created directory $dir";

my $file = File::Spec->catfile($dir, 'foo.txt');
do {
  open my $fh, '>', $file;
  print $fh "hi there\n";
  close $fh;
};

ok -e $file, "created file $file";

my($dir1, $file1) = win32_space_be_gone($dir,$file);

ok -d $dir1, "dir exists $dir1";
ok -r $file1, "file readable $file1";

unlike $dir1, qr{\s}, "dir has no spaces";
unlike $file1, qr{\s}, "file has no spaces";

my $content = do {
  open my $fh, '<', $file1;
  local $/;
  <$fh>;
};

like $content, qr{hi there}, "has content";

done_testing;
