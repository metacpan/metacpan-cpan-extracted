#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $slime_pool = NetHack::ItemPool->new;
my $slime_mold = $slime_pool->new_item("a slime mold");
is($slime_mold->nutrition_each, 250);
is($slime_mold->total_nutrition, 250);
ok($slime_mold->is_custom_fruit, "slime mold is custom fruit");
is($slime_mold->appearance, 'slime mold');
is($slime_mold->identity, 'slime mold');

my $molds = $slime_pool->new_item("3 slime molds");
is($molds->nutrition_each, 250);
is($molds->total_nutrition, 750);
ok($molds->is_custom_fruit, "slime molds is custom fruit");
is($molds->appearance, 'slime mold');
is($molds->identity, 'slime mold');


my $brain_pool = NetHack::ItemPool->new(
    fruit_name => "brain",
    fruit_plural => "brains",
);
my $brain = $brain_pool->new_item("a brain");
is($brain->nutrition_each, 250);
is($brain->total_nutrition, 250);
ok($brain->is_custom_fruit, "brain is custom fruit");
is($brain->appearance, 'brain');
is($brain->identity, 'slime mold');

my $brains = $brain_pool->new_item("3 brains");
is($brains->nutrition_each, 250);
is($brains->total_nutrition, 750);
ok($brains->is_custom_fruit, "brains is custom fruit");
is($brains->appearance, 'brain');
is($brains->identity, 'slime mold');

my $child_pool = NetHack::ItemPool->new(
    fruit_name => "child",
    fruit_plural => "children",
);
my $child = $child_pool->new_item("a child");
is($child->nutrition_each, 250);
is($child->total_nutrition, 250);
ok($child->is_custom_fruit, "child is custom fruit");
is($child->appearance, 'child');
is($child->identity, 'slime mold');

my $children = $child_pool->new_item("3 children");
is($children->nutrition_each, 250);
is($children->total_nutrition, 750);
ok($children->is_custom_fruit, "children is custom fruit");
is($children->appearance, 'child');
is($children->identity, 'slime mold');

done_testing;
