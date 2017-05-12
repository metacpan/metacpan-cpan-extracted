#!/usr/bin/env perl
# Test the fdio extensions.
#XXX many more tests (and benchmarking) needed

use lib 'lib';
use warnings;
use strict;

use Test::More tests => 4;

use POSIX::1003::FdIO qw(openfd closefd O_RDONLY);
use POSIX::Util       qw(:fdio);

my $fd = openfd __FILE__, O_RDONLY
    or die "cannot open myself: $!";
ok(defined $fd, "open file, fd = $fd");

my $readall = readfd_all $fd;
ok(defined $readall, "read all success");
cmp_ok(-s __FILE__, '==', length $readall, "all bytes");

ok((closefd($fd) ? 1 : 0), "closefd $fd");
