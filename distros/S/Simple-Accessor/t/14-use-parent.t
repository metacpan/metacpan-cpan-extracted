use strict;
use warnings;

use Test::More tests => 28;
use FindBin;
use lib "$FindBin::Bin/lib";

# ===================================================================
# Test that Simple::Accessor works correctly when @ISA is set at
# compile time via use parent, use base, or BEGIN blocks.
#
# Previously, _add_with() and _add_new() used $class->can() to check
# for existing functions, which walks @ISA.  When @ISA is set before
# import() runs, can() finds the parent's functions and skips
# installation for the child.  Since with() is called as a bare
# function (not a method), the child gets "Undefined subroutine".
# ===================================================================

# --- Basic: compile-time @ISA via BEGIN block ---
{
    package CT::Parent;
    use Simple::Accessor qw{name};
    sub _build_name { 'parent' }

    package CT::Child;
    BEGIN { our @ISA = ('CT::Parent'); }
    use Simple::Accessor qw{age};

    package main;

    my $obj = CT::Child->new(name => 'alice', age => 30);
    ok $obj, 'compile-time @ISA: object created';
    is( $obj->name, 'alice', 'parent attr set via constructor' );
    is( $obj->age,  30,      'child attr set via constructor' );

    my $obj2 = CT::Child->new(age => 5);
    is( $obj2->name, 'parent', 'parent builder fires for child' );
}

# --- use parent -norequire ---
{
    package UP::Vehicle;
    use Simple::Accessor qw{speed};
    sub _build_speed { 0 }

    package UP::Car;
    use parent -norequire, 'UP::Vehicle';
    use Simple::Accessor qw{brand};

    package main;

    my $car = UP::Car->new(brand => 'Tesla', speed => 100);
    ok $car, 'use parent: object created';
    is( $car->brand, 'Tesla', 'child attr works' );
    is( $car->speed, 100,     'parent attr set via constructor' );

    my $slow = UP::Car->new(brand => 'bike');
    is( $slow->speed, 0, 'parent builder fires' );
}

# --- with() works after use parent ---
{
    package UP::Role::Color;
    use Simple::Accessor qw{color};
    sub _build_color { 'red' }
    $INC{"UP/Role/Color.pm"} = 1;

    package UP::Base;
    use Simple::Accessor qw{id};

    package UP::Widget;
    use parent -norequire, 'UP::Base';
    use Simple::Accessor qw{label};
    with 'UP::Role::Color';

    package main;

    my $w = UP::Widget->new(id => 1, label => 'btn', color => 'blue');
    ok $w, 'use parent + with(): object created';
    is( $w->id,    1,      'inherited attr' );
    is( $w->label, 'btn',  'own attr' );
    is( $w->color, 'blue', 'role attr' );

    my $w2 = UP::Widget->new(id => 2, label => 'x');
    is( $w2->color, 'red', 'role builder fires' );
}

# --- Role composed in child does NOT leak to parent ---
{
    package Leak::Role;
    use Simple::Accessor qw{leak_attr};
    $INC{"Leak/Role.pm"} = 1;

    package Leak::Parent;
    use Simple::Accessor qw{base_val};

    package Leak::Child;
    use parent -norequire, 'Leak::Parent';
    use Simple::Accessor;
    with 'Leak::Role';

    package main;

    ok !Leak::Parent->can('leak_attr'),
        'role composed in child does not leak to parent';

    my $child = Leak::Child->new(base_val => 'ok', leak_attr => 'mine');
    is( $child->base_val,  'ok',   'child accesses parent attr' );
    is( $child->leak_attr, 'mine', 'child has role attr' );

    my $parent = Leak::Parent->new(base_val => 'p');
    ok !$parent->can('leak_attr'), 'parent object has no role attr';
}

# --- Strict constructor with use parent ---
{
    package Strict::Parent;
    use Simple::Accessor qw{x};

    package Strict::Child;
    use parent -norequire, 'Strict::Parent';
    use Simple::Accessor qw{y};
    sub _strict_constructor { 1 }

    package main;

    my $obj = Strict::Child->new(x => 1, y => 2);
    ok $obj, 'strict constructor + use parent: valid args accepted';

    eval { Strict::Child->new(x => 1, y => 2, typo => 3) };
    like( $@, qr/unknown attribute/,
        'strict constructor catches typos with inherited attrs' );

    eval { Strict::Child->new(x => 1) };
    ok !$@, 'parent attrs not flagged as unknown';
}

# --- Multi-level with use parent ---
{
    package ML::A;
    use Simple::Accessor qw{a_val};

    package ML::B;
    use parent -norequire, 'ML::A';
    use Simple::Accessor qw{b_val};

    package ML::C;
    use parent -norequire, 'ML::B';
    use Simple::Accessor qw{c_val};

    package main;

    my $obj = ML::C->new(a_val => 1, b_val => 2, c_val => 3);
    ok $obj, 'three-level use parent: object created';
    is( $obj->a_val, 1, 'grandparent attr' );
    is( $obj->b_val, 2, 'parent attr' );
    is( $obj->c_val, 3, 'own attr' );
}

# --- Hooks resolve correctly through use parent inheritance ---
{
    package Hook::Role;
    use Simple::Accessor qw{val};
    sub _validate_val {
        my ($self, $v) = @_;
        return $v > 0 ? 1 : 0;
    }
    $INC{"Hook/Role.pm"} = 1;

    package Hook::Parent;
    use Simple::Accessor qw{name};
    with 'Hook::Role';

    package Hook::Child;
    use parent -norequire, 'Hook::Parent';
    use Simple::Accessor qw{extra};

    package main;

    my $obj = Hook::Child->new(name => 'test', val => 5, extra => 'x');
    ok $obj, 'hooks through use parent: object created';
    is( $obj->val, 5, 'role attr set via child constructor' );

    $obj->val(-1);  # should be rejected by validator
    is( $obj->val, 5, 'role validator fires through use parent inheritance' );

    $obj->val(10);
    is( $obj->val, 10, 'role validator accepts valid value' );
}
