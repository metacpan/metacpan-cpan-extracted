#!perl

use strict;
use warnings;

use TAP::Harness;

my $harness = TAP::Harness->new({sources => {
    Feature => {},
}});
$harness->runtests(@ARGV);
