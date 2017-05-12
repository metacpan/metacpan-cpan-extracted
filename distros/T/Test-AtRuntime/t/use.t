#!/usr/bin/perl -w

use Test::AtRuntime;
use Test::More;

sub foo {
    TEST {
        pass('foo');
    }
}

sub bar {
    TEST {
        pass('bar');
    }
}


foo();
bar();
