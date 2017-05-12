#!perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::SharedFork;
use POSIX::AtFork;

my $prepare = 0;
my $parent  = 0;
my $child   = 0;

POSIX::AtFork->add_to_prepare(sub{ $prepare++ }) for 1 .. 2;
POSIX::AtFork->add_to_parent( sub{ $parent++ })  for 1 .. 2;
POSIX::AtFork->add_to_child(  sub{ $child++ })   for 1 .. 2;

my $pid = fork;
die "Failed to fork: $!" if not defined $pid;

if($pid != 0) {
    is $prepare, 2, '&prepare in parent';
    is $parent,  2, '&parent in parent';
    is $child,   0, '&child in parent';
    waitpid $pid, 0;
    exit;
}
else {
    is $prepare, 2, '&prepare in child';
    is $parent,  0, '&parent in child';
    is $child,   2, '&child in child';
    exit;
}


