#!/usr/bin/env perl

use strict;
use warnings;

use Set::Array;

# -------------

my($set1) = Set::Array->new(qw(abc def ghi jkl mno));
my($set2) = Set::Array->new(qw(def jkl pqr));
my($set3) = $set1 - $set2;
my($set4) = Set::Array -> new(@{$set1 - $set2});

print '1: ', join(', ', @$set3), ". \n";
print '2: ', join(', ', @{$set4 -> print}), ". \n";
print '3: ', join(', ', $set4 -> print), ". \n";
