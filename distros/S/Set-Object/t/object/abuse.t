#!/usr/bin/perl -w

use strict;
use Test::More tests => 20;
use Set::Object;

my @objects = ( bless([], "Bob"),
		bless([], "Jane"),
		bless([], "Bernie"));

my $set = Set::Object->new(@objects);

# This test is because I once found as_string getting called
# completely out of context, so I added an explicit check
eval { Set::Object::as_string("yo momma") };
like($@, qr/Tried to use as_string/, "as_string");

is(($set == "doorpost"), undef, "== operator");
is($set->equal(["pocketknife"]), undef, "equal method");

is(($set != "doorpost"),     1, "!= operator");
is($set->not_equal(["pocketknife"]), 1, "not_equal method");

ok(( $set->union([ "carborettor" ]) == $set), "union method");

# no longer abuse...
#eval{ my $x = $set + "carborettor" };
#like($@, qr/Tried to form union.*carborettor/, "+ operator");

eval { my $x = $set * [ "octarine" ] };
like($@, qr/Tried to .*intersection.*ARRAY/, "* operator");
eval { my $x = $set->intersection([ "octarine" ]) };
like($@, qr/Tried to .*intersection.*ARRAY/, "intersection method");

eval { my $x = $set - { "deep" => "purple" } };
like($@, qr/Tried to .*difference.*HASH/, "- operator");
eval { my $x = $set->difference({ "uriah" => "heep" }) };
like($@, qr/Tried to .*difference.*HASH/, "difference");

eval { my $x = $set % $objects[0] };
like($@, qr/Tried to .*symmetric.*Bob/, "% operator");
eval { my $x = $set->symmetric_difference($objects[1]) };
like($@, qr/Tried to .*symmetric.*Jane/, "symmetric_difference");

eval { my $x = $set < $objects[0] };
like($@, qr/Tried to .*proper subset.*Bob/, "< operator");
eval { my $x = $set->proper_subset($objects[1]) };
like($@, qr/Tried to .*proper subset.*Jane/, "proper_subset");

eval { my $x = $set <= $objects[0] };
like($@, qr/Tried to find subset.*Bob/, "<= operator");
eval { my $x = $set->subset($objects[1]) };
like($@, qr/Tried to find subset.*Jane/, "subset");

eval { my $x = $set > $objects[0] };
like($@, qr/Tried to .*proper superset.*Bob/, "> operator");
eval { my $x = $set->proper_superset($objects[1]) };
like($@, qr/Tried to .*proper superset.*Jane/, "proper_superset");

eval { my $x = $set >= $objects[0] };
like($@, qr/Tried to find superset.*Bob/, ">= operator");
eval { my $x = $set->superset($objects[1]) };
like($@, qr/Tried to find superset.*Jane/, "superset");

