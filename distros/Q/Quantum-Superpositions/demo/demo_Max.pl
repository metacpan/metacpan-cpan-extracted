#!/usr/local/bin/perl -sw

use Quantum::Superpositions;

my @nums = (1..10);

print "min: ", (any(@nums) <= all(@nums)), "\n";
print "max: ", any(@nums) >= all(@nums), "\n";

print "New max: ", eigenstates (any(@nums) >= all @nums), "\n";
print "New min: ", (any(@nums) <= all @nums), "\n";
