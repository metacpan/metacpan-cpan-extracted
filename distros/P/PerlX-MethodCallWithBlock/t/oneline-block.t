#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use lib 't/lib';

use PerlX::MethodCallWithBlock;

use Test::More;
use Echo;
use MyEnum;

Echo->say { pass "bar" };
Echo->say{pass};

my $x = MyEnum->new(0..10);
$x->each { pass "iteration $_"; };

done_testing;
