#!/usr/bin/env perl
use Test::More;
use syntax 'in';

ok 42 |in| [1..100];
ok 'foo' /in/ [qw(foo bar)];
ok 'x' <<in>> ['a'..'z'];
ok not 'X' |in| ['a'..'z'];

done_testing;
