#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Object::Proto;

# Define test classes once
Object::Proto::define('LeakCreate', 'val:Str');
Object::Proto::define('LeakKeys', 'a:Str', 'b:Int', 'c:Num');
Object::Proto::define('LeakSeal', 'x:Int');
Object::Proto::define('LeakMethod', 'count:Int:default(0)');
Object::Proto::define('LeakChain', 'data:Any');

# Add methods to test class
package LeakMethod;
sub increment { my $self = shift; $self->count($self->count + 1); }
package main;

# Warmup - create objects for tests
my $keys_obj = new LeakKeys 'str', 42, 3.14;
my $seal_obj = new LeakSeal x => 1;
my $method_obj = new LeakMethod;
my $chain_obj = new LeakChain data => 'test';
my $proto_parent = new LeakChain data => 'proto';
my $proto_child = new LeakChain data => 'child';
Object::Proto::set_prototype($proto_child, $proto_parent);

for (1..10) {
    $keys_obj->a;
    $method_obj->count;
}

# ============================================
# Object creation
# ============================================

# positional constructor no leak
{
    no_leaks_ok {
        for (1..50) {
            my $obj = new LeakKeys 'str', 42, 3.14;
        }
    } 'positional constructor does not leak';
}
# named constructor no leak
{
    no_leaks_ok {
        for (1..50) {
            my $obj = new LeakKeys a => 'str', b => 42, c => 3.14;
        }
    } 'named constructor does not leak';
}
# ============================================
# Accessor operations (should not leak)
# ============================================

# accessor get repeated no leak
{
    no_leaks_ok {
        for (1..500) {
            my $a = $keys_obj->a;
            my $b = $keys_obj->b;
            my $c = $keys_obj->c;
        }
    } 'accessor get repeated does not leak';
}
# accessor set repeated no leak
{
    no_leaks_ok {
        for (1..500) {
            $keys_obj->a('updated');
            $keys_obj->b(99);
            $keys_obj->c(2.71);
        }
    } 'accessor set repeated does not leak';
}
# ============================================
# Lock operations
# ============================================

# is_locked no leak
{
    no_leaks_ok {
        for (1..500) {
            my $l = Object::Proto::is_locked($seal_obj);
        }
    } 'is_locked does not leak';
}
# ============================================
# Method calls
# ============================================

# custom method call no leak
{
    no_leaks_ok {
        for (1..500) {
            $method_obj->increment;
        }
    } 'custom method does not leak';
}
# ============================================
# Prototype chain operations
# ============================================

# prototype get no leak
{
    no_leaks_ok {
        for (1..500) {
            my $p = Object::Proto::prototype($proto_child);
        }
    } 'prototype get does not leak';
}
# prototype chain access no leak
{
    no_leaks_ok {
        for (1..500) {
            my $d = $proto_child->data;
        }
    } 'prototype chain access does not leak';
}
# ============================================
# Lock/unlock operations
# ============================================

# lock/unlock cycle no leak
{
    my $obj = new LeakSeal x => 1;
    no_leaks_ok {
        for (1..200) {
            Object::Proto::lock($obj);
            my $l = Object::Proto::is_locked($obj);
            Object::Proto::unlock($obj);
        }
    } 'lock/unlock cycle does not leak';
}
# ============================================
# Type registration
# ============================================

# has_type no leak
{
    no_leaks_ok {
        for (1..500) {
            my $h1 = Object::Proto::has_type('Str');
            my $h2 = Object::Proto::has_type('NonExistent');
        }
    } 'has_type does not leak';
}
# list_types no leak
{
    no_leaks_ok {
        for (1..200) {
            my $types = Object::Proto::list_types();
        }
    } 'list_types does not leak';
}
# ============================================
# Freeze operations
# ============================================

# freeze and is_frozen no leak
{
    my $obj = new LeakSeal x => 42;
    Object::Proto::freeze($obj);
    no_leaks_ok {
        for (1..500) {
            my $f = Object::Proto::is_frozen($obj);
            my $v = $obj->x;
        }
    } 'freeze and is_frozen no leak';
}
done_testing();
