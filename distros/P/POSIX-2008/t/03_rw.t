#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);
use Fcntl qw(:DEFAULT :mode);
use File::Path 'rmtree';
use File::Temp 'mktemp';
use POSIX::2008 qw(:prw :rw);
use Test::More tests => 9;

my $rv;
my $buf;
my $tmpname = mktemp('tmpXXXXX');

sysopen my $fh, $tmpname, O_RDWR|O_CREAT|O_TRUNC;

cmp_ok(writev($fh, [qw(01 23 45 67 89)]), '==', 10, 'writev bytes written');
cmp_ok(pread($fh, $buf, 4096, 0), '==', 10, 'pread 10 bytes read');
is($buf, '0123456789', 'pread content');
cmp_ok(pread($fh, $buf, 3, 7, 3), '==', 3, 'pread 3 bytes read');
is($buf, '012789', 'pread content at offset');

cmp_ok(pwrite($fh, 'foo', undef, 1), '==', 3, 'pwrite bytes written');

if ($^O eq 'cygwin') {
  pass('dummy') for 1 .. 3;
}
else {
  cmp_ok(preadv($fh, my @b, [1, 3]), '==', 4, 'preadv bytes read');
  is($b[0], '0', 'preadv buffer 0');
  is($b[1], 'foo', 'preadv buffer 1');
}

close $fh;

END {
  rmtree($tmpname);
}
