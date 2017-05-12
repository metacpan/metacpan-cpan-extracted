#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});


my $class =     "t::Object::Complete";
my $subclass =  "t::Object::Complete::Sub";

plan tests => 2 * TC() + 3;

my $o = test_constructor($class);

SKIP: {
    skip "because we don't have a $class object", TC() + 2  
        unless $o;
    is( $o->get_count, 1, "Superclass object counter is 1");
    my $p = test_constructor($subclass);
    is( $p->get_subcount, 1, "Subclass object counter is 1"); 
    is( $o->get_count, 2, "Superclass object counter is 2");
}




