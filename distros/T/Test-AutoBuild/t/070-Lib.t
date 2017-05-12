# -*- perl -*-

use Test::More tests => 32;

BEGIN {
  use_ok("Test::AutoBuild::Lib") or die $@;
}

use warnings;
use strict;
use Log::Log4perl;
Log::Log4perl::init("t/log4perl.conf");
use File::Temp qw(tempdir);
use File::Path;
use File::Spec::Functions;

# Test cases for copy
#
# Source is a glob
# Dest is a path

my $scratch = tempdir(CLEANUP => 1);

&create_file($scratch, "file-src-a.txt");
&create_file($scratch, "file-src-b.txt");
&create_file($scratch, "file-dst-a.txt");
&create_dir($scratch, "dir-src-a");
&create_dir($scratch, "dir-src-b");
&create_dir($scratch, "dir-src-c");
&create_dir($scratch, "dir-dst-a");
&create_dir($scratch, "dir-dst-b");
&create_dir($scratch, "dir-dst-c");
&create_dir($scratch, "dir-dst-d");
&create_dir($scratch, "dir-dst-f");
&create_file($scratch, catfile("dir-src-c", "file-{src}-a.txt"));


# Single file -> single existing file
#  (Dest name is exact)

Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-a.txt"),
			    catfile($scratch, "file-dst-a.txt"));

ok(-f catfile($scratch, "file-dst-a.txt"), "Copy file -> existing file (file $scratch/file-dst-a.txt exists)");
is(&content($scratch, "file-dst-a.txt"), "file-src-a.txt\n", "Copy file -> existing file (file c contains 'file a')");

# Single file -> single existing directory
#  (Last component of src file name appended to dst dir name)

Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-a.txt"),
			    catfile($scratch, "dir-dst-a"));

ok(-f catfile($scratch, "dir-dst-a", "file-src-a.txt"), "Copy file -> existing dir (file $scratch/dir-dst-a/file-src-a.txt exists)");
is(&content($scratch, "dir-dst-a", "file-src-a.txt"), "file-src-a.txt\n", "Copy file -> existing dir (File a contains 'file a')");

# Single file -> non-existing path (Treat as file)
#  (Dest name is exact)

Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-a.txt"),
			    catfile($scratch, "file-dst-b.txt"));

ok(-f catfile($scratch, "file-dst-b.txt"), "Copy file -> new file (file $scratch/file-dst-b.txt exists)");
is(&content($scratch, "file-dst-b.txt"), "file-src-a.txt\n", "Copy file -> new file (File c contains 'file a')");

# Single directory -> single existing file (Fail)

eval {
  Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-a"),
			      catfile($scratch, "file-dst-a.txt"));
};
ok($@, "Copy dir -> existing file (should throw an error)");
ok(-f catfile($scratch, "file-dst-a.txt"), "Copy dir -> existing file ($scratch/file-dst-a.txt is still a file");

# Single directory -> single existing directory
Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-a"),
			    catfile($scratch, "dir-dst-b"));
ok(-d catfile($scratch, "dir-dst-b", "dir-src-a"), "Copy dir -> existing dir ($scratch/dir-dst-b/dir-src-a is a dir)");

# Single directory -> non-existing path (treat as directory)
Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-a"),
			    catfile($scratch, "dir-d"));
ok(-d catfile($scratch, "dir-d"), "Copy dir -> new dir ($scratch/dir-d is a dir)");

# Multiple files -> single existing file   (Fail)
eval {
  Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-*.txt"),
			      catfile($scratch, "file-dst-b.txt"));
  $@ = undef;
};
ok($@, "Copy many files -> existing file (should throw an error)");

# Multiple files -> single existing directory
Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-*.txt"),
			    catfile($scratch, "dir-dst-c"));
ok(-f catfile($scratch, "dir-dst-c", "file-src-a.txt"), "Copy many files -> existing dir ($scratch/dir-dst-c/file-src-a.txt exists)");
is(&content($scratch, "dir-dst-c", "file-src-a.txt"), "file-src-a.txt\n", "Copy many files -> existing dir (File c contains 'file a')");
ok(-f catfile($scratch, "dir-dst-c", "file-src-b.txt"), "Copy many files -> existing dir ($scratch/dir-dst-c/file-src-b.txt exists)");
is(&content($scratch, "dir-dst-c", "file-src-b.txt"), "file-src-b.txt\n", "Copy many files -> existing dir (File c contains 'file a')");

# XXX should we actually fail ? 'cp' does
# Multiple files -> non-existing path (treat as directory)

Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-*.txt"),
			    catfile($scratch, "dir-dst-d"));
ok(-f catfile($scratch, "dir-dst-d", "file-src-a.txt"), "Copy many files -> new dir ($scratch/dir-dst-d/file-src-a.txt exists)");
is(&content($scratch, "dir-dst-d", "file-src-a.txt"), "file-src-a.txt\n", "Copy many files -> new dir (File c contains 'file a')");

ok(-f catfile($scratch, "dir-dst-d", "file-src-b.txt"), "Copy many files -> new dir ($scratch/dir-dst-d/file-src-b.txt exists)");
is(&content($scratch, "dir-dst-d", "file-src-b.txt"), "file-src-b.txt\n", "Copy many files -> new dir (File c contains 'file b')");


# Multiple directories -> single existing file  (Fail)

eval {
  Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-*"),
			      catfile($scratch, "file-dst-a.txt"));
};
ok($@, "Copy many dir -> existing file (error should be thrown)");
ok(-f catfile($scratch, "file-dst-a.txt"), "Copy many dir -> existing file ($scratch/file-dst-a.txt is still a file)");


# Multiple directories -> single existing directory

Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-*"),
			    catfile($scratch, "dir-dst-d"));

ok(-d catfile($scratch, "dir-dst-d" , "dir-src-a"), "Copy many dirs -> existing dir ($scratch/dir-dst-d/dir-src-a is a dir)");
ok(-d catfile($scratch, "dir-dst-d" , "dir-src-b"), "Copy many dirs -> existing dir ($scratch/dir-dst-d/dir-src-b is a dir)");

# XXX should we actually fail ? 'cp' does
# Multiple directories -> non-existing (treat as directory)

Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-*"),
			    catfile($scratch, "dir-dst-e"));

ok(-d catfile($scratch, "dir-dst-e" , "dir-src-a"), "Copy many dirs -> new dir ($scratch/dir-dst-e/dir-src-a is a dir)");
ok(-d catfile($scratch, "dir-dst-e" , "dir-src-b"), "Copy many dirs -> new dir ($scratch/dir-dst-e/dir-src-b is a dir)");


# Single file -> deep directory
mkpath catfile($scratch, "one","two","three-a");
Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-a.txt"),
			    catfile($scratch, "one","two","three-a"));

ok(-f catfile($scratch, "one","two","three-a","file-src-a.txt"), "Copy file -> new deep dir ($scratch/one/two/three-a/file-src-a.txt)");

# Single file -> deep directory
Test::AutoBuild::Lib::_copy(catfile($scratch, "file-src-a.txt"),
			    catfile($scratch, "one","two","three-b","file-src-a.txt"));

ok(-f catfile($scratch, "one","two","three-b","file-src-a.txt"), "Copy file -> new deep dir ($scratch/one/two/three-b/file-src-a.txt)");

Test::AutoBuild::Lib::_copy(catfile($scratch, "dir-src-c"),
			    catfile($scratch, "dir-dst-f"));
ok(-f catfile($scratch, "dir-dst-f", "dir-src-c", "file-{src}-a.txt"), "Copy containing {}");

&create_dir($scratch, "remove-test");
&create_file($scratch, catfile("remove-test","file-a"));
&create_file($scratch, catfile("remove-test","file-b"));
&create_dir($scratch, catdir("remove-test","subdir-a"));
&create_file($scratch, catfile("remove-test","subdir-a","file-c"));

Test::AutoBuild::Lib::delete_files(catdir($scratch, "remove-test"));

opendir DIR, catdir($scratch, "remove-test")
  or die "cannot read $scratch/remove-test: $!";
my @files = sort readdir DIR;
ok($#files == 1, "two entries in directory");
is($files[0], ".", "entry '.' in directory");
is($files[1], "..", "entry '..' in directory");
closedir DIR;


sub create_file {
  my $base = shift;
  my $name = shift;

  my $file = catfile($base, $name);
  open FILE, ">$file"
    or die "cannot create $file: $!";

  print FILE $name, "\n";

  close FILE;
}

sub create_dir {
  my $base = shift;
  my $name = shift;

  my $file = catfile($base, $name);

  mkdir $file, 0777;
}

sub content {
  my @args = @_;
  my $file = catfile(@args);

  open FILE, "<$file"
    or return undef;

  local $/ = undef;

  my $content = <FILE>;

  close FILE;

  return $content;
}
