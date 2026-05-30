#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my @aoh = (
	{
		a => 'A',
		b => 'B',
		r => '1st'
	},
	{
		a => 'C',
		b => 'D',
		r => '2nd'
	}
);
my $t0 = Time::HiRes::time();
my $hoh = aoh2hoh( \@aoh,  'r' );
my $t1 = Time::HiRes::time();
p $hoh;
printf("aoh2hoh in %g seconds\n", $t1 - $t0);
$t0 = Time::HiRes::time();
p @aoh;
$hoh = aoh2hoh( \@aoh );
$t1 = Time::HiRes::time();
p $hoh;
printf("aoh2hoh in %g seconds\n", $t1 - $t0);
