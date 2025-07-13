#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Spec;
use File::Temp 'mktemp';
use Scalar::Util qw(blessed looks_like_number);

use Test::More tests => 27;
use POSIX::2008 ':at';

my $HAVE_WEIRD_DIR_MODE = $^O =~ /^(?:MSWin32|cygwin)$/ || do {
  if (open my $fh, '<', '/proc/version') {
    <$fh> =~ /microsoft/i;
  }
  else {
    0;
  }
};

my $rv;
my $atfdcwd = defined &AT_FDCWD ? &AT_FDCWD : undef;
my $tmpname = mktemp('tmpXXXXX');
rmtree($tmpname);

SKIP: {
  if (! defined &openat) {
    skip 'openat() UNAVAILABLE', 27;
  }

  umask 0;
  opendir my $dot, File::Spec->curdir() or die "Could not opendir(.): $!";

  $rv = openat(undef, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  ok(!defined $rv, 'openat with undef fd');

  $rv = eval { openat('xyz', $tmpname, O_RDWR|O_CREAT|O_TRUNC) };
  ok(!defined $rv, 'openat with invalid fd');

  $rv = openat($dot, "\0", O_RDWR|O_CREAT|O_TRUNC);
  ok(!defined $rv, 'openat with invalid path');

  $rv = openat(AT_FDCWD, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  ok(looks_like_number($rv),
     "openat(AT_FDCWD=$atfdcwd, $tmpname) returns file descriptor");
  ok(-e $tmpname, "$tmpname exists");

  $rv = openat(\AT_FDCWD, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  like(blessed($rv), qr/^IO::File/,
       "openat(\\AT_FDCWD=\\$atfdcwd, $tmpname) returns file handle");

  # Perl < 5.22 doesn't support fileno for directory handles
  if (defined(my $fndot = fileno $dot)) {
    $rv = openat($fndot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
    ok(looks_like_number($rv), "openat(fd=$fndot, $tmpname) returns file descriptor");
  }
  else {
    pass("This Perl doesn't support fileno for directory handles");
  }

  $rv = openat($dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  like(blessed($rv), qr/^IO::File/, "openat(fh, $tmpname) returns file handle");
  ok(-f $rv, 'handle references a regular file');
  ok(unlinkat($dot, $tmpname), "unlinkat(fh, $tmpname)");
  ok(! -e $tmpname, "$tmpname is gone");

  ok(symlinkat('abc', $dot, $tmpname), "symlinkat: $tmpname \-> abc");
  is(readlinkat($dot, $tmpname), 'abc', 'readlinkat');
  ok(unlinkat($dot, $tmpname), "unlinkat: $tmpname (symlink)");

  ok(mkdirat($dot, $tmpname, 0700), "mkdirat: $tmpname");

  my @stat = fstatat($dot, $tmpname);
  ok(scalar(@stat), 'fstatat ok after mkdirat');
  ok(S_ISDIR($stat[2]), 'fstatat S_ISDIR after mkdirat');
  cmp_ok(
    ($HAVE_WEIRD_DIR_MODE ? 0700 : $stat[2] & 0777), '==', 0700,
    'fstatat mode after mkdirat'
  );

  ok(fchmodat($dot, $tmpname, 0755), 'fchmodat');

  @stat = fstatat($dot, $tmpname);
  ok(scalar(@stat), 'fstatat ok after fchmodat');
  ok(S_ISDIR($stat[2]), 'fstatat S_ISDIR after fchmodat');
  cmp_ok(
    ($HAVE_WEIRD_DIR_MODE ? 0755 : $stat[2] & 0777), '==', 0755,
    'fstatat mode after fchmodat'
  );

  # Don't use O_DIRECTORY here because it's not always available. We don't need
  # it anyway because we know we've just created a directory.
  $rv = openat($dot, $tmpname, O_RDONLY);
  like(blessed($rv), qr/^IO::Dir/, 'openat returns directory handle');

  ok(openat($rv, $tmpname, O_RDWR|O_CREAT|O_TRUNC), 'openat() in subdir');
  ok(readdir $rv, 'readdir() on handle from openat()');
  ok(unlinkat($rv, $tmpname), 'unlinkat() in subdir');

  ok(unlinkat($dot, $tmpname, AT_REMOVEDIR), "unlinkat: directory $tmpname");
}

END {
  rmtree($tmpname);
}
