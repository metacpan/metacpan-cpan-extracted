#!/bin/env perl

use strict;
use warnings;

use lib qw<blib/lib>;

use Regexp::Wildcards;
use Data::Dumper;

my $rw = Regexp::Wildcards->new(
 do      => [ qw<brackets> ],
 capture => [ qw<single> ],
);
$rw->do(add => [ qw<jokers> ]);
$rw->capture(add => [ qw<brackets any greedy> ]);

print $_, ' => ', $rw->convert($_), "\n" for @ARGV;
