use strict;
use warnings;
use Test::More;
use Path::Extended;
use File::Path;
use File::Temp qw/tempdir/;

my $tmpdir = tempdir();

subtest 'subsumes' => sub {
  ok dir('t/foo/bar')->subsumes('t/foo/bar/baz'), 't/foo/bar subsumes t/foo/bar/baz';

  ok !dir('t/foo/bar')->subsumes('t/foo/baz/bar'), 't/foo/bar does not subsume t/foo/baz/bar';
};

subtest 'subsumes_win32' => sub {
  unless ($^O eq 'MSWin32') {
    SKIP: { skip 'this is Win32 only', 1; fail };
    return;
  }

  ok dir('C:/foo/bar')->subsumes('C:/foo/bar/baz'), 'C:/foo/bar subsumes C:/foo/bar/baz';
  ok !dir('C:/foo/bar')->subsumes('D:/foo/bar/baz'), 'C:/foo/bar does not subsume D:/foo/bar/baz';

  ok !dir('C:/foo/bar')->subsumes('C:/foo/baz/bar'), 't/foo/bar does not subsume t/foo/baz/bar';
};

done_testing;

END {
  rmtree $tmpdir if $tmpdir && -d $tmpdir;
}
