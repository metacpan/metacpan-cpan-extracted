#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 7;
chdir($_point);
system("echo hippity >womble");

ok(-f "womble","exists");
ok(!-f "rabbit","target file doesn't exist");
is(-s "womble",8,"right size");
system("ln","womble","rabbit");
ok(-f "womble","old file exists");
ok(-f "rabbit","target file exists");
is(-s "womble",8,"right size");
is(-s "rabbit",8,"right size");
unlink("womble");
unlink("rabbit");
