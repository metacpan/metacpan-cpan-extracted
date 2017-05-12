#!/usr/bin/env perl

use lib qw(lib examples/lib);
use Rubyish;
use Rubyish::Autobox;

my $string = "string";
puts $string->methods;
puts $string->gsub(qr/string/, "hello");
puts $string;

my $array = [qw(hello world)];
puts Array()->methods;
puts $array->methods;
puts $array->size;
puts $array->at(0);
puts $array->inspect;

my $hash = {hello => "world"};
puts Hash->methods;
puts $hash->inspect;


