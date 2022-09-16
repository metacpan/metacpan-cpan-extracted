#!/usr/bin/perl
use warnings;
use strict;

use Test::More (tests => 1);

use PDF::Builder;

my $pdf = PDF::Builder->open('t/resources/sample.pdf');

ok($pdf->to_string(),
   q{open() followed by saveas() doesn't crash});

1;
