#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Range::Iterator;

my (@res, $iter);

@res=(); $iter=Range::Iterator->new(1, 0);     while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=Range::Iterator->new(0, 0);     while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, [0]);
@res=(); $iter=Range::Iterator->new(1, 5);     while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, [1,2,3,4,5]);
@res=(); $iter=Range::Iterator->new(1, 6, 2);  while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, [1,3,5]);
@res=(); $iter=Range::Iterator->new("b", "a"); while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, []);
@res=(); $iter=Range::Iterator->new("a", "a"); while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, ["a"]);
@res=(); $iter=Range::Iterator->new("a", "z"); while(defined($_=$iter->next)) { push @res, $_ } is_deeply(\@res, ["a".."z"]);

done_testing;
