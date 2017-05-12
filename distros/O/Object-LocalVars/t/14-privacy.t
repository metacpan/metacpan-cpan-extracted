#!/usr/bin/perl
use strict;
use warnings;
use blib;  

use Test::More;
use Test::Exception;
use Scalar::Util qw( refaddr );

use t::Common;
# work around win32 console buffering
Test::More->builder->failure_output(*STDOUT) 
    if ($^O eq 'MSWin32' && $ENV{HARNESS_VERBOSE});

plan tests => 2 * TC() + 32;

my $class = "t::Object::Privacy";
my $subclass = "t::Object::Privacy::Sub";

my $o = test_constructor($class); 
my $p = test_constructor($subclass);

SKIP: {
    skip "because we don't have a $class object", 31
        unless $o;
    skip "because we don't have a $subclass object", 31  
        unless $p;
    # public
    lives_ok { $o->default_meth } 
        "call default method lives";
    lives_ok { $o->public_meth } 
        "call public method lives";
    lives_ok { $o->set_public_prop(1) } 
        "set public property lives";
    lives_ok { $o->public_prop } 
        "get public property lives";
    is( $o->public_prop, 1, "... and public property is correct");
    lives_ok { $o->set_class_public_prop(2) } 
        "set public class property lives";
    lives_ok { $o->class_public_prop } 
        "get public property lives";
    is( $o->class_public_prop, 2, "... and class public property is correct");

    # protected
    dies_ok { $o->protected_meth } 
        "call protected method should die";
    dies_ok { $o->set_protected_prop(1) } 
        "set protected property should die";
    dies_ok { $o->protected_prop } 
        "get protected property should die";
    dies_ok { $o->set_class_protected_prop(1) } 
        "set protected class property should die";
    dies_ok { $o->class_protected_prop } 
        "get protected class property should die";
    
    lives_ok { $p->protected_super_meth } 
        "call protected method from subclass lives";
    lives_ok { $p->protected_super_prop } 
        "call protected properties from subclass lives";
    is( $p->protected_super_prop, 3, 
        "... and protected property manipulations are correct");

    # private
    ok( ! UNIVERSAL::can( $class, "default_prop" ), 
        "default property shouldn't have an accessor");
    ok( ! UNIVERSAL::can( $class, "set_default_prop" ), 
        "default property shouldn't have a mutator");
    ok( ! UNIVERSAL::can( $class, "private_prop" ), 
        "private property shouldn't have an accessor");
    ok( ! UNIVERSAL::can( $class, "set_private_prop" ), 
        "private property shouldn't have a mutator");
    dies_ok { $o->private_meth } 
        "call private method should die";
    dies_ok { $p->private_super_meth } 
        "call private method from subclass should die";
    lives_ok { $o->private_prop_lives } 
        "private property alias used in class lives";
    is( $o->private_prop_lives, 15, 
        "... and private property aliases manipulations working");
    lives_ok { $o->private_meth_lives } 
        "call private method from class lives";
    is( $o->indirect_private( $p ), refaddr $p,
        "private method wraps \$self properly" 
    );

    # readonly
    dies_ok { $o->set_readonly_prop( 1 ) } 
        "call readonly property mutator should die";
    lives_ok { $p->set_readonly_super_prop( 1 ) } 
        "call readonly property mutator from subclass lives";
    is( $p->readonly_prop, 1, "... and readonly property is correct");
    dies_ok { $o->set_class_readonly_prop( 1 ) } 
        "call readonly property mutator should die";
    lives_ok { $p->set_class_readonly_super_prop( 1 ) } 
        "call readonly property mutator from subclass lives";
    is( $p->class_readonly_prop, 1, "... and readonly property is correct");
    
}



