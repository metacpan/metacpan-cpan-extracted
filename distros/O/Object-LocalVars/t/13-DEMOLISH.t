#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;

# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

plan tests => TC() + TN() + 8;

my $class = "t::Object::Complete";

my $o = test_constructor($class, name => "Charlie");

SKIP: {
    skip "because we don't have a $class object", TN() + 8  
        unless $o;
    is( $o->name, "Charlie", "New object is named 'Charlie'");
    is( $o->get_count, 1, "Count of $class is correct");
    my $p = test_new($class, name => "Curly");
    is( $p->name, "Curly", "New object is named 'Curly'");
    is( $p->get_count, 2, "Count of $class is correct");
    $p = undef;
    ok( ! defined $p, "Curly destroyed" );
    is( $o->get_count, 1, "Count of $class is correct");
    $o = undef;
    ok( ! defined $o, "Charlie destroyed" );
    is( $class->get_count, 0, "Count of $class is correct");

}



