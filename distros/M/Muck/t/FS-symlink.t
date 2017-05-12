#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 4;

chdir($_point);
system("echo hello >abc");
ok(symlink("abc","def"),"symlink created");
ok(-l "def","symlink exists");
is(readlink("def"),"abc","it worked");
my $txt = `cat def`;
chomp($txt);
is($txt,"hello","contents match too");
unlink("def");
