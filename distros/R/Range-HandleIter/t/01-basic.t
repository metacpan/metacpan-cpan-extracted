#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Range::HandleIter qw(range_handleiter);

my (@res, $iter);

@res=(); $iter=range_handleiter(1, 0);     while(<$iter>) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_handleiter(0, 0);     while(<$iter>) { push @res, $_ } is_deeply(\@res, [0]);
@res=(); $iter=range_handleiter(1, 5);     while(<$iter>) { push @res, $_ } is_deeply(\@res, [1,2,3,4,5]);
@res=(); $iter=range_handleiter(1, 6, 2);  while(<$iter>) { push @res, $_ } is_deeply(\@res, [1,3,5]);

@res=(); $iter=range_handleiter("b", "a"); while(<$iter>) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_handleiter("a", "a"); while(<$iter>) { push @res, $_ } is_deeply(\@res, ["a"]);
@res=(); $iter=range_handleiter("a", "z"); while(<$iter>) { push @res, $_ } is_deeply(\@res, ["a".."z"]);

done_testing;
