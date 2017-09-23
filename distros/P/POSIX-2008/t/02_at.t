#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);
use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Temp 'mktemp';
use POSIX::2008 qw(:at);
use Scalar::Util 'blessed';
use Test::More tests => 17;

my $rv;
my $buf;
my $tmpname = mktemp('tmpXXXXX');

opendir my $dot, '.' or die "Could not opendir(.)";

rmtree($tmpname);

$rv = eval { openat(undef, $tmpname, O_RDWR|O_CREAT|O_TRUNC) };

SKIP: {
  skip $@, 17 if !defined $rv && $@ && $@ =~ /not available/;

  ok(!defined $rv, 'openat with undef fd');

  $rv = eval { openat('xyz', $tmpname, O_RDWR|O_CREAT|O_TRUNC) };
  ok(!defined $rv, 'openat with invalid fd');

  $rv = openat($dot, "\0", O_RDWR|O_CREAT|O_TRUNC);
  ok(!defined $rv, 'openat with invalid path');

  # Perl < 5.22 doesn't support fileno for directory handles
  if (defined(my $fndot = fileno $dot)) {
    defined($rv = openat($fndot, $tmpname, O_RDWR|O_CREAT|O_TRUNC))
      or die "Coudn't openat($fndot, $tmpname): $!";
    like($rv, qr/^\d+$/, 'openat returns file descriptor');
  } else {
    pass('dummy');
  }

  defined($rv = openat($dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC))
    or die "Coudn't openat($dot, $tmpname): $!";
  like(blessed($rv), qr/^POSIX::2008/, 'openat returns handle (1)');
  ok(-f $rv, 'openat returns file handle');
  ok(unlinkat($dot, $tmpname), "unlinkat: $tmpname (file)");

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
  defined($rv = openat($dot, $tmpname, O_RDONLY))
    or die "Coudn't openat(., $tmpname): $!";
  like(blessed($rv), qr/^POSIX::2008/, 'openat returns handle (2)');

  defined(openat($rv, $tmpname, O_RDWR|O_CREAT|O_TRUNC))
    or die "Coudn't openat(./$tmpname, $tmpname): $!";
  ok(readdir $rv, 'openat returns directory handle');
  unlinkat($rv, $tmpname);

  ok(unlinkat($dot, $tmpname, AT_REMOVEDIR), "unlinkat: directory $tmpname");
}

END {
  rmtree($tmpname);
}
