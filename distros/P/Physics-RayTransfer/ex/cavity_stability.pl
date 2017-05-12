#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Physics::RayTransfer;

use PDL;
use PDL::Graphics::Gnuplot qw/plot/;

my $sys = Physics::RayTransfer->new();
$sys->add_mirror;
$sys->add_space->parameter(sub{shift}); #$d
$sys->add_mirror(8);

my $d = [ map { $_ / 10 } (0..100) ];

my @data = 
  map { $_->[1]->w(1063e-7) }
  $sys->evaluate_parameterized($d);

plot pdl($d), pdl(\@data);

