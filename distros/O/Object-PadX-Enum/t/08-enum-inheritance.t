#!perl
use v5.22;
use warnings;

use Test2::V0;

use Object::PadX::Enum;

# Parent enum with fields/methods.
enum Parent {
   item P_ONE;
   item P_TWO;

   field $x :param :reader = 0;

   method describe { return "parent x=$x" }
}

# Child enum inherits fields/methods, defines its own items.
enum Child :isa(Parent) {
   item C_ONE( x => 1 );
   item C_TWO( x => 2 );
}

# Child has its own item sequence with ordinals starting at 0.
{
   my @cs = Child->values;
   is( scalar @cs, 2, 'Child->values returns only child items' );
   is( $cs[0]->name,    'C_ONE', 'first child item is C_ONE' );
   is( $cs[0]->ordinal, 0,       'C_ONE ordinal is 0' );
   is( $cs[1]->name,    'C_TWO', 'second child item is C_TWO' );
   is( $cs[1]->ordinal, 1,       'C_TWO ordinal is 1' );
}

# Inherited field and method work on child instances.
is( Child->C_ONE->x,        1,           'child instance has inherited field' );
is( Child->C_ONE->describe, 'parent x=1', 'child instance can call inherited method' );

# Parent items are shadowed on the child.
{
   my $ok = eval { Child->P_ONE; 1 };
   ok( !$ok, 'Child->P_ONE croaks' );
   like( $@, qr/not an item of 'Child'/, 'shadow error names the child class' );
   like( $@, qr/inherited from 'Parent'/, 'shadow error names the ancestor' );
}

# Parent items still resolve on the parent itself.
is( Parent->P_ONE->name, 'P_ONE', 'Parent->P_ONE still works' );
is( Parent->P_ONE->ordinal, 0,    'Parent->P_ONE has ordinal 0' );

# Child->new is blocked; Parent->new is blocked.
{
   my $ok = eval { Child->new; 1 };
   ok( !$ok, 'Child->new croaks' );
   like( $@, qr/enum class 'Child'/, 'Child->new error names Child' );
}
{
   my $ok = eval { Parent->new; 1 };
   ok( !$ok, 'Parent->new croaks' );
   like( $@, qr/enum class 'Parent'/, 'Parent->new error names Parent' );
}

# Child->from_name and from_ordinal see only child items.
is( Child->from_name('C_ONE')->ordinal, 0, 'Child->from_name(child item) works' );
is( Child->from_name('P_ONE'), undef,      'Child->from_name(parent item) returns undef' );
is( Child->from_ordinal(0)->name, 'C_ONE', 'Child->from_ordinal(0) is child item' );

# Multi-level inheritance: Grand :isa(Child).
enum Grand :isa(Child) {
   item G_ONE( x => 9 );
}

is( Grand->G_ONE->x, 9, 'grand item has inherited field' );
is( Grand->G_ONE->describe, 'parent x=9', 'grand item can call inherited method' );

{
   my $ok = eval { Grand->P_ONE; 1 };
   ok( !$ok, 'Grand->P_ONE croaks (transitive shadow)' );
   like( $@, qr/inherited from 'Parent'/, 'Grand shadow names Parent ancestor' );
}
{
   my $ok = eval { Grand->C_ONE; 1 };
   ok( !$ok, 'Grand->C_ONE croaks (immediate-parent shadow)' );
   like( $@, qr/inherited from 'Child'/, 'Grand shadow names Child ancestor' );
}

# Name collision: child item with same name as parent item wins.
enum Child2 :isa(Parent) {
   item P_ONE( x => 42 );
}

is( Child2->P_ONE->x,       42, 'child item with parent-shared name overrides' );
is( Child2->P_ONE->ordinal, 0,  'overriding child item has child ordinal 0' );
is( Parent->P_ONE->x,       0,  'parent P_ONE unaffected by Child2 override' );

done_testing;
