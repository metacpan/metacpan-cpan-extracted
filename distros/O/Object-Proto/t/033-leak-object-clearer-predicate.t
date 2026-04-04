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

# Define test classes with clearer and predicate
Object::Proto::define('LeakClearer',
    'name:Str:clearer',
    'age:Int:clearer:default(0)',
);

Object::Proto::define('LeakPredicate',
    'title:Str:predicate',
    'count:Int:predicate:default(0)',
);

Object::Proto::define('LeakBoth',
    'value:Str:clearer:predicate',
    'data:ArrayRef:clearer:predicate:default([])',
);

# Warmup
for (1..10) {
    my $obj = new LeakClearer name => 'Warmup', age => 1;
    $obj->clear_name;
    $obj = new LeakPredicate title => 'Test';
    my $has = $obj->has_title;
}

# ==== Clearer tests ====

# clearer basic no leak
{
    my $obj = new LeakClearer name => 'Test', age => 25;
    no_leaks_ok {
        for (1..1000) {
            $obj->clear_name;
            $obj->name('Restored');
        }
    } 'clearer basic no leak';
}
# clearer with default no leak
{
    my $obj = new LeakClearer name => 'Test', age => 50;
    no_leaks_ok {
        for (1..1000) {
            $obj->clear_age;
            my $val = $obj->age;  # should return default
        }
    } 'clearer default no leak';
}
# clearer on already undef no leak
{
    my $obj = new LeakClearer;
    no_leaks_ok {
        for (1..1000) {
            $obj->clear_name;  # already undef
        }
    } 'clearer undef no leak';
}
# ==== Predicate tests ====

# predicate true no leak
{
    my $obj = new LeakPredicate title => 'Title';
    no_leaks_ok {
        for (1..1000) {
            my $has = $obj->has_title;
        }
    } 'predicate true no leak';
}
# predicate false no leak
{
    my $obj = new LeakPredicate;
    no_leaks_ok {
        for (1..1000) {
            my $has = $obj->has_title;
        }
    } 'predicate false no leak';
}
# predicate with default no leak
{
    my $obj = new LeakPredicate;
    no_leaks_ok {
        for (1..1000) {
            my $has = $obj->has_count;  # has default, so true
        }
    } 'predicate default no leak';
}
# ==== Combined clearer + predicate ====

# clearer predicate combo no leak
{
    my $obj = new LeakBoth value => 'data';
    no_leaks_ok {
        for (1..500) {
            my $has = $obj->has_value;
            $obj->clear_value;
            $has = $obj->has_value;
            $obj->value('restored');
        }
    } 'clearer predicate combo no leak';
}
# array clearer predicate no leak
{
    my $obj = new LeakBoth;
    no_leaks_ok {
        for (1..500) {
            my $has = $obj->has_data;
            $obj->data([]);  # set fresh array
            push @{$obj->data}, 'item';
            $obj->clear_data;
        }
    } 'array clearer predicate no leak';
}
# multiple objects clearer no leak
{
    no_leaks_ok {
        for (1..300) {
            my $obj = new LeakClearer name => 'Test', age => 20;
            $obj->clear_name;
            $obj->clear_age;
        }
    } 'multiple clearer no leak';
}
# multiple objects predicate no leak
{
    no_leaks_ok {
        for (1..300) {
            my $obj = new LeakPredicate title => 'T';
            my $has1 = $obj->has_title;
            my $has2 = $obj->has_count;
        }
    } 'multiple predicate no leak';
}
done_testing;
