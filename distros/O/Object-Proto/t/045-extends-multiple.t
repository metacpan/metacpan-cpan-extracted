#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Multiple inheritance ===

Object::Proto::define('Movable',
    'x:Num:default(0)',
    'y:Num:default(0)',
);

package Movable;
sub move {
    my ($self, $dx, $dy) = @_;
    $self->x($self->x + $dx);
    $self->y($self->y + $dy);
}
package main;

Object::Proto::define('Drawable',
    'color:Str:default(black)',
    'visible:Int:default(1)',
);

package Drawable;
sub draw { my $self = shift; return "Drawing " . $self->color }
package main;

# Multiple inheritance via arrayref
Object::Proto::define('Sprite',
    extends => ['Movable', 'Drawable'],
    'name:Str:required',
    'scale:Num:default(1.0)',
);

# Sprite should have all properties
my @props = sort(Object::Proto::properties('Sprite'));
is_deeply(\@props, [qw(color name scale visible x y)], 'Sprite has all properties from both parents + own');

# Create instance
my $s = new Sprite name => 'hero', x => 10, y => 20, color => 'red';
is($s->name, 'hero', 'own property');
is($s->x, 10, 'first parent property');
is($s->y, 20, 'first parent property');
is($s->color, 'red', 'second parent property');
is($s->visible, 1, 'second parent default');
ok($s->scale == 1.0, 'own default');

# Inherited methods from both parents
$s->move(5, 3);
is($s->x, 15, 'method from first parent works');
is($s->y, 23, 'method from first parent works');
is($s->draw, 'Drawing red', 'method from second parent works');

# isa works for all parents
ok($s->isa('Sprite'), 'isa Sprite');
ok($s->isa('Movable'), 'isa Movable');
ok($s->isa('Drawable'), 'isa Drawable');

# can works for methods from both parents
ok($s->can('move'), 'can(move) from Movable');
ok($s->can('draw'), 'can(draw) from Drawable');

# === parent() in list context ===
my @parents = Object::Proto::parent('Sprite');
is_deeply(\@parents, ['Movable', 'Drawable'], 'parent() list context returns both');

# === parent() in scalar context ===
my $first_parent = Object::Proto::parent('Sprite');
is($first_parent, 'Movable', 'parent() scalar context returns first');

# === ancestors() with multiple inheritance ===
my @ancestors = Object::Proto::ancestors('Sprite');
is_deeply(\@ancestors, ['Movable', 'Drawable'], 'ancestors includes both parents');

# === Diamond-safe: shared property from multiple parents ===
Object::Proto::define('HasName',
    'name:Str',
);

Object::Proto::define('HasAge',
    'name:Str',  # same property as HasName
    'age:Int:default(0)',
);

Object::Proto::define('Person',
    extends => ['HasName', 'HasAge'],
    'email:Str',
);

# 'name' should only appear once (first parent wins)
my @person_props = sort(Object::Proto::properties('Person'));
is_deeply(\@person_props, [qw(age email name)], 'duplicate property from parents only included once');

my $p = new Person name => 'Alice', age => 30, email => 'alice@example.com';
is($p->name, 'Alice', 'shared property works');
is($p->age, 30, 'second parent unique property works');
is($p->email, 'alice@example.com', 'own property works');

# === Extends undefined class ===
eval {
    Object::Proto::define('Bad',
        extends => ['Movable', 'NonExistent'],
        'x:Int',
    );
};
like($@, qr/has not been defined/, 'croak on undefined parent in multi-inherit');

done_testing;
