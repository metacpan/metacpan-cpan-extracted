#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 1;
chdir($_point);
system("echo frog >file");
ok(open(FILE,"file"),"open");
close(FILE);
unlink("file");
