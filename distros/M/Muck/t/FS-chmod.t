#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};
use Test::More;
plan tests => 4;
chdir($_point);
system("echo frog >file");
ok(chmod(0644,"file"),"set unexecutable");
ok(!-x "file","unexecutable");
ok(chmod(0755,"file"),"set executable");
ok(-x "file","executable");
unlink("file");
