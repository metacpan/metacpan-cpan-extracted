#!/usr/bin/env perl
use strict;
use 5.010;
use lib 't/lib';
use PerlX::MethodCallWithBlock;
use Test::More;
use Echo;

Echo->say {
    pass "the block after bar is called";
};

done_testing;
