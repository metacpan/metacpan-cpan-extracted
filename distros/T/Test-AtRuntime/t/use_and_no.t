#!/usr/bin/perl -w

use Test::AtRuntime;
use Test::More;

sub foo {
    # This test runs.
    TEST { pass('foo ran'); }
}

no Test::AtRuntime;

sub bar {
    # This test is not run.
    TEST { fail('bar ran') }
}

use Test::AtRuntime;

sub baz {
    # XXX This test should be run, but it isn't.  Might be a Filter::Simple
    # bug.
    TEST { pass('baz ran') }
}

no Test::AtRuntime;

sub ed {
    # This test is not run.
    TEST { fail('ed ran') }
}


foo();
bar();
baz();
ed();
