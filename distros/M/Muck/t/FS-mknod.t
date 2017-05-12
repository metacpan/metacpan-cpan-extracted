#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 6;
use English;

my (@stat);

chdir($_point);
ok(!(system("touch reg"      )>>8),"create normal file");
ok(!(system("mknod fifo p"   )>>8),"create fifo");

chdir($_point);
ok(-e "reg" ,"normal file exists");
ok(-e "fifo","fifo exists");
ok(-f "reg" ,"normal file is normal file");
ok(-p "fifo","fifo is fifo");

map { unlink } qw(reg fifo);
