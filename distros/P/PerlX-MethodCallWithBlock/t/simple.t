#!/usr/bin/env perl
use strict;
use lib 't/lib';
use Echo;
use Test::More;
use PerlX::MethodCallWithBlock;

Echo->say(42) {
    my ($self, @args) = @_;

    pass "the block after bar is called";
    my $caller = caller;
    is($caller, "Echo", "called from Echo class");

    is($self, "Echo", "with 'Echo' class");
    is($args[0], 42, "and argument 42");
};

done_testing;
