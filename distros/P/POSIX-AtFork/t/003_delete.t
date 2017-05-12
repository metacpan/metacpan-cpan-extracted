#!perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::SharedFork;
use POSIX::AtFork;

my $prepare = 0;
my $parent  = 0;
my $child   = 0;

sub prepare1 { $prepare += 3 }
sub prepare2 { $prepare += 5 }

sub parent1 { $parent += 3 }
sub parent2 { $parent += 5 }

sub child1 { $child += 3 }
sub child2 { $child += 5 }

POSIX::AtFork->add_to_prepare(\&prepare1);
POSIX::AtFork->add_to_prepare(\&prepare2);
POSIX::AtFork->add_to_prepare(\&prepare1);
POSIX::AtFork->add_to_prepare(\&prepare2);
POSIX::AtFork->delete_from_prepare(\&prepare2);

POSIX::AtFork->add_to_parent(\&parent1);
POSIX::AtFork->add_to_parent(\&parent2);
POSIX::AtFork->add_to_parent(\&parent1);
POSIX::AtFork->add_to_parent(\&parent2);
POSIX::AtFork->delete_from_parent(\&parent2);

POSIX::AtFork->add_to_child(\&child1);
POSIX::AtFork->add_to_child(\&child2);
POSIX::AtFork->add_to_child(\&child1);
POSIX::AtFork->add_to_child(\&child2);
POSIX::AtFork->delete_from_child(\&child2);


my $pid = fork;
die "Failed to fork: $!" if not defined $pid;

if($pid != 0) {
    is $prepare, 6, '&prepare in parent';
    is $parent,  6, '&parent in parent';
    is $child,   0, '&child in parent';
    waitpid $pid, 0;
    exit;
}
else {
    is $prepare, 6, '&prepare in child';
    is $parent,  0, '&parent in child';
    is $child,   6, '&child in child';
    exit;
}


