#!/usr/bin/perl -w

no Test::AtRuntime;
use Test::More;

sub foo {
    TEST {
        fail('foo');
    }
}

sub bar {
    TEST {
        fail('bar');
    }
}


foo();
bar();


pass("no Test::AtRuntime");
