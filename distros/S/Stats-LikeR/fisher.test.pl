#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my $array_data = [
	[10, 2],
	[3, 15]
];
my $t0 = Time::HiRes::time();
my $ft = fisher_test($array_data);
my $t1 = Time::HiRes::time();
printf("Simple array calculation in %g seconds.\n", $t1-$t0);
p $ft; # R equivalent: fisher.test( matrix(c(10,2,3,15), nrow = 2)))
$t0 = Time::HiRes::time();
$ft = fisher_test( {
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
});
$t1 = Time::HiRes::time();
printf("Hash calculation in %g seconds.\n", $t1-$t0);
$t0 = Time::HiRes::time();
$ft = fisher_test( {
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
}, alternative => 'greater');
$t1 = Time::HiRes::time();
printf("Hash calculation in %g seconds.\n", $t1-$t0);
$ft = fisher_test( {
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
}, alternative => 'less');
p $ft;
$ft = fisher_test([[5, 0], [1, 4]]);
p $ft;
