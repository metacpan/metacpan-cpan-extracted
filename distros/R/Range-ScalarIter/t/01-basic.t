#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Range::ScalarIter qw(range_scalariter);

my (@res, $iter);

@res=(); $iter=range_scalariter(1, 0);     while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_scalariter(0, 0);     while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, [0]);
@res=(); $iter=range_scalariter(1, 5);     while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, [1,2,3,4,5]);
@res=(); $iter=range_scalariter(1, 6, 2);  while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, [1,3,5]);

@res=(); $iter=range_scalariter("b", "a"); while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_scalariter("a", "a"); while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, ["a"]);
@res=(); $iter=range_scalariter("a", "z"); while(defined($_ = $$iter)) { push @res, $_ } is_deeply(\@res, ["a".."z"]);

done_testing;
