#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# Define a class
Object::Proto::define('Cat', "name:default(Barry)", "age:default(100)");

# Test named constructor where key does not exist
my $cat1 = new Cat thing => 3;

is($cat1->name, 'Barry');
is($cat1->age, 100);

# An inherited slot keeps its readonly, required and coerce checks when its
# accessor is called as a function, which compiles to the inlined setter
BEGIN {
    Object::Proto::define('RoParent', 'id:Int:readonly', 'n:Num:coerce(RoParent::to_num)');
    Object::Proto::define('RoChild', extends => 'RoParent');
}
package RoParent;
sub to_num { $_[0] eq 'one' ? 1 : $_[0] }
package RoChild;
sub set_id { id($_[0], 99) }
sub set_n  { n($_[0], $_[1]) }
package main;
my $child = RoChild->new(id => 1, n => 2);
eval { $child->set_id };
like($@, qr/Cannot modify readonly slot 'id'/, 'an inherited readonly slot refuses the function-call setter');
is($child->id, 1, 'and keeps its value');
is($child->set_n('one'), 1, 'an inherited coerce runs on the function-call setter');
is($child->n, 1, 'and stores the coerced value');

done_testing;
