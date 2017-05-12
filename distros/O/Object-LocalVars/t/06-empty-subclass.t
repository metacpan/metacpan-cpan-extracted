#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::EmptySubclass";

plan tests => TC() + TN() + 7;

my $o = test_constructor($class);

SKIP: {
    skip "because we don't have a $class object", TN() + 7  
        unless $o;
    ok( $o->set_name("Charlie"), "Naming object 'Charlie'");
    ok( $o->set_color("orange"), "... making him 'orange'");
    is( $o->desc, "I'm Charlie and I'm orange", 
        "... and his description is right");
    my $p = test_new($class);
    ok( $p->set_name("Curly"), 
        "Naming new object 'Curly'");
    ok( $p->set_color("blue"), "... and making him 'blue'");
    is( $p->desc, "I'm Curly and I'm blue", 
        "... and his description is right");
    is( $o->desc, "I'm Charlie and I'm orange", 
        "Charlie's description is still right");
}




