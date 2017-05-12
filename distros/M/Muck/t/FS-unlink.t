#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 2;
chdir($_point);
system("touch file");
ok(-f "file","file exists");
unlink("file");
ok(! -f "file","file unlinked");
