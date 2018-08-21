#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 1;

use PDF::Builder;

my $pdf = PDF::Builder->new('-compress' => 'none');
my $page1 = $pdf->page();
my $page2 = $pdf->page();

my $outlines = $pdf->outlines();
my $outline = $outlines->outline();
$outline->title('Test Outline');
$outline->dest($page2);

like($pdf->stringify, qr{/Dest \[ 6 0 R /XYZ null null null \] /Parent 7 0 R /Title \(Test Outline\)},
     q{Basic outline test});

1;
