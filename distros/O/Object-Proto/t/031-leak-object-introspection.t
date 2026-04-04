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

# Define test classes
Object::Proto::define('LeakClone',
    'name:Str:required',
    'age:Int:default(0)',
    'tags:ArrayRef:default([])',
);

Object::Proto::define('LeakSimple', 'foo', 'bar', 'baz');

Object::Proto::define('LeakTyped',
    'str_val:Str',
    'int_val:Int:default(42)',
    'readonly_val:Str:readonly',
);

# Warmup
for (1..10) {
    my $obj = new LeakClone name => 'Warmup';
    my $clone = Object::Proto::clone($obj);
    my @props = Object::Proto::properties('LeakClone');
    my $info = Object::Proto::slot_info('LeakClone', 'name');
}

# ==== clone() leak tests ====

# clone basic no leak
{
    my $obj = new LeakClone name => 'Original', age => 30;
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
        }
    } 'clone basic no leak';
}
# clone with array default no leak
{
    my $obj = new LeakClone name => 'WithTags', age => 25;
    push @{$obj->tags}, 'tag1', 'tag2';
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
        }
    } 'clone with array no leak';
}
# clone frozen object no leak
{
    my $obj = new LeakClone name => 'Frozen', age => 40;
    Object::Proto::freeze($obj);
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
        }
    } 'clone frozen no leak';
}
# clone locked object no leak
{
    my $obj = new LeakClone name => 'Locked', age => 35;
    Object::Proto::lock($obj);
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
        }
    } 'clone locked no leak';
}
# clone and modify no leak
{
    my $obj = new LeakClone name => 'Source', age => 20;
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
            $clone->name('Modified');
            $clone->age(99);
        }
    } 'clone and modify no leak';
}
# ==== properties() leak tests ====

# properties list context no leak
{
    no_leaks_ok {
        for (1..1000) {
            my @props = Object::Proto::properties('LeakClone');
        }
    } 'properties list no leak';
}
# properties scalar context no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $count = Object::Proto::properties('LeakClone');
        }
    } 'properties scalar no leak';
}
# properties simple class no leak
{
    no_leaks_ok {
        for (1..1000) {
            my @props = Object::Proto::properties('LeakSimple');
        }
    } 'properties simple no leak';
}
# properties nonexistent class no leak
{
    no_leaks_ok {
        for (1..1000) {
            my @props = Object::Proto::properties('NonExistent');
            my $count = Object::Proto::properties('NonExistent');
        }
    } 'properties nonexistent no leak';
}
# ==== slot_info() leak tests ====

# slot_info typed property no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakClone', 'name');
        }
    } 'slot_info typed no leak';
}
# slot_info with default no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakClone', 'age');
        }
    } 'slot_info default no leak';
}
# slot_info array default no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakClone', 'tags');
        }
    } 'slot_info array no leak';
}
# slot_info untyped property no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakSimple', 'foo');
        }
    } 'slot_info untyped no leak';
}
# slot_info readonly property no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakTyped', 'readonly_val');
        }
    } 'slot_info readonly no leak';
}
# slot_info nonexistent property no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('LeakClone', 'nonexistent');
        }
    } 'slot_info nonexistent no leak';
}
# slot_info nonexistent class no leak
{
    no_leaks_ok {
        for (1..1000) {
            my $info = Object::Proto::slot_info('NonExistent', 'prop');
        }
    } 'slot_info missing class no leak';
}
# slot_info access all fields no leak
{
    no_leaks_ok {
        for (1..500) {
            my $info = Object::Proto::slot_info('LeakClone', 'name');
            my $n = $info->{name};
            my $i = $info->{index};
            my $t = $info->{type};
            my $r = $info->{is_required};
            my $ro = $info->{is_readonly};
        }
    } 'slot_info field access no leak';
}
# ==== Combined operations ====

# introspection combined no leak
{
    my $obj = new LeakClone name => 'Test', age => 25;
    no_leaks_ok {
        for (1..300) {
            my $clone = Object::Proto::clone($obj);
            my @props = Object::Proto::properties('LeakClone');
            for my $prop (@props) {
                my $info = Object::Proto::slot_info('LeakClone', $prop);
            }
        }
    } 'combined introspection no leak';
}
done_testing;
