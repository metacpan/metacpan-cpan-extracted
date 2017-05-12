#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use 5.010;
use PerlX::MethodCallWithBlock;

use MyEnum;
use Test::More;

my $x = MyEnum->new(0..10);

$x->each {
    pass "iteration $_";
};

done_testing;
