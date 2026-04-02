#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test function-style accessors in various patterns

BEGIN {
    require Object::Proto;
    Object::Proto::define('Box', qw(width height depth));
    Object::Proto::define('Coord', qw(cx cy));  # Using cx/cy to avoid y() builtin conflict
    Object::Proto::define('Person', qw(name age));
    Object::Proto::import_accessors('Box');
    Object::Proto::import_accessors('Coord');
    Object::Proto::import_accessors('Person');
}

use Object::Proto;

# ============================================
# Basic function accessor in map
# ============================================

subtest 'func accessor in map getter' => sub {
    my @boxes = (
        new Box(10, 20, 30),
        new Box(40, 50, 60),
        new Box(70, 80, 90),
    );

    my @widths = map { width($_) } @boxes;
    is_deeply(\@widths, [10, 40, 70], 'map with func accessor getter');

    my @heights = map { height($_) } @boxes;
    is_deeply(\@heights, [20, 50, 80], 'map height accessor');
};

subtest 'func accessor in map setter' => sub {
    my @boxes = (
        new Box(1, 2, 3),
        new Box(4, 5, 6),
    );

    # Double all widths
    map { width($_, width($_) * 2) } @boxes;

    is(width($boxes[0]), 2, 'first box width doubled');
    is(width($boxes[1]), 8, 'second box width doubled');
};

# ============================================
# Function accessor in grep
# ============================================

subtest 'func accessor in grep' => sub {
    my @people = (
        new Person('Alice', 25),
        new Person('Bob', 17),
        new Person('Charlie', 30),
        new Person('Diana', 15),
    );

    my @adults = grep { age($_) >= 18 } @people;
    is(scalar(@adults), 2, 'grep found 2 adults');
    is(name($adults[0]), 'Alice', 'first adult is Alice');
    is(name($adults[1]), 'Charlie', 'second adult is Charlie');
};

# ============================================
# Function accessor in for loop
# ============================================

subtest 'func accessor in for loop' => sub {
    my @coords = (
        new Coord(1, 2),
        new Coord(3, 4),
        new Coord(5, 6),
    );

    my $sum = 0;
    for my $c (@coords) {
        $sum += cx($c);
    }
    is($sum, 9, 'sum of x coords');

    # Modify in loop
    for my $c (@coords) {
        cy($c, cy($c) + 10);
    }

    is(cy($coords[0]), 12, 'first coord y incremented');
    is(cy($coords[2]), 16, 'third coord y incremented');
};

subtest 'func accessor in foreach with $_' => sub {
    my @boxes = map { new Box($_, $_ * 2, $_ * 3) } (1..3);

    my @depths;
    for (@boxes) {
        push @depths, depth($_);
    }
    is_deeply(\@depths, [3, 6, 9], 'foreach with $_ and func accessor');
};

# ============================================
# Nested loops with func accessors
# ============================================

subtest 'nested loops with func accessors' => sub {
    my @row1 = map { new Coord($_, 1) } (1..3);
    my @row2 = map { new Coord($_, 2) } (1..3);
    my @grid = (\@row1, \@row2);

    my $total = 0;
    for my $row (@grid) {
        for my $pt (@$row) {
            $total += cx($pt) * cy($pt);
        }
    }
    # row1: 1*1 + 2*1 + 3*1 = 6
    # row2: 1*2 + 2*2 + 3*2 = 12
    is($total, 18, 'nested loop with func accessors');
};

# ============================================
# Complex argument expressions
# ============================================

subtest 'func accessor with expression argument' => sub {
    my $box = new Box(10, 20, 30);

    # Set width to height + depth
    width($box, height($box) + depth($box));
    is(width($box), 50, 'width set to height + depth');

    # Chained modifications
    height($box, width($box) / 2);
    is(height($box), 25, 'height set to width / 2');
};

subtest 'func accessor with method call result' => sub {
    my $c1 = new Coord(5, 10);
    my $c2 = new Coord(0, 0);

    # Use method call result as value
    cx($c2, $c1->cx);
    cy($c2, $c1->cy);

    is(cx($c2), 5, 'x set from method call');
    is(cy($c2), 10, 'y set from method call');
};

subtest 'func accessor with sub call result' => sub {
    my $box = new Box(1, 2, 3);

    sub compute_value { return 42 }

    width($box, compute_value());
    is(width($box), 42, 'width set from sub call');
};

# ============================================
# Multiple objects same call
# ============================================

subtest 'func accessor alternating objects' => sub {
    my $c1 = new Coord(1, 2);
    my $c2 = new Coord(10, 20);

    # Swap x values
    my $tmp = cx($c1);
    cx($c1, cx($c2));
    cx($c2, $tmp);

    is(cx($c1), 10, 'c1 x swapped');
    is(cx($c2), 1, 'c2 x swapped');
};

# ============================================
# Return value usage
# ============================================

subtest 'func accessor return value in expression' => sub {
    my $box = new Box(10, 20, 30);

    my $volume = width($box) * height($box) * depth($box);
    is($volume, 6000, 'volume from func accessors');

    # Setter return value
    my $new_width = width($box, 5);
    is($new_width, 5, 'setter returns new value');
    is(width($box), 5, 'value was set');
};

subtest 'chained func accessor calls' => sub {
    my $c = new Coord(0, 0);

    # Chain setters (each returns new value)
    my $final = cx($c, cx($c, 5) + 10);
    is($final, 15, 'chained setter result');
    is(cx($c), 15, 'chained setter applied');
};

# ============================================
# Edge cases
# ============================================

subtest 'func accessor with undef' => sub {
    my $person = new Person('Test', 30);

    name($person, undef);
    ok(!defined(name($person)), 'can set to undef');

    name($person, 'Restored');
    is(name($person), 'Restored', 'can set back from undef');
};

subtest 'func accessor with empty string' => sub {
    my $person = new Person('Test', 30);

    name($person, '');
    is(name($person), '', 'can set to empty string');
    ok(defined(name($person)), 'empty string is defined');
};

subtest 'func accessor with zero' => sub {
    my $coord = new Coord(5, 5);

    cx($coord, 0);
    is(cx($coord), 0, 'can set to zero');
    ok(defined(cx($coord)), 'zero is defined');
};

subtest 'func accessor with negative' => sub {
    my $coord = new Coord(5, 5);

    cx($coord, -10);
    is(cx($coord), -10, 'can set to negative');

    cy($coord, -0.5);
    is(cy($coord), -0.5, 'can set to negative float');
};

# ============================================
# Sort with func accessors
# ============================================

subtest 'sort with func accessor' => sub {
    my @people = (
        new Person('Charlie', 30),
        new Person('Alice', 25),
        new Person('Bob', 35),
    );

    my @by_age = sort { age($a) <=> age($b) } @people;
    is(name($by_age[0]), 'Alice', 'youngest first');
    is(name($by_age[2]), 'Bob', 'oldest last');

    my @by_name = sort { name($a) cmp name($b) } @people;
    is(name($by_name[0]), 'Alice', 'alphabetically first');
    is(name($by_name[2]), 'Charlie', 'alphabetically last');
};

# ============================================
# Accumulate with func accessors
# ============================================

subtest 'accumulate with func accessor' => sub {
    my @boxes = (
        new Box(2, 3, 4),
        new Box(1, 1, 1),
        new Box(5, 5, 5),
    );

    my $total_volume = 0;
    for my $b (@boxes) {
        $total_volume += width($b) * height($b) * depth($b);
    }
    # 24 + 1 + 125 = 150
    is($total_volume, 150, 'accumulated volume');
};

done_testing();
