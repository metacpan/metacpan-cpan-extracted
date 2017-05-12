#!perl
use strict;
use warnings;
use Test::More tests => 7;
use Test::SharedFork;
use POSIX::AtFork qw(:all);
use POSIX qw(getpid);

my %h;
my $prepare = 0;
my $parent  = 0;
my $child   = 0;

pthread_atfork(
    sub { $h{$_[0]}++; $prepare++ },
    sub { $h{$_[0]}++; $parent++; },
    sub { $h{$_[0]}++; $child++; },
);

system $^X, '-e', '0';
is $?, 0;

`$^X -e 0`;
is $?, 0;

is $prepare, 2;
is $parent,  2;
is $child,   0;

is $h{system},   2;
is $h{backtick}, 2;

