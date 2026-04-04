#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# === Basic BUILD hook ===

package WithBuild;

use Object::Proto;

object('WithBuild', 'name:Str', 'initialized');

sub BUILD {
    my ($self) = @_;
    $self->initialized(1);
}

package main;

my $obj = new WithBuild name => 'test';
is($obj->initialized, 1, 'BUILD called on new()');
is($obj->name, 'test', 'constructor args still work with BUILD');

# === BUILD receives the constructed object ===

package Tracker;
BEGIN { Object::Proto::define('Tracker', 'log'); }

sub BUILD {
    my ($self) = @_;
    $self->log('built');
}

package main;

my $t = new Tracker;
is($t->log, 'built', 'BUILD receives the object and can set slots');

# === BUILD with positional constructor ===

package Positional;
BEGIN { Object::Proto::define('Positional', 'x', 'y', 'sum'); }

sub BUILD {
    my ($self) = @_;
    my $x = $self->x // 0;
    my $y = $self->y // 0;
    $self->sum($x + $y);
}

package main;

my $p = new Positional 3, 4;
is($p->x, 3, 'positional arg 1 set before BUILD');
is($p->y, 4, 'positional arg 2 set before BUILD');
is($p->sum, 7, 'BUILD computed derived value');

# === BUILD with named constructor ===

my $p2 = new Positional x => 10, y => 20;
is($p2->sum, 30, 'BUILD works with named constructor too');

# === Class without BUILD is unaffected ===

package NoBuild;
BEGIN { Object::Proto::define('NoBuild', 'val'); }

package main;

my $nb = new NoBuild val => 42;
is($nb->val, 42, 'class without BUILD works normally');

# === BUILD with defaults ===

package WithDefaults;
BEGIN { Object::Proto::define('WithDefaults', 'count:Int:default(0)', 'doubled'); }

sub BUILD {
    my ($self) = @_;
    $self->doubled($self->count * 2);
}

package main;

my $wd = new WithDefaults;
is($wd->count, 0, 'default applied before BUILD');
is($wd->doubled, 0, 'BUILD sees default value');

my $wd2 = new WithDefaults count => 5;
is($wd2->doubled, 10, 'BUILD sees provided value over default');

# === BUILD with extends ===

package Parent046;
BEGIN { Object::Proto::define('Parent046', 'base_val', 'parent_built'); }

sub BUILD {
    my ($self) = @_;
    $self->parent_built(1);
}

package Child046;
BEGIN { Object::Proto::define('Child046', extends => 'Parent046', 'child_val', 'child_built'); }

sub BUILD {
    my ($self) = @_;
    $self->child_built(1);
}

package main;

my $child = new Child046 base_val => 'a', child_val => 'b';
is($child->child_built, 1, 'child BUILD called');
is($child->base_val, 'a', 'inherited slot set');
is($child->child_val, 'b', 'own slot set');

# Note: child's BUILD overrides parent's BUILD (standard Perl inheritance behavior)
# Parent BUILD is NOT automatically called - the child must call it explicitly if desired.

# === BUILD called per instance ===

my $call_count = 0;

package Counted;
BEGIN { Object::Proto::define('Counted', 'id'); }

sub BUILD {
    my ($self) = @_;
    $call_count++;
    $self->id($call_count);
}

package main;

my $c1 = new Counted;
my $c2 = new Counted;
my $c3 = new Counted;
is($c1->id, 1, 'BUILD called for first instance');
is($c2->id, 2, 'BUILD called for second instance');
is($c3->id, 3, 'BUILD called for third instance');
is($call_count, 3, 'BUILD called exactly once per new()');

done_testing;
