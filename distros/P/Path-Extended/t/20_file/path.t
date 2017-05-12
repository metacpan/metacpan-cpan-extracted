use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;
use File::Spec;

my $tmpdir = tempdir();

subtest 'constructor' => sub {
  my $file = file("$tmpdir/file.txt");

  ok $file->path, 'constructor contains the path';

  ok( File::Spec->file_name_is_absolute( $file->path ), 'and the path is absolute');

  ok !$file->_handle, 'and its handle is not open';

  ok !$file->exists, 'and the file does not exist';
};

subtest 'input_path_is_absolute' => sub {
  my $file_rel = file('a/relative/../path/to/file');

  ok ( ! $file_rel->is_absolute, 'input path is not absolute' );

  my $file_abs = file('/is/an/absolute/path/to/file');

  ok ( $file_abs->is_absolute, 'input path is absolute' );
};

subtest 'forward_slashes' => sub {
  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'this test is for Win32', 1; fail; }
    return;
  }

  my $file = file('t\\tmp\\file.txt');

  ok $file->path !~ /\\/,
    'path does not contain back slashes';
};

subtest 'absolute' => sub {
  my $file = file("$tmpdir/file.txt");

  ok( File::Spec->file_name_is_absolute($file->absolute), 'file name is absolute' );

  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'native check is only for Win32', 1; fail; }
    return;
  }

  ok $file->absolute ne $file->absolute( native => 1 ), 'paths vary according to the native option';

  ok $file->absolute( native => 1 ) =~ /\\/, 'native path does contain back slashes';
};

subtest 'relative' => sub {
  my $file = file("$tmpdir/file.txt");

  ok( !File::Spec->file_name_is_absolute($file->relative), 'file name is relative' );

  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'native check is only for Win32', 1; fail }
    return;
  }

  ok $file->relative ne $file->relative( native => 1 ), 'paths vary according to the native option';

  ok $file->relative( native => 1 ) =~ /\\/, 'native path does contain back slashes';
};

subtest 'relative_with_explicit_base' => sub {
  my $file = file("$tmpdir/tmp/file.txt");
  ok $file->relative( base => $tmpdir ) eq 'tmp/file.txt', 'base path option works';
};

subtest 'basename' => sub {
  my $file = file("$tmpdir/file.txt");
  ok $file->basename eq 'file.txt', 'got basename';
};

subtest 'touch' => sub {
  my $file = file("$tmpdir/touch.txt");
  ok !$file->exists, 'file does not exist';
  ok $file->touch, 'created file';
  ok $file->exists, 'file does exist';
  ok $file->touch, 'changed mtime';

  $file->unlink;
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
