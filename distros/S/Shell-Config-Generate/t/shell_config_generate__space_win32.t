use Test2::V0 -no_srand => 1;
use Shell::Config::Generate qw( win32_space_be_gone );
use File::Temp qw( tempdir );
use File::Spec;

skip_all 'test only for cygwin and MSWin32' unless $^O =~ /^(cygwin|MSWin32|msys)$/;

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

unlike $dir1, qr{\s}, "dir has no spaces"
  or diag "before: $dir\n",
          "after:  $dir1";
unlike $file1, qr{\s}, "file has no spaces"
  or diag "before: $file\n",
          "after:  $file1";

my $content = do {
  open my $fh, '<', $file1;
  local $/;
  <$fh>;
};

like $content, qr{hi there}, "has content";

done_testing;
