#!/usr/bin/perl
my $_point = $ENV{MUCKFS_TESTDIR};

use Test::More;
my (@names) = qw(abc def ghi jkl mno pqr stu jlk sfdaljk  sdfakjlsdfa kjldsf kjl;sdf akjl;asdf klj;asdf lkjsdflkjsdfkjlsdfakjsdfakjlsadfkjl;asdfklj;asdfkjl;asdfklj;asdfkjl;asdfkjlasdflkj;sadf);
@names = sort(@names);
plan tests => scalar @names;
chdir($_point);

# create entries
map { system("touch \"$_\"") } @names;

# make sure they exist in fuse dir
opendir(POINT,$_point);
@ents = readdir(POINT);
closedir(POINT);
@ents = sort(@ents);
map {
	shift(@ents) while($ents[0] eq '.' || $ents[0] eq '..');
	is(shift(@ents),$_,"ent $_")
} @names;

# remove them
map { unlink } @names;
