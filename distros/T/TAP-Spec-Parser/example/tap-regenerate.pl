#!/usr/bin/perl
#
use strict;
use warnings;

use TAP::Spec::Parser;
use Data::Dumper;

my $testset = TAP::Spec::Parser->parse_from_handle(\*ARGV);
print $testset->as_tap;
