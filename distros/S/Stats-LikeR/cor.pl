#!/usr/bin/env perl

use 5.042.2;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';
use DDP {output => 'STDOUT', array_max => 10, show_memsize => 1};
use Devel::Confess 'color';
use Stats::LikeR;

my $x_na = [1, 2,     3, undef,  5, 5, 6,     undef,7];
my $y_na = [2, undef, 6, 8,     10, 9, undef, 14,  16];
my $r = cor($x_na, $y_na);
p $r;
my $x1 = [ 1, 2, 3, 4 ];
my $y1 = [ 2, 4, 6, 8 ];
my $res_perfect = cor($x1, $y1, 'pearson');
p $res_perfect;
$r = cor([1,1],[1,1]);
p $r;
=my $res = cor_test([1,2,3], [1,3,2], method => 'pearson');
p $res;
