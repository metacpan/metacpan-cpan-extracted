#!/usr/bin/env perl

use lib qw(lib examples/lib);
use Rubyish;

my $array = Rubyish::Array->new([1, 2, 3, 4, 5]);
puts $array;

my $new_array = Array([1, 2, 3, 4, 5, {hello => "world"}]);
puts $new_array;
puts $new_array->object_id;

puts $new_array->methods;

puts $new_array->superclass;
puts $new_array->size;

puts $new_array->each( sub {$_+1} );
puts $new_array->map( sub {$_+1} );

puts $new_array->at(0);
puts $new_array->at(5);


