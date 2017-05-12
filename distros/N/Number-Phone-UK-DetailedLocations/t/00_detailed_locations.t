#!/usr/bin/perl

use strict;
use warnings;
use Number::Phone;

use Test::More tests => 1;

my $number = Number::Phone->new('+442087712924');
is_deeply($number->location(), [51.410357, -0.08641], "Yarr, it all works");
