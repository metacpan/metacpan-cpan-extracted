#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test function-style accessors with $_ in various loop patterns
# This tests the same patterns we fixed in file.c to ensure object module
# doesn't have the same bypass issues.

BEGIN {
    require Object::Proto;
    Object::Proto::define('Box', qw(width height depth));
    Object::Proto::define('Coord', qw(cx cy));  # Use cx/cy to avoid y/// conflict  
    Object::Proto::define('Item', qw(val));
    Object::Proto::import_accessors('Box');
    Object::Proto::import_accessors('Coord');
    Object::Proto::import_accessors('Item');
}

use Object::Proto;

# ============================================
# Basic $_ patterns
# ============================================

# foreach with $_ getter
{
    my @boxes = (
        new Box(10, 20, 30),
        new Box(40, 50, 60),
        new Box(70, 80, 90),
    );

    my @widths;
    for (@boxes) {
        push @widths, width($_);
    }
    is_deeply(\@widths, [10, 40, 70], 'foreach $_ getter');
}
# foreach with $_ setter
{
    my @boxes = (
        new Box(1, 2, 3),
        new Box(4, 5, 6),
    );

    for (@boxes) {
        width($_, 100);
    }

    is(width($boxes[0]), 100, 'first box width set via $_');
    is(width($boxes[1]), 100, 'second box width set via $_');
}
# map with $_ getter
{
    my @coords = (
        new Coord(1, 2),
        new Coord(3, 4),
        new Coord(5, 6),
    );

    my @cxs = map { cx($_) } @coords;
    is_deeply(\@cxs, [1, 3, 5], 'map $_ getter');
}
# map with $_ setter
{
    my @items = (
        new Item(10),
        new Item(20),
        new Item(30),
    );

    # Double each value
    map { val($_, val($_) * 2) } @items;

    my @vals = map { val($_) } @items;
    is_deeply(\@vals, [20, 40, 60], 'map $_ setter');
}
# grep with $_ getter
{
    my @boxes = (
        new Box(5, 10, 15),
        new Box(50, 60, 70),
        new Box(15, 20, 25),
    );

    my @big = grep { width($_) > 10 } @boxes;
    is(scalar(@big), 2, 'grep found 2 big boxes');
    is(width($big[0]), 50, 'first big box width');
    is(width($big[1]), 15, 'second big box width');
}
# ============================================
# Nested loops with $_
# ============================================

# nested foreach with $_
{
    my @outer = (
        new Coord(1, 1),
        new Coord(2, 2),
    );

    my @inner = (
        new Item(10),
        new Item(20),
    );

    my @results;
    for my $c (@outer) {
        for (@inner) {
            push @results, cx($c) * val($_);
        }
    }
    is_deeply(\@results, [10, 20, 20, 40], 'nested loop with $_ in inner');
}
# map inside foreach with $_
{
    my @boxes = (
        new Box(1, 2, 3),
        new Box(4, 5, 6),
    );

    my @all_dims;
    for (@boxes) {
        my $box = $_;  # capture
        push @all_dims, width($box), height($box), depth($box);
    }
    is_deeply(\@all_dims, [1, 2, 3, 4, 5, 6], 'foreach captures $_ for accessors');
}
# ============================================
# $_ with expression values
# ============================================

# setter with $_ and expression
{
    my @coords = (
        new Coord(1, 1),
        new Coord(2, 2),
        new Coord(3, 3),
    );

    my $offset = 0;
    for (@coords) {
        cx($_, cy($_) + $offset);
        $offset = $offset + 1;
    }

    my @cxs = map { cx($_) } @coords;
    is_deeply(\@cxs, [1, 3, 5], 'setter with $_ and expression');
}
# chained $_ operations
{
    my @items = (
        new Item(1),
        new Item(2),
        new Item(3),
    );

    # Triple each value using $_
    for (@items) {
        val($_, val($_) * 3);
    }

    my @tripled = map { val($_) } @items;
    is_deeply(\@tripled, [3, 6, 9], 'chained $_ get/set');
}
# ============================================
# $_ with sub calls
# ============================================

# $_ with sub call argument
{
    sub compute { return 42 }

    my @boxes = (
        new Box(1, 2, 3),
        new Box(4, 5, 6),
    );

    for (@boxes) {
        width($_, compute());
    }

    is(width($boxes[0]), 42, 'first box set via $_ with sub call');
    is(width($boxes[1]), 42, 'second box set via $_ with sub call');
}
# $_ with method call argument
{
    my @coords = (
        new Coord(10, 20),
        new Coord(30, 40),
    );

    # Set cx to cy value for each coord using method call
    for (@coords) {
        cx($_, $_->cy);
    }

    is(cx($coords[0]), 20, 'first coord cx set from method call');
    is(cx($coords[1]), 40, 'second coord cx set from method call');
}
# ============================================
# $_ preservation across operations
# ============================================

# $_ preserved in complex expression
{
    my @boxes = (
        new Box(2, 3, 4),
        new Box(5, 6, 7),
    );

    my @volumes = map {
        width($_) * height($_) * depth($_)
    } @boxes;

    is_deeply(\@volumes, [24, 210], 'volume calculation with $_');
}
# $_ in sort with accessor
{
    my @items = (
        new Item(30),
        new Item(10),
        new Item(20),
    );

    my @sorted = sort { val($a) <=> val($b) } @items;
    my @vals = map { val($_) } @sorted;
    is_deeply(\@vals, [10, 20, 30], 'sorted by accessor value');
}
# ============================================
# Edge cases with $_
# ============================================

# $_ with defined check
{
    my @items = (
        new Item(1),
        new Item(2),
    );

    # Make sure we handle the list correctly
    my @vals;
    for (@items) {
        push @vals, val($_) if defined $_;
    }
    is_deeply(\@vals, [1, 2], 'foreach handles defined objects');
}
# while with $_ aliasing
{
    my @boxes = (
        new Box(1, 1, 1),
        new Box(2, 2, 2),
    );

    my $idx = 0;
    while ($idx < scalar(@boxes)) {
        local $_ = $boxes[$idx];
        width($_, width($_) * 10);
        $idx = $idx + 1;
    }

    is(width($boxes[0]), 10, 'while with local $_ works');
    is(width($boxes[1]), 20, 'while with local $_ works for second');
}
done_testing;
