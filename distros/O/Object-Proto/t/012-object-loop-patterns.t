#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test object module with various loop variable patterns

# Define test classes
Object::Proto::define('Point', qw(x y));
Object::Proto::define('Item', qw(val));
Object::Proto::define('Entry', qw(id name score));
Object::Proto::define('Cell', qw(r c));
Object::Proto::define('Data', qw(num));

# for with $attr
{
    my $obj = new Point 10, 20;
    my @attrs = ('x', 'y');
    my @result;
    for my $attr (@attrs) {
        push @result, $obj->$attr();
    }
    is_deeply(\@result, [10, 20], 'object accessors with $attr');
}
# for with $key
{
    my $obj = new Point 1, 2;
    my $sum = 0;
    for my $key ('x', 'y') {
        $sum += $obj->$key();
    }
    is($sum, 3, 'object access with $key');
}
# for with $item coords
{
    my @specs = (
        [10, 20],
        [30, 40],
    );

    my @objects;
    for my $item (@specs) {
        push @objects, new Point @$item;
    }

    is($objects[0]->x(), 10, 'object from $item x');
    is($objects[1]->y(), 40, 'object from $item y');
}
# map with $_
{
    my @data = (1, 2, 3);

    my @objects = map { new Data $_ } @data;
    my @nums = map { $_->num() } @objects;
    is_deeply(\@nums, [1, 2, 3], 'objects from map with $_');
}
# for with $obj
{
    # Use parentheses to avoid parsing issues with indirect object syntax
    my $o1 = new Item(10);
    my $o2 = new Item(20);
    my $o3 = new Item(30);
    my @objects = ($o1, $o2, $o3);

    my $sum = 0;
    for my $obj (@objects) {
        $sum += $obj->val();
    }
    is($sum, 60, 'iterate objects with $obj');
}
# for with $n creating objects
{
    my @nums = (1, 2, 3);
    my @objects;
    for my $n (@nums) {
        push @objects, new Point $n, $n * $n;
    }

    my @squares;
    for my $obj (@objects) {
        push @squares, $obj->y();  # y holds squared value
    }
    is_deeply(\@squares, [1, 4, 9], 'objects with $n');
}
# nested $row/$col
{
    my @matrix;
    for my $row (1..2) {
        my @row_objs;
        for my $col (1..3) {
            push @row_objs, new Cell $row, $col;
        }
        push @matrix, \@row_objs;
    }

    is($matrix[0][0]->r(), 1, 'nested row 0 col 0');
    is($matrix[1][2]->c(), 3, 'nested row 1 col 2');
}
# while with $current
{
    my @objects = map { new Item $_ } (1..5);
    my $i = 0;
    my @vals;
    while ($i < @objects) {
        my $current = $objects[$i];
        push @vals, $current->val();
        $i++;
    }
    is_deeply(\@vals, [1, 2, 3, 4, 5], 'while with $current');
}
# grep with $_ on objects
{
    my @objects = map { new Data $_ } (1..10);
    my @evens = grep { $_->num() % 2 == 0 } @objects;
    is(scalar(@evens), 5, 'grep objects with $_');
}
# for with $entry named
{
    my @entries = (
        [1, 'alice', 90],
        [2, 'bob', 85],
    );

    my @objects;
    for my $entry (@entries) {
        push @objects, new Entry @$entry;
    }

    is($objects[0]->name(), 'alice', 'entry name from $entry');
    is($objects[1]->score(), 85, 'entry score from $entry');
}
done_testing();
