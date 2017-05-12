#!perl
use strict;
use warnings;
use Test::More tests => 6;
use Test::SharedFork;
use POSIX::AtFork qw(:all);

my $prepare = 0;
my $parent  = 0;
my $child   = 0;

pthread_atfork(
    sub { $prepare++ },
    sub { $parent++ },
    sub { $child++ },
);

my $pid = fork;
die "Failed to fork: $!" if not defined $pid;

if($pid != 0) {
    is $prepare, 1, '&prepare in parent';
    is $parent,  1, '&parent in parent';
    is $child,   0, '&child in parent';
    waitpid $pid, 0;
    exit;
}
else {
    is $prepare, 1, '&prepare in child';
    is $parent,  0, '&parent in child';
    is $child,   1, '&child in child';
    exit;
}


