#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

plan tests => 6;

my $badclass = "t::Object::Paranoid";
my $class = "t::Object::Paranoid::Sub";

dies_ok { test_new($badclass, name => "Chad", color => "pink") }
    "paranoid BUILD dies on bad input to new";

my $o;
require_ok( $class );
lives_ok { $o = $class->new(name => "Charlie", color => "pink") } 
    "subclass with PREBUILD filters bad input to superclass new";

SKIP: {
    skip "because we don't have a $class object", 3 
        unless $o;
    is( $o->name, "Charlie", "New object is named 'Charlie'");
    is( $o->get_count, 1, "Count of $class is correct");
    is( $o->color, "pink", "Charlie's color (defined in subclass) is correct")
}



