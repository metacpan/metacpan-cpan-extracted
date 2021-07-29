#!/usr/bin/perl
use warnings;
use strict;

{   package MyTest;
    use parent 'Test::Class::WithStrictPlan';
    use Test::More;

    sub t01 : Test( 1 ) {
        pass('First test passed');
        pass('Second test passed');
    }

    sub t02 : Test( no_plan ) {
        pass('First test passed');
    }
}

MyTest->runtests;
