#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Temp 'mktemp';
use Scalar::Util qw(blessed looks_like_number);

use Test::More tests => 23;
use POSIX::2008 ':at';

my $rv;
my $tmpname = mktemp('tmpXXXXX');
rmtree($tmpname);

SKIP: {
  if (! defined &openat) {
    skip 'openat() UNAVAILABLE', 23;
  }

  umask 0;
  opendir my $dot, '.' or die "Could not opendir(.): $!";

  $rv = openat(undef, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  ok(!defined $rv, 'openat with undef fd');

  $rv = eval { openat('xyz', $tmpname, O_RDWR|O_CREAT|O_TRUNC) };
  ok(!defined $rv, 'openat with invalid fd');

  $rv = openat($dot, "\0", O_RDWR|O_CREAT|O_TRUNC);
  ok(!defined $rv, 'openat with invalid path');

  $rv = openat(AT_FDCWD, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  ok(looks_like_number($rv), 'openat(AT_FDCWD, ...) returns file descriptor');
  ok(-e $tmpname, "$tmpname exists");

  $rv = openat(\AT_FDCWD, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  like(blessed($rv), qr/^POSIX::2008/, 'openat(\AT_FDCWD, ...) returns handle');

  # Perl < 5.22 doesn't support fileno for directory handles
  if (defined(my $fndot = fileno $dot)) {
    $rv = openat($fndot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
    ok(looks_like_number($rv), 'openat(fd, ...) returns file descriptor');
  }
  else {
    pass("This Perl doesn't support fileno for directory handles");
  }

  $rv = openat($dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  like(blessed($rv), qr/^POSIX::2008/, 'openat(fh, ...) returns handle (file)');
  ok(-f $rv, 'handle references a regular file');
  ok(unlinkat($dot, $tmpname), "unlinkat(fh, $tmpname)");
  ok(! -e $tmpname, "$tmpname is gone");

  ok(symlinkat('abc', $dot, $tmpname), "symlinkat: $tmpname \-> abc");
  is(readlinkat($dot, $tmpname), 'abc', 'readlinkat');
  ok(unlinkat($dot, $tmpname), "unlinkat: $tmpname (symlink)");

  ok(mkdirat($dot, $tmpname, 0700), "mkdirat: $tmpname");

  my @stat = fstatat($dot, $tmpname);
  ok(@stat && S_ISDIR($stat[2]) && ($stat[2] & 07777) == 0700, 'fstatat after mkdirat');

  ok(fchmodat($dot, $tmpname, 0755), 'fchmodat');

  @stat = fstatat($dot, $tmpname);
  ok(@stat && S_ISDIR($stat[2]) && ($stat[2] & 07777) == 0755, 'fstatat after fchmodat');

  # Don't use O_DIRECTORY here because it's not always available. We don't need
  # it anyway because we know we've just created a directory.
  $rv = openat($dot, $tmpname, O_RDONLY);
  like(blessed($rv), qr/^POSIX::2008/, 'openat returns handle (dir))');

  ok(openat($rv, $tmpname, O_RDWR|O_CREAT|O_TRUNC), 'openat() in subdir');
  ok(readdir $rv, 'readdir() on handle from openat()');
  ok(unlinkat($rv, $tmpname), 'unlinkat() in subdir');

  ok(unlinkat($dot, $tmpname, AT_REMOVEDIR), "unlinkat: directory $tmpname");
}

END {
  rmtree($tmpname);
}
