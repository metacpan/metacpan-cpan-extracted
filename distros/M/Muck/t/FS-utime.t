#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 3;
my (@stat);
chdir($_point);
system("echo frog >file");
ok(utime(1,2,"file"),"set utime");
@stat = stat("file");
is($stat[8],1,"atime");
is($stat[9],2,"mtime");
unlink("file");
