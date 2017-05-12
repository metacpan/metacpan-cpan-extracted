use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;
use File::Spec;

my $tmpdir = tempdir();

subtest 'constructor' => sub {
  my $dir = dir("$tmpdir/tmpdir");

  ok $dir->path, 'constructor contains the path';

  ok( File::Spec->file_name_is_absolute( $dir->path ),
    'and the path is absolute');

  ok !$dir->_handle, 'and its handle is not open';

  ok !$dir->exists, 'and the dir does not exist';
};

subtest 'input_path_is_absolute' => sub {
  my $dir_rel = dir('a/relative/../path');

  ok ( ! $dir_rel->is_absolute, 'input path is not absolute' );

  my $dir_abs = dir('/is/an/absolute/path');

  ok ( $dir_abs->is_absolute, 'input path is absolute' );
};

subtest 'forward_slashes' => sub {
  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'this test is for Win32', 1; fail };
    return;
  }

  my $dir = dir('t\\tmp\\tmpdir');

  ok $dir->path !~ /\\/,
    'path does not contain back slashes';
};

subtest 'absolute' => sub {
  my $dir = dir("$tmpdir/tmpdir");

  ok( File::Spec->file_name_is_absolute($dir->absolute),
    'dir name is absolute'
  );

  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'native check is only for Win32', 1; fail };
    return;
  }

  ok $dir->absolute ne $dir->absolute( native => 1 ),
    'paths vary according to the native option';

  ok $dir->absolute( native => 1 ) =~ /\\/,
    'native path does contain back slashes';
};

subtest 'relative' => sub {
  my $dir = dir("$tmpdir/tmpdir");

  ok( !File::Spec->file_name_is_absolute($dir->relative),
    'dir name is relative'
  );

  unless ( $^O eq 'MSWin32' ) {
    SKIP: { skip 'native check is only for Win32', 1; fail };
    return;
  }

  ok $dir->relative ne $dir->relative( native => 1 ),
    'paths vary according to the native option';

  ok $dir->relative( native => 1 ) =~ /\\/,
    'native path does contain back slashes';
};

subtest 'relative_with_explicit_base' => sub {
  my $dir = dir("$tmpdir/tmpdir/tmp");
  ok $dir->relative( base => $tmpdir ) eq 'tmpdir/tmp',
    'base path option works';
};

subtest 'default_directory' => sub {
  my $dir = dir();
  ok $dir->absolute eq dir('.')->absolute, 'default directory is current directory';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
