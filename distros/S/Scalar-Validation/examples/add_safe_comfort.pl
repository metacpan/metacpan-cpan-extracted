# Perl
#
# How to implement correct add sub with Scalar::Validation
# showing validation modes
#
# Ralf Peine, Sat Jul 12 12:49:47 2014

$| = 1;

use strict;
use warnings;

use Carp;
local $Carp::Verbose = 1;

use Scalar::Validation qw(:all);

sub add {
    local ($Scalar::Validation::trouble_level) = 0;

    my $sum = 0;
    map { $sum += par add => Float => $_; } @_;

    return undef if validation_trouble(); # fire exit, if validation does not die

    return $sum;
}

local ($Scalar::Validation::fail_action, $Scalar::Validation::off) = prepare_validation_mode(shift || 'die');

my $ref = [];

print "sum of (1,2,3) = ".add(1,2,3)."\n";
print "sum of []      = ".add($ref)."\n";

print "Done"; # will be reached if validation mode != 'die'
