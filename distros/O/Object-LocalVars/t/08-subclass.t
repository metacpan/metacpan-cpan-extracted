#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use t::Common;
use Scalar::Util 'refaddr';
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

my $class = "t::Object::Complete::Sub";

plan tests => TC() + 16;

my $o = test_constructor($class);

SKIP: {
    skip "because we don't have a $class object", TN() + 7  
        unless $o;
    is( $o->report_package, "t::Object::Complete", 
        "inherits report_package() method OK");
    ok( $o->set_name("Charlie"), "naming object 'Charlie'");
    ok( $o->set_color("orange"), "... making him 'orange'");
    ok( $o->set_shape("square"), "... making him 'square'");
    is( $o->desc, "I'm Charlie, my color is orange and my shape is square", 
        "... and his overridden description is right");
    ok( ! $o->can_roll, "additional can-roll() method works" );
    is( $o->report_color, undef, 
        "inherited method using alias for overridden property finds undef" );
    my $addr = refaddr $o;

    ok( exists $t::Object::Complete::DATA::name{$addr}, 
        "found property 'name' data in the superclass data hash" );
    ok( exists $t::Object::Complete::DATA::color{$addr}, 
        "found property 'color' data in the superclass data hash" );
    ok( exists $t::Object::Complete::Sub::DATA::color{$addr}, 
        "found property 'color' data in the subclass data hash" );
    ok( exists $t::Object::Complete::Sub::DATA::shape{$addr}, 
        "found property 'shape' data in the subclass data hash" );
    $o = undef;
    ok( ! defined $o, "releasing object reference" );
    ok( ! exists $t::Object::Complete::DATA::name{$addr}, 
        "... and superclass property 'name' data has been cleaned up" );
    ok( ! exists $t::Object::Complete::DATA::color{$addr}, 
        "... and superclass property 'color' data has been cleaned up" );
    ok( ! exists $t::Object::Complete::Sub::DATA::color{$addr}, 
        "... and subclass property 'color' data has been cleaned up" );
    ok( ! exists $t::Object::Complete::Sub::DATA::shape{$addr}, 
        "... and subclass property 'shape' data has been cleaned up" );
}




