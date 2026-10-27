use strict;
use warnings;

use Test::More tests => 12;
use FindBin;
use lib "$FindBin::Bin/lib";

# =============================================================
# Test: $obj->new() should work like ClassName->new()
# =============================================================
# Calling new() as an instance method is a common Perl pattern
# (e.g. "poor man's clone": $obj->new(%{$obj})).
# Without ref($class) || $class, bless dies with
# "Attempt to bless into a reference".
# =============================================================

{
    package InstanceTest;
    use Simple::Accessor qw{name age};
    sub _build_name { 'default' }
    sub _build_age  { 0 }
}

# --- basic instance-method new ---

my $orig = InstanceTest->new(name => 'Alice', age => 30);
isa_ok($orig, 'InstanceTest', 'original object');
is($orig->name, 'Alice', 'original name');

my $copy = $orig->new(name => 'Bob', age => 25);
isa_ok($copy, 'InstanceTest', 'instance->new() produces correct class');
is($copy->name, 'Bob', 'instance->new() sets attributes');
is($copy->age, 25, 'instance->new() sets all attributes');

# original is not mutated
is($orig->name, 'Alice', 'original unchanged after instance->new()');
is($orig->age, 30, 'original age unchanged');

# --- instance->new() with no args uses builders ---

my $empty = $orig->new();
isa_ok($empty, 'InstanceTest', 'instance->new() with no args');
is($empty->name, 'default', 'instance->new() triggers builder');
is($empty->age, 0, 'instance->new() triggers builder for age');

# --- "poor man's clone" pattern ---

my $clone = $orig->new(%{$orig});
isa_ok($clone, 'InstanceTest', 'poor man clone is correct class');
is($clone->name, 'Alice', 'clone has same attribute values');
