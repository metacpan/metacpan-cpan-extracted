#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 3;
chdir($_point);
ok(mkdir("dir"),"mkdir");
ok(-d "dir","dir exists");
rmdir("dir");
ok(! -d "dir","dir removed");
