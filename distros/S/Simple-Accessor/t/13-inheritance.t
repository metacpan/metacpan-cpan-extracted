use strict;
use warnings;

use Test::More tests => 28;
use FindBin;
use lib "$FindBin::Bin/lib";

# ===================================================================
# Test inheritance via @ISA: parent class attributes should be
# recognized by the child class constructor.
# ===================================================================

# --- Basic single inheritance ---
{
    package Animal;
    use Simple::Accessor qw{name sound};
    sub _build_sound { 'unknown' }

    package Dog;
    our @ISA = ('Animal');
    use Simple::Accessor qw{breed};

    package main;

    my $dog = Dog->new(name => 'Rex', breed => 'Labrador', sound => 'woof');
    ok $dog, 'single inheritance: object created';
    is( $dog->name,  'Rex',       'parent attr set via constructor' );
    is( $dog->breed, 'Labrador',  'child attr set via constructor' );
    is( $dog->sound, 'woof',      'parent attr with builder overridden by constructor' );

    my $dog2 = Dog->new(breed => 'Poodle');
    is( $dog2->sound, 'unknown', 'parent builder fires when no constructor arg' );
    is( $dog2->name,  undef,     'parent attr without builder returns undef' );
}

# --- Multi-level inheritance (grandparent) ---
{
    package Base;
    use Simple::Accessor qw{id};

    package Middle;
    our @ISA = ('Base');
    use Simple::Accessor qw{level};

    package Leaf;
    our @ISA = ('Middle');
    use Simple::Accessor qw{label};

    package main;

    my $obj = Leaf->new(id => 1, level => 2, label => 'leaf-node');
    ok $obj, 'multi-level inheritance: object created';
    is( $obj->id,    1,           'grandparent attr set via constructor' );
    is( $obj->level, 2,           'parent attr set via constructor' );
    is( $obj->label, 'leaf-node', 'child attr set via constructor' );
}

# --- Inheritance + roles: both work together ---
{
    package Role::Colored;
    use Simple::Accessor qw{color};
    sub _build_color { 'white' }
    $INC{"Role/Colored.pm"} = 1;

    package Shape;
    use Simple::Accessor qw{sides};

    package Circle;
    our @ISA = ('Shape');
    use Simple::Accessor qw{radius};
    with 'Role::Colored';

    package main;

    my $c = Circle->new(sides => 0, radius => 5, color => 'blue');
    ok $c, 'inheritance + role: object created';
    is( $c->sides,  0,      'inherited attr from parent via @ISA' );
    is( $c->radius, 5,      'own attr' );
    is( $c->color,  'blue', 'role attr set via constructor' );

    my $c2 = Circle->new(radius => 3);
    is( $c2->color, 'white', 'role builder fires as lazy default' );
}

# --- Attribute name collision: child attr wins (already defined) ---
{
    package ParentDup;
    use Simple::Accessor qw{name};

    package ChildDup;
    our @ISA = ('ParentDup');
    # "name" is inherited via @ISA — child doesn't redeclare it
    use Simple::Accessor qw{extra};

    package main;

    my $obj = ChildDup->new(name => 'inherited', extra => 'mine');
    ok $obj, 'no collision when child does not redeclare parent attr';
    is( $obj->name,  'inherited', 'parent attr accessible through inheritance' );
    is( $obj->extra, 'mine',      'child attr set normally' );
}

# --- Strict constructor with inheritance ---
{
    package StrictParent;
    use Simple::Accessor qw{a};

    package StrictChild;
    our @ISA = ('StrictParent');
    use Simple::Accessor qw{b};

    sub _strict_constructor { 1 }

    package main;

    my $obj = StrictChild->new(a => 1, b => 2);
    ok $obj, 'strict constructor with inherited attrs: valid args accepted';
    is( $obj->a, 1, 'inherited attr set' );
    is( $obj->b, 2, 'own attr set' );

    eval { StrictChild->new(a => 1, b => 2, typo => 3) };
    like( $@, qr/unknown attribute/, 'strict constructor catches unknown attrs' );

    # parent attrs should NOT be flagged as unknown
    eval { StrictChild->new(a => 1) };
    ok !$@, 'strict constructor does not reject parent attrs';
}

# --- Parent hooks fire for inherited attrs set via child constructor ---
{
    package HookParent;
    use Simple::Accessor qw{guarded};

    my @hook_log;
    sub _before_guarded {
        my ($self, $v) = @_;
        push @hook_log, "before:$v";
        return 1;
    }
    sub hook_log { [@hook_log] }

    package HookChild;
    our @ISA = ('HookParent');
    use Simple::Accessor qw{other};

    package main;

    @hook_log = ();  # reset
    my $obj = HookChild->new(guarded => 'hello', other => 42);
    ok $obj, 'parent hooks fire via inherited constructor';
    is( $obj->guarded, 'hello', 'inherited guarded attr set' );
    is_deeply( HookParent->hook_log(), ['before:hello'],
        'parent _before_* hook fired during child constructor' );
}

# --- Empty parent (no SA attrs) doesn't break ---
{
    package EmptyParent;
    use Simple::Accessor;  # no attributes

    package ChildOfEmpty;
    our @ISA = ('EmptyParent');
    use Simple::Accessor qw{val};

    package main;

    my $obj = ChildOfEmpty->new(val => 'ok');
    ok $obj, 'child of empty SA parent: object created';
    is( $obj->val, 'ok', 'child attr works normally' );
}
