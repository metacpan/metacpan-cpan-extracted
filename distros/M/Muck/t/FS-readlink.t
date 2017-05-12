#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
plan tests => 4;

chdir($_point);
ok(symlink("abc","def"),"OS supports symlinks");
is(readlink("def"),"abc","OS supports symlinks");
ok(-l "def","symlink exists");
is(readlink("def"),"abc","readlink");
unlink("def");
