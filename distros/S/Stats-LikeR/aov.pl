#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my $t0 = Time::HiRes::time();
my $aov = aov(
	{
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0]
	},
'yield ~ ctrl');
my $t1 = Time::HiRes::time();
printf("aov calculation in %g seconds.\n", $t1-$t0);
p $aov;

