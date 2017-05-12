#!/usr/bin/env perl

use lib qw(lib examples/lib);
use Cat;
use Rubyish;

my $oreo = Cat->new->name("Oreo");

puts $oreo->methods;

print $oreo->sound . "\n";

$oreo->play(qw(CHEESE BURGER));

print '$oreo is a ' . ref($oreo) . "\n";

print "Oreo to YAML:\n" . $oreo->to_yaml;

puts $oreo->inspect;

puts $oreo->ancestors;
