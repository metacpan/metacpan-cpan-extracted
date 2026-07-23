#!/usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Errno ':POSIX';
use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Temp 'mktemp';
use Test::More tests => 60;

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
  ok(!$rv && $@ =~ /Negative/, 'write fails due to negative size');
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
  ok(!$rv && $@ =~ /Negative/, 'read fails due to negative size');
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
  ok(!$rv && $@ =~ /Negative/, 'pwrite fails due to negative size');
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
  ok(!$rv && $@ =~ /Negative/, 'pread fails due to negative size');
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
  if (! defined &POSIX::2008::writev) {
    skip 'writev() UNAVAILABLE', 18;
  }

  my ($rv, $buf);
  sysseek $fh, 0, 0;
  truncate $fh, 0;

  no warnings 'uninitialized';
  cmp_ok(POSIX::2008::writev($fh, [undef, '', '0', '11']), '==', 3, 'writev(fh) bytes written');
  cmp_ok(POSIX::2008::writev($fh, ['22', undef, '', '3']), '==', 3, 'writev(fh) bytes written');
  cmp_ok(POSIX::2008::writev($fh, ['4', '55', undef, '']), '==', 3, 'writev(fh) bytes written');
  cmp_ok(POSIX::2008::writev($fh, ['', '6', '77', undef]), '==', 3, 'writev(fh) bytes written');
  sysseek $fh, 0, 0;
  sysread $fh, $buf, 4096;
  cmp_ok($buf, 'eq', '011223455677');

  my $teststring = 'abcdef:ABCDEF';
  my @offsets_ok = (
    0,
    int(length($teststring)/2),
    length($teststring)-1,
    length($teststring),
    -1,
    -int(length($teststring)/2),
    -length($teststring),
  );
  my @offsets_nok = (
    +length($teststring)+1,
    -length($teststring)-1,
    ~0,
    +(~0 >> 1),
    -(~0 >> 1),
  );
  my $data_expected = join '', map substr($teststring, $_), @offsets_ok;
  my $bufs = [ map [$teststring, $_], @offsets_ok ];
  sysseek $fh, 0, 0;
  truncate $fh, 0;
  $rv = POSIX::2008::writev($fh, $bufs);
  cmp_ok($rv, '==', length($data_expected), 'writev(fh, arrayrefs) bytes written');
  sysseek $fh, 0, 0;
  sysread $fh, $buf, 4096;
  cmp_ok($buf, 'eq', $data_expected, 'writev(fh, arrayrefs) data written');

  foreach my $offset (@offsets_nok) {
    $rv = eval { POSIX::2008::writev($fh, [ [$teststring, $offset] ]) };
    ok(!defined($rv), "writev() croaks due to invalid offset $offset (rv:$rv)");
    like($@, qr/outside string/, "writev() offset $offset should be outside string");
  }
  
  $rv = eval { POSIX::2008::writev($fh, "foobar") };
  # /i is needed because some Perls say "ARRAY", others say "array".
  ok(!defined($rv) && $@ =~ /not an ARRAY/i);
}
SKIP: {
  if (! defined &POSIX::2008::readv) {
    skip 'readv() UNAVAILABLE', 10;
  }
  my $rv;
  my @buf1;
  my @buf2;
  sysseek $fh, 0, 0;
  truncate $fh, 0;
  syswrite $fh, 'abcdef';
  sysseek $fh, 0, 0;

  $rv = eval { my $buf = 'foobar'; POSIX::2008::readv($fh, $buf, []) };
  ok(!$rv && $@ =~ /'buffers' is not an ARRAY/i, 'readv rejects non-arrayref buffers');

  $rv = eval { my $buf = {}; POSIX::2008::readv($fh, $buf, []) };
  ok(!$rv && $@ =~ /'buffers' is not an ARRAY/i, 'readv rejects non-arrayref buffers');

  $rv = eval { my $buf = []; POSIX::2008::readv($fh, $buf, 'foobar') };
  ok(!$rv && $@ =~ /not an ARRAY/i, 'readv rejects non-arrayref sizes');

  $rv = eval { POSIX::2008::readv($fh, my $buf, [0, -1, 0]) };
  ok(!$rv && $@ =~ /Negative/, 'readv rejects negative size');

  cmp_ok(POSIX::2008::readv($fh, @buf1, [0, 1, 0, 2]), '==', 3, 'readv(fh) bytes read');
  cmp_ok(scalar(@buf1), '==', 4, 'readv(fh) buffers read');
  cmp_ok(join('', @buf1), 'eq', 'abc', 'readv(fh) strings read');
  cmp_ok(POSIX::2008::readv($fd, @buf2, [2, 0, 1, 0]), '==', 3, 'readv(fd) bytes read');
  cmp_ok(scalar(@buf2), '==', 4, 'readv(fd) buffers read');
  cmp_ok(join('', @buf2), 'eq', 'def', 'readv(fd) strings read');
}

#
# preadv/pwritev
#
SKIP: {
  if (! defined &POSIX::2008::pwritev) {
    skip 'pwritev() UNAVAILABLE', 3;
  }
  sysseek $fh, 0, 0;
  truncate $fh, 0;
  syswrite $fh, '......';
  no warnings 'uninitialized';
  cmp_ok(POSIX::2008::pwritev($fh, ['88', '', undef, '8'], 3), '==', 3, 'pwritev(fh) bytes written');
  cmp_ok(POSIX::2008::pwritev($fd, ['7', undef, '', '77'], 0), '==', 3, 'pwritev(fd) bytes written');
  sysseek $fh, 0, 0;
  sysread $fh, my $buf, 4096;
  cmp_ok($buf, 'eq', '777888');
}
SKIP: {
  if (! defined &POSIX::2008::preadv) {
    skip 'preadv() UNAVAILABLE', 7;
  }
  my (@buf1, @buf2);
  cmp_ok(POSIX::2008::preadv($fh, @buf1, [2, 0, 0, 1], 3), '==', 3, 'preadv(fh) bytes read');
  cmp_ok(scalar(@buf1), '==', 4, 'preadv(fh) buffers read');
  cmp_ok(join('', @buf1), 'eq', '888', 'preadv(fh) strings read');
  cmp_ok(POSIX::2008::preadv($fd, @buf2, [1, 0, 0, 2], 0), '==', 3, 'preadv(fd) bytes read');
  cmp_ok(scalar(@buf2), '==', 4, 'preadv(fd) buffers read');
  cmp_ok(join('', @buf2), 'eq', '777', 'preadv(fh) strings read');

  my $rv = POSIX::2008::preadv($fd, @buf2, [1, 0, 0, 2], -1);
  ok(!defined($rv) && $! == EINVAL, 'preadv() with negative offset sets errno EINVAL');
}

close $fh;

END {
  rmtree($tmpname) if defined $tmpname && $tmpname =~ /^tmp/;
}
