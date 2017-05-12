#!/usr/bin/env perl

use lib qw(lib examples/lib);
use Rubyish;

$string = String("hello");

puts $string->methods;

$string->replace("world");

puts $string;


