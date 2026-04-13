#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

# Test that import_accessor works correctly with lazy attributes
# that have custom-named readers. Previously, the C-level func accessor
# installed by import_accessor would bypass lazy evaluation, returning
# undef instead of triggering the builder.

our $build_count = 0;

package LazyNamed;

sub _build_data {
    $main::build_count++;
    return "lazy-value";
}

package main;

BEGIN {
    require Object::Proto;

    # Two attributes: first non-lazy with reader(get_status),
    # second lazy with custom reader(get_data).
    # The bug: import_accessor for 'get_data' creates a direct slot
    # reader that bypasses lazy, returning undef.
    Object::Proto::define('LazyNamed',
        'status:Str:reader(get_status):writer(set_status)',
        'data:Str:lazy:builder(_build_data):reader(get_data):writer(set_data)'
    );

    Object::Proto::import_accessor('LazyNamed', 'status', 'status_func');
    Object::Proto::import_accessor('LazyNamed', 'data', 'data_func');
}

use Object::Proto;

# Verify method-level accessors work with lazy
{
    $build_count = 0;
    my $obj = LazyNamed->new();
    $obj->set_status("active");

    is($obj->get_status, 'active', 'Non-lazy named reader works');
    is($build_count, 0, 'Builder not called yet');
    is($obj->get_data, 'lazy-value', 'Lazy named reader triggers builder');
    is($build_count, 1, 'Builder called once');
}

# Verify func-level accessors also respect lazy
{
    $build_count = 0;
    my $obj = LazyNamed->new();
    status_func($obj, "running");

    is(status_func($obj), 'running', 'Non-lazy func accessor works');
    is($build_count, 0, 'Builder not called yet via func');
    is(data_func($obj), 'lazy-value', 'Lazy func accessor triggers builder');
    is($build_count, 1, 'Builder called once via func');
}

