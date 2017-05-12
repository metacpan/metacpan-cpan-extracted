#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 3;
chdir($_point);
system("echo frog >file");
ok(open(FILE,"file"),"open");
my ($data) = <FILE>;
close(FILE);
is(length($data),5,"right amount read");
is($data,"frog\n","right data read");
unlink("file");
