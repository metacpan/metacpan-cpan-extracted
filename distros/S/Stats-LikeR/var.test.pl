#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;
use Time::HiRes;

my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
my @y = (3.8, 2.7, 4.0, 2.4);
my @z = (2.8, 3.4, 3.7, 2.2, 2.0);

my $t0 = Time::HiRes::time();
my $vt = var_test(\@x, \@y);
my $t1 = Time::HiRes::time();
printf("var_tests in %g seconds.\n", $t1-$t0);
p $vt; # R equivalent: fisher.test( matrix(c(10,2,3,15), nrow = 2)))

$t1 = Time::HiRes::time();
