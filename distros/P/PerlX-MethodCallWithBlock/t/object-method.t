#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Test::More;
use PerlX::MethodCallWithBlock;
use Echo;

my $echoer = bless {}, "Echo";

# $echoer->say {
#     pass "echo (no args)";
# };

$echoer->say(42) {
    pass "echo 42";
};

done_testing;
