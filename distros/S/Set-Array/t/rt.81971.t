#!/usr/bin/env perl

use strict;
use warnings;

use Set::Array;

use Test::More tests => 5;

# -------------

my($set) = Set::Array -> new('cat', 'sat', 'mat');

$set -> delete('(');

my($get) = join(', ', $set -> print);

diag "<$get>";

ok($get eq 'cat, sat, mat', 'Chars are quoted properly in delete()');

my($count) = $set -> count('.');

ok($count == 0, 'Chars are quoted properly in count()');

my($index) = $set -> index('cat');

ok($index == 0, 'Prefix is quoted properly in index()');

my($rindex) = $set -> rindex('sat');

ok($rindex == 1, 'Prefix is quoted properly in rindex()');

$rindex = $set -> rindex('at');

ok(! defined $rindex, 'Suffix is properly not matched in rindex()');
