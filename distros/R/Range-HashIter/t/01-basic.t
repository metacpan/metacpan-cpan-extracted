#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Range::HashIter qw(range_hashiter);

my (@res, $iter);

@res=(); $iter=range_hashiter(1, 0);     while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_hashiter(0, 0);     while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, [0]);
@res=(); $iter=range_hashiter(1, 5);     while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, [1,2,3,4,5]);
@res=(); $iter=range_hashiter(1, 6, 2);  while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, [1,3,5]);

@res=(); $iter=range_hashiter("b", "a"); while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=range_hashiter("a", "a"); while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, ["a"]);
@res=(); $iter=range_hashiter("a", "z"); while(($_,undef)=each %$iter) { push @res, $_ } is_deeply(\@res, ["a".."z"]);

done_testing;
