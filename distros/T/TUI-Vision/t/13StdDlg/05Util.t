use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::StdDlg::Util', qw( fexpand );
}

subtest 'fexpand basic expansion' => sub {
  my $path;

  # relative path
  $path = 'foo/bar.txt';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^[A-Z]:\\},
      'Windows: relative path expanded to absolute with drive'
    );
  }
  else {
    like(
      $path,
      qr{^/},
      'Unix: relative path expanded to absolute'
    );
  }
  like(
    $path,
    qr{foo\\bar\.txt$}i,
    'path suffix preserved'
  );
}; #/ 'fexpand basic expansion' => sub

subtest 'fexpand dot and dotdot' => sub {
  my $path;

  $path = 'a/./b/../c';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{\\a\\c$},
      'Windows: "." and ".." collapsed correctly'
    );
  }
  else {
    like(
      $path,
      qr{/a/c$},
      'Unix: "." and ".." collapsed correctly'
    );
  }
}; #/ 'fexpand dot and dotdot' => sub

subtest 'fexpand mixed separators' => sub {
  my $path;

  $path = 'a\\b/c\\d';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{\\a\\b\\c\\d$},
      'Windows: mixed separators normalized to backslash'
    );
  }
  else {
    like(
      $path,
      qr{/a/b/c/d$},
      'Unix: mixed separators normalized to slash'
    );
  }
}; #/ 'fexpand mixed separators' => sub

subtest 'fexpand drive-relative path' => sub {
  my $path;

  $path = 'C:foo\\bar';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^C:\\},
      'Windows: C:relative path expanded using drive C cwd'
    );
    like(
      $path,
      qr{foo\\bar$},
      'Windows: path suffix preserved'
    );
  }
  else {
    pass( 'Unix: drive-relative paths are not applicable' );
  }
}; #/ 'fexpand drive-relative path' => sub

subtest 'fexpand rooted path without drive' => sub {
  my $path;

  $path = '\\foo\\bar';
  fexpand( $path );

  if ( $^O eq 'MSWin32' ) {
    like(
      $path,
      qr{^[A-Z]:\\foo\\bar$},
      'Windows: rooted path uses current drive'
    );
  }
  else {
    pass( 'Unix: backslash-rooted path not applicable' );
  }
};

subtest 'fexpand home expansion' => sub {
  my $path = '~/testdir/file.txt';
  fexpand( $path );

  if ( $^O ne 'MSWin32' ) {
    like(
      $path,
      qr{^/},
      'Unix: ~/ expanded to absolute home directory'
    );
    like(
      $path,
      qr{/testdir/file\.txt$},
      'Unix: home expansion preserves suffix'
    );
  }
  else {
    pass( 'Windows: home expansion not supported' );
  }
}; #/ 'fexpand home expansion' => sub

subtest 'fexpand idempotency' => sub {
  my $path;

  $path = 'foo/bar';
  fexpand( $path );
  my $once = $path;

  fexpand( $path );
  my $twice = $path;

  is(
    $twice,
    $once,
    'fexpand is idempotent (second call does not change path)'
  );
};

done_testing();
