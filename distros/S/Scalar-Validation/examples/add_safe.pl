# Perl
#
# How to implement correct add sub with Scalar::Validation
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

use Scalar::Validation qw(par);

sub add {
    my $sum = 0;
    map { $sum += par add => Float => $_; } @_;
    return $sum;
}

my $ref = [];

print "sum of (1,2,3) = ".add(1,2,3)."\n";
print "sum of []      = ".add($ref)."\n";

print "Done"; # never will reach this code!!
