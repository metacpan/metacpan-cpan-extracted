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
Object::Proto::define('LeakPerson', 'name:Str', 'age:Int');
Object::Proto::define('LeakWithDefault', 'val:Str:default(hello)');
Object::Proto::define('LeakReadonly', 'fixed:Str:readonly');
Object::Proto::define('LeakTyped', 'num:Num', 'arr:ArrayRef', 'hash:HashRef');

# Warmup
for (1..10) {
    my $obj = new LeakPerson name => 'Warmup', age => 1;
    $obj->name;
    $obj->age;
}

# accessor get no leak
{
    my $obj = new LeakPerson name => 'Test', age => 25;
    no_leaks_ok {
        for (1..1000) {
            my $n = $obj->name;
            my $a = $obj->age;
        }
    } 'accessor get no leak';
}
# accessor set no leak
{
    my $obj = new LeakPerson name => 'Start', age => 1;
    no_leaks_ok {
        for (1..1000) {
            $obj->name('Updated');
            $obj->age(42);
        }
    } 'accessor set no leak';
}
# default value access no leak
{
    my $obj = new LeakWithDefault;
    no_leaks_ok {
        for (1..1000) {
            my $v = $obj->val;
        }
    } 'default value no leak';
}
# readonly access no leak
{
    my $obj = new LeakReadonly fixed => 'immutable';
    no_leaks_ok {
        for (1..1000) {
            my $v = $obj->fixed;
        }
    } 'readonly access no leak';
}
# typed properties no leak
{
    my $obj = new LeakTyped num => 3.14, arr => [1, 2, 3], hash => { a => 1 };
    no_leaks_ok {
        for (1..1000) {
            my $n = $obj->num;
            my $a = $obj->arr;
            my $h = $obj->hash;
        }
    } 'typed get no leak';
}
# typed setter no leak
{
    my $obj = new LeakTyped num => 0, arr => [], hash => {};
    my $arr = [1, 2, 3];
    my $hash = { x => 1 };
    no_leaks_ok {
        for (1..1000) {
            $obj->num(3.14);
            $obj->arr($arr);
            $obj->hash($hash);
        }
    } 'typed set no leak';
}
# prototype operations no leak
{
    my $parent = new LeakPerson name => 'Parent', age => 50;
    my $child = new LeakPerson name => 'Child', age => 20;
    Object::Proto::set_prototype($child, $parent);

    no_leaks_ok {
        for (1..1000) {
            my $proto = Object::Proto::prototype($child);
        }
    } 'prototype get no leak';
}
# freeze check no leak
{
    my $obj = new LeakPerson name => 'Freeze', age => 30;
    Object::Proto::freeze($obj);
    no_leaks_ok {
        for (1..1000) {
            my $f = Object::Proto::is_frozen($obj);
        }
    } 'is_frozen no leak';
}
# lock check no leak
{
    my $obj = new LeakPerson name => 'Lock', age => 30;
    Object::Proto::lock($obj);
    no_leaks_ok {
        for (1..1000) {
            my $l = Object::Proto::is_locked($obj);
        }
    } 'is_locked no leak';
}
# type introspection no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $has = Object::Proto::has_type('Str');
            my @types = Object::Proto::list_types();
        }
    } 'type introspection no leak';
}
done_testing;
