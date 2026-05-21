#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
my @x = (@xk, @yk, @zk);
my @g = (
	(map {'Normal subjects'} 0..4),
	(map {'Subjects with obstructive airway disease'} 0..3),
	map {'Subjects with asbestosis'} 0..4
);
my $t0 = Time::HiRes::time();
my $kt = kruskal_test(\@x, \@g);
my $t1 = Time::HiRes::time();
printf("Kruskal calculation in %g seconds.\n", $t1-$t0);
my %x = (
'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
);
$t0 = Time::HiRes::time();
$kt = kruskal_test(\%x);
$t1 = Time::HiRes::time();
printf("Kruskal calculation via HoA in %g seconds.\n", $t1-$t0);
p $kt;
