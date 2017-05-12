# Perl
#
# sub without checks, very dangerous!!
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

sub add {
    my $sum = 0;
    map { $sum += $_; } @_;
    return $sum;
}

my $ref = [];

print "sum of (1,2,3) = ".add(1,2,3)."\n";
print "sum of []      = ".add($ref)."\n";

print "Done";
