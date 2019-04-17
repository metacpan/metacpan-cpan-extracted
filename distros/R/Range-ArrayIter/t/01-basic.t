#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Range::ArrayIter qw(range_arrayiter);

my (@res, $iter);

@res=(); $iter=range_arrayiter(1, 0);     for(@$iter) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_arrayiter(0, 0);     for(@$iter) { push @res, $_ } is_deeply(\@res, [0]);
@res=(); $iter=range_arrayiter(1, 5);     for(@$iter) { push @res, $_ } is_deeply(\@res, [1,2,3,4,5]);
@res=(); $iter=range_arrayiter(1, 6, 2);  for(@$iter) { push @res, $_ } is_deeply(\@res, [1,3,5]);

@res=(); $iter=range_arrayiter("b", "a"); for(@$iter) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_arrayiter("a", "a"); for(@$iter) { push @res, $_ } is_deeply(\@res, ["a"]);
@res=(); $iter=range_arrayiter("a", "z"); for(@$iter) { push @res, $_ } is_deeply(\@res, ["a".."z"]);

done_testing;
