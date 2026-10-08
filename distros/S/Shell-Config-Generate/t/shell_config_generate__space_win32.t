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

note "before: $dir";
note "after:  $dir1";
note "before: $file";
note "after:  $file1";

# short (8+3) names are not created by default on newer versions of
# Windows, in which case the original paths should be returned as-is.
if($dir1 =~ /\s/ || $file1 =~ /\s/)
{
  note "short names do not appear to be available";
  is $dir1,  $dir,  "dir unchanged";
  is $file1, $file, "file unchanged";
}
else
{
  pass "dir has no spaces";
  pass "file has no spaces";
}

is [win32_space_be_gone 'foo', 'bar baz'], ['foo', 'bar baz'], "non-existent path with space is returned unchanged";

my $content = do {
  open my $fh, '<', $file1;
  local $/;
  <$fh>;
};

like $content, qr{hi there}, "has content";

done_testing;
