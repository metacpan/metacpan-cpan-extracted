#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Temp 'mktemp';
use Test::More tests => 41;

use POSIX::2008;

my $tmpname = mktemp('tmpXXXXX');

sysopen my $fh, $tmpname, O_RDWR|O_CREAT|O_EXCL, 0600 or die "$tmpname: $!";
my $fd = fileno $fh;
syswrite $fh, '......';

#
# read/write
#
SKIP: {
  sysseek $fh, 0, 0;
  if (! defined &POSIX::2008::write) {
    cmp_ok(syswrite($fh, '111222'), '==', 6, '... syswrite(fh) bytes written (fallback)');
    skip 'write() UNAVAILABLE', 2;
  }
  my $rv = eval { POSIX::2008::write($fh, '', -3) };
  ok(!$rv && $@ =~ /negative/, 'write fails due to negative size');
  cmp_ok(POSIX::2008::write($fh, '111'), '==', 3, 'write(fh) bytes written');
  cmp_ok(POSIX::2008::write($fd, '222', 10), '==', 3, 'write(fd) bytes written');
}
SKIP: {
  my $buf;
  sysseek $fh, 0, 0;
  if (! defined &POSIX::2008::read) {
    cmp_ok(sysread($fh, $buf, 6), '==', 6, '... sysread(fh) bytes read (fallback)');
    cmp_ok($buf, 'eq', '111222', '  sysread(fh) string read (fallback)');
    skip 'read() UNAVAILABLE', 3;
  }
  my $rv = eval { POSIX::2008::read($fh, my $buf, -3) };
  ok(!$rv && $@ =~ /negative/, 'read fails due to negative size');
  cmp_ok(POSIX::2008::read($fh, $buf, 3), '==', 3, 'read(fh) bytes read');
  cmp_ok($buf, 'eq', '111', 'read(fh) string read');
  cmp_ok(POSIX::2008::read($fd, $buf, 3), '==', 3, 'read(fd) bytes read');
  cmp_ok($buf, 'eq', '222', 'read(fh) string read');
}

#
# pread/pwrite
#
SKIP: {
  if (! defined &POSIX::2008::pwrite) {
    sysseek $fh, 0, 0;
    cmp_ok(syswrite($fh, '333444'), '==', 6, '... syswrite(fh) bytes written (fallback)');
    skip 'pwrite() UNAVAILABLE', 6;
  }
  my $rv = eval { POSIX::2008::pwrite($fh, 'foo', -3, 0) };
  ok(!$rv && $@ =~ /negative/, 'pwrite fails due to negative size');
  foreach my $buf_offset (-1290880921, -4, 4, ~0) {
    my $rv = eval { POSIX::2008::pwrite($fh, 'foo', undef, 0, $buf_offset) };
    ok(!$rv && $@ =~ /outside/, 'pwrite fails due to invalid buf_offset');
  }
  cmp_ok(POSIX::2008::pwrite($fh, '444', undef, 3), '==', 3, 'pwrite(fh) bytes written');
  cmp_ok(POSIX::2008::pwrite($fd, '333', undef, 0), '==', 3, 'pwrite(fd) bytes written');
}
SKIP: {
  my $buf;
  if (! defined &POSIX::2008::pread) {
    sysseek $fh, 0, 0;
    cmp_ok(sysread($fh, $buf, 6), '==', 6, '... sysread(fh) bytes read (fallback)');
    cmp_ok($buf, 'eq', '333444', '... sysread(fh) string read (fallback)');
    skip 'pread() UNAVAILABLE', 5;
  }
  my $rv = eval { POSIX::2008::pread($fh, my $buf, -3, 0) };
  ok(!$rv && $@ =~ /negative/, 'pread fails due to negative size');
  foreach my $buf_offset (-1290880921, -4) {
    my $buf = 'foo';
    my $rv = eval { POSIX::2008::pread($fh, $buf, 0, 0, $buf_offset) };
    ok(!$rv && $@ =~ /outside/, 'pwrite fails due to invalid buf_offset');
  }
  cmp_ok(POSIX::2008::pread($fh, $buf, 3, 3), '==', 3, 'pread(fh) bytes read');
  cmp_ok($buf, 'eq', '444', 'pread(fh) string read');
  cmp_ok(POSIX::2008::pread($fd, $buf, 3, 0), '==', 3, 'pread(fd) bytes read');
  cmp_ok($buf, 'eq', '333', 'pread(fh) string read');
}

#
# readv/writev
#
SKIP: {
  sysseek $fh, 0, 0;
  if (! defined &POSIX::2008::writev) {
    cmp_ok(syswrite($fh, '555666'), '==', 6, '... syswrite(fh) bytes written (fallback)');
    skip 'writev() UNAVAILABLE', 2;
  }
  my $rv = eval { POSIX::2008::writev($fh, "foobar") };
  # Note: The /i is needed because some Perls say "ARRAY", others say "array".
  ok(!$rv && $@ =~ /not an ARRAY/i);
  no warnings 'uninitialized';
  cmp_ok(POSIX::2008::writev($fh, ['55', '', undef, '5']), '==', 3, 'writev(fh) bytes written');
  cmp_ok(POSIX::2008::writev($fd, ['6', undef, '', '66']), '==', 3, 'writev(fd) bytes written');
}
SKIP: {
  sysseek $fh, 0, 0;
  if (! defined &POSIX::2008::readv) {
    my $buf;
    cmp_ok(sysread($fh, $buf, 6), '==', 6, '... sysread(fh) bytes read (fallback)');
    cmp_ok($buf, 'eq', '555666', '... sysread(fh) string read (fallback)');
    skip 'readv() UNAVAILABLE', 6;
  }
  my $rv;
  my @buf1;
  my @buf2;
  $rv = eval { POSIX::2008::readv($fh, my $buf, 'foobar') };
  ok(!$rv && $@ =~ /not an ARRAY/i, 'readv fails due to non-arrayref');
  $rv = eval { POSIX::2008::readv($fh, my $buf, [0, -1, 0]) };
  ok(!$rv && $@ =~ /negative/, 'readv fails due to negative size');
  cmp_ok(POSIX::2008::readv($fh, @buf1, [0, 1, 0, 2]), '==', 3, 'readv(fh) bytes read');
  cmp_ok(scalar(@buf1), '==', 4, 'readv(fh) buffers read');
  cmp_ok(join('', @buf1), 'eq', '555', 'readv(fh) strings read');
  cmp_ok(POSIX::2008::readv($fd, @buf2, [2, 0, 1, 0]), '==', 3, 'readv(fd) bytes read');
  cmp_ok(scalar(@buf2), '==', 4, 'readv(fd) buffers read');
  cmp_ok(join('', @buf2), 'eq', '666', 'readv(fd) strings read');
}

#
# preadv/pwritev
#
SKIP: {
  if (! defined &POSIX::2008::pwritev) {
    sysseek $fh, 0, 0;
    cmp_ok(syswrite($fh, '777888'), '==', 6, '... syswrite(fh) bytes written (fallback)');
    skip 'pwritev() UNAVAILABLE', 1;
  }
  no warnings 'uninitialized';
  cmp_ok(POSIX::2008::pwritev($fh, ['88', '', undef, '8'], 3), '==', 3, 'pwritev(fh) bytes written');
  cmp_ok(POSIX::2008::pwritev($fd, ['7', undef, '', '77'], 0), '==', 3, 'pwritev(fd) bytes written');
}
SKIP: {
  if (! defined &POSIX::2008::preadv) {
    my $buf;
    sysseek $fh, 0, 0;
    cmp_ok(sysread($fh, $buf, 6), '==', 6, '... sysread(fh) bytes read (fallback)');
    cmp_ok($buf, 'eq', '777888', '... sysread(fh) string read (fallback)');
    skip 'preadv() UNAVAILABLE', 4;
  }
  my @buf1;
  my @buf2;
  cmp_ok(POSIX::2008::preadv($fh, @buf1, [2, 0, 0, 1], 3), '==', 3, 'preadv(fh) bytes read');
  cmp_ok(scalar(@buf1), '==', 4, 'preadv(fh) buffers read');
  cmp_ok(join('', @buf1), 'eq', '888', 'preadv(fh) strings read');
  cmp_ok(POSIX::2008::preadv($fd, @buf2, [1, 0, 0, 2], 0), '==', 3, 'preadv(fd) bytes read');
  cmp_ok(scalar(@buf2), '==', 4, 'preadv(fd) buffers read');
  cmp_ok(join('', @buf2), 'eq', '777', 'preadv(fh) strings read');
}

close $fh;

END {
  rmtree($tmpname) if defined $tmpname && $tmpname =~ /^tmp/;
}
