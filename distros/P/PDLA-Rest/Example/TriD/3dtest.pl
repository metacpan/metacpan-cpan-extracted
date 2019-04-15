#!/usr/bin/perl
#
# This program is a simple diagnostic example to
# check if TriD imagrgb is working
#
use PDLA;
use PDLA::NiceSlice;
use PDLA::Graphics::TriD;

# $PDLA::debug_trid=1;
# $PDLA::Graphics::TriD::verbose = 100;
$im = sequence(640,480)/640.0/480.0;
$im3 = $im->dummy(0,3);

# print "\$im3 has dims of @{[$im3->dims()]}\n";

imagrgb $im3;

