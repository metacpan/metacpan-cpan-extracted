# Perl
#
# How to implement correct add sub without Scalar::Validation
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

use Carp;

sub add {
     my $sum = 0;
     map {
	 croak "value is empty"
	     unless defined $_ and $_ ne '';
	 croak "value is not a Scalar: '$_'"
	     unless ref($_) eq '';
	 croak "value '$_' is not a Float"
	     unless /^[\+\-]?\d+(\.\d+)?([Ee][\+-]?\d+)?$/;
	 $sum += $_;
     } @_;
     return $sum;
}

my $ref = [];

print "sum of (1,2,3) = ".add(1,2,3)."\n";
print "sum of []      = ".add($ref)."\n";

print "Done"; # never will reach this code!!
