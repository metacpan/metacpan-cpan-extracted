#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);
use Fcntl qw(:DEFAULT :mode);
use File::Temp 'mktemp';
use POSIX::2008 qw(:at :prw);
use Scalar::Util 'blessed';
use Test::More tests => 21;

opendir my $dot, '.' or die "Could not opendir(.)";

my $rv;
my $buf;
my $tmpname = mktemp('tmpXXXXX');
unlink $tmpname;

$rv = openat(undef, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
ok(!defined $rv, 'openat with undef fd');

$rv = eval { openat('xyz', $tmpname, O_RDWR|O_CREAT|O_TRUNC) };
ok(!defined $rv, 'openat with invalid fd');

$rv = openat($dot, "\0", O_RDWR|O_CREAT|O_TRUNC);
ok(!defined $rv, 'openat with invalid path');

if (defined fileno $dot) { # Perl < 5.22 doesn't support fileno for directory handles
  $rv = openat(fileno $dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
  ok($rv =~ /^[1-9]\d*$/, 'openat returns file descriptor');
}
else {
  pass('dummy');
}

$rv = openat($dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
ok(blessed($rv) =~ /^POSIX::2008/, 'openat returns handle (1)');
ok(-f $rv, 'openat returns file handle');

ok(unlinkat($dot, $tmpname), "unlinkat: $tmpname");

ok(symlinkat('abc', $dot, $tmpname), "symlinkat: $tmpname \-> abc");
ok(readlinkat($dot, $tmpname) eq 'abc', 'readlinkat');
unlinkat($dot, $tmpname);

ok(mkdirat($dot, $tmpname, 0700), "mkdirat: $tmpname");

my @stat = fstatat($dot, $tmpname);
ok(@stat && S_ISDIR($stat[2]) && ($stat[2] & 07777) == 0700, 'fstatat after mkdirat');

ok(fchmodat($dot, $tmpname, 0755), 'fchmodat');

@stat = fstatat($dot, $tmpname);
ok(@stat && S_ISDIR($stat[2]) && ($stat[2] & 07777) == 0755, 'fstatat after fchmodat');

# Don't use O_DIRECTORY here because it's not always available. We don't need
# it anyway because we know we've just created a directory.
$rv = openat($dot, $tmpname, O_RDONLY);
ok(blessed($rv) =~ /^POSIX::2008/, 'openat returns handle (2)');

openat($rv, $tmpname, O_RDWR|O_CREAT|O_TRUNC);
ok(readdir $rv, 'openat returns directory handle');
unlinkat($rv, $tmpname);

ok(unlinkat($dot, $tmpname, AT_REMOVEDIR), "unlinkat: directory $tmpname");

my $fh = openat($dot, $tmpname, O_RDWR|O_CREAT|O_TRUNC);

syswrite $fh, '0123456789';
ok(pread($fh, $buf, 0, 4096) == 10, 'pread nbytes');
ok($buf eq '0123456789', 'pread content');

ok(pwrite($fh, 'foobar', 2) == 6, 'pwrite nbytes');

ok(pread($fh, $buf, 1, 8) == 8, 'pread nbytes (again)');
ok($buf eq '1foobar8', "pread content: $buf");
close $fh;

END {
  unlink $tmpname;
  rmdir $tmpname;
}
