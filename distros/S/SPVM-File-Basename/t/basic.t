use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use File::Basename;

use SPVM 'Fn';
use SPVM::File::Basename;

use SPVM 'File::Basename';
use SPVM 'TestCase::File::Basename';

ok(SPVM::TestCase::File::Basename->test);

my $sep;
if ($^O eq 'MSWin32') {
  $sep = "\\";
}
else {
  $sep = "/";
}

warn "[Test Output]The file separator in this system is $sep";

# fileparse
{
  {
    my $path = "bar";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "foo${sep}bar";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "${sep}foo${sep}bar";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "${sep}foo${sep}bar${sep}";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "c:${sep}foo${sep}bar${sep}";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }

  {
    my $path = "foo/bar";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "/foo/bar";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "/foo/bar/";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
  {
    my $path = "c:/foo/bar/";
    is_deeply(SPVM::File::Basename->fileparse($path)->to_strings, [File::Basename::fileparse($path)]);
  }
}

# basename
{
  {
    my $path = "bar";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "foo${sep}bar";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "${sep}foo${sep}bar";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "${sep}foo${sep}bar${sep}";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "c:${sep}foo${sep}bar${sep}";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }

  {
    my $path = "foo/bar";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "/foo/bar";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "/foo/bar/";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
  {
    my $path = "c:/foo/bar/";
    is(SPVM::File::Basename->basename($path)->to_string, File::Basename::basename($path));
  }
}

# dirname
{
  {
    my $path = "bar";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "foo${sep}bar";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "${sep}foo${sep}bar";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "${sep}foo${sep}bar${sep}";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "c:${sep}foo${sep}bar${sep}";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "foo/bar";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "/foo/bar";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "/foo/bar/";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
  {
    my $path = "c:/foo/bar/";
    is(SPVM::File::Basename->dirname($path)->to_string, File::Basename::dirname($path));
  }
}

# Version
{
  is($SPVM::File::Basename::VERSION, SPVM::Fn->get_version_string('File::Basename'));
}

done_testing;
