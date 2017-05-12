#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 13;

use POSIX::1003::FdIO;   # load all

my $fd = openfd __FILE__, O_RDONLY
    or die "cannot open myself: $!";
ok(defined $fd, "open file, fd = $fd");

cmp_ok(seekfd($fd, 0,  SEEK_SET), '==', 0,  'tell');
cmp_ok(seekfd($fd, 10, SEEK_SET), '==', 10, 'tell');
cmp_ok(seekfd($fd, 0,  SEEK_CUR), '==', 10, 'tell');

# try to read a few bytes
my $string;
my $len = readfd $fd, $string, 20;
ok(defined $string, "read string");
cmp_ok($len, '==', 20, 'returned length');
cmp_ok(length $string, '==', 20, 'check length');
cmp_ok(seekfd($fd, 0,  SEEK_CUR), '==', 30, 'tell');
cmp_ok(tellfd($fd), '==', 30, 'tellfd');

my $fh = fdopen $fd, 'r';
isa_ok($fh, 'GLOB', 'now also connected as fh');

ok((closefd($fd) ? 1 : 0), "closefd $fd");

# only SEEK_ keys in %seek
my $non_seek = grep !/^SEEK_/, keys %seek;
cmp_ok($non_seek, '==', 0, join(',',keys %seek));

# only O_ keys in %mode
my $non_mode = grep !/^O_/, keys %mode;
cmp_ok($non_mode, '==', 0, join(',',keys %mode));
