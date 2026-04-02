use strict;
use warnings;
use Test::More tests => 6;

# Test the 'object' keyword exported by 'use Object::Proto'

package TestKeyword;

use Object::Proto;

BEGIN {
    object('Gadget', qw(brand model));
}

package main;

# Verify the class was defined via the object() keyword
my $g = new Gadget 'Sony', 'WH-1000';
isa_ok($g, 'Gadget', 'object() keyword defines class');
is($g->brand, 'Sony', 'object() defined class: getter works');
is($g->model, 'WH-1000', 'object() defined class: second getter works');

# Setter
$g->brand('Bose');
is($g->brand, 'Bose', 'object() defined class: setter works');

# Named constructor
my $g2 = new Gadget brand => 'Apple', model => 'AirPods';
is($g2->brand, 'Apple', 'object() defined class: named constructor');
is($g2->model, 'AirPods', 'object() defined class: named constructor second prop');
