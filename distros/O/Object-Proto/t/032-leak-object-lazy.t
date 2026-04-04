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

# Define test classes with lazy attributes
Object::Proto::define('LeakLazy',
    'name:Str:required',
    'computed:Str:lazy:builder(_build_computed)',
);

package LeakLazy;
sub _build_computed {
    my $self = shift;
    return "computed_" . $self->name;
}
package main;

Object::Proto::define('LeakLazyDefault',
    'base:Int:default(10)',
    'doubled:Int:lazy:builder(_build_doubled)',
);

package LeakLazyDefault;
sub _build_doubled {
    my $self = shift;
    return $self->base * 2;
}
package main;

Object::Proto::define('LeakLazyClear',
    'counter:Int:default(0)',
    'cached:Str:lazy:builder(_build_cached):clearer',
);

package LeakLazyClear;
our $BUILD_COUNT = 0;
sub _build_cached {
    my $self = shift;
    $BUILD_COUNT++;
    return "cache_" . $self->counter . "_" . $BUILD_COUNT;
}
package main;

# Warmup
for (1..10) {
    my $obj = new LeakLazy name => 'Warmup';
    my $c = $obj->computed;
}

# lazy builder first access no leak
{
    no_leaks_ok {
        for (1..500) {
            my $obj = new LeakLazy name => 'Test';
            my $val = $obj->computed;  # triggers builder
        }
    } 'lazy first access no leak';
}
# lazy builder repeated access no leak
{
    my $obj = new LeakLazy name => 'Cached';
    # First access triggers builder
    my $first = $obj->computed;
    no_leaks_ok {
        for (1..1000) {
            my $val = $obj->computed;  # cached, no rebuild
        }
    } 'lazy repeated access no leak';
}
# lazy with default dependency no leak
{
    no_leaks_ok {
        for (1..500) {
            my $obj = new LeakLazyDefault;
            my $val = $obj->doubled;
        }
    } 'lazy default dependency no leak';
}
# lazy clear and rebuild no leak
{
    $LeakLazyClear::BUILD_COUNT = 0;
    my $obj = new LeakLazyClear counter => 1;
    no_leaks_ok {
        for (1..300) {
            my $val = $obj->cached;    # access (builds if needed)
            $obj->clear_cached();      # clear cache
            $val = $obj->cached;       # rebuild
        }
    } 'lazy clear rebuild no leak';
}
# lazy multiple objects no leak
{
    no_leaks_ok {
        for (1..300) {
            my $obj1 = new LeakLazy name => 'One';
            my $obj2 = new LeakLazy name => 'Two';
            my $c1 = $obj1->computed;
            my $c2 = $obj2->computed;
        }
    } 'lazy multiple objects no leak';
}
# lazy object clone no leak
{
    my $obj = new LeakLazy name => 'Source';
    my $orig = $obj->computed;  # trigger builder first
    no_leaks_ok {
        for (1..500) {
            my $clone = Object::Proto::clone($obj);
            my $val = $clone->computed;  # should use cloned value
        }
    } 'lazy clone no leak';
}
done_testing;
