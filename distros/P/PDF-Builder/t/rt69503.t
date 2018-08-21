#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

use PDF::Builder;

# -firstpage as page number (original bug report)

my $pdf = PDF::Builder->new();
my $page1 = $pdf->page();
my $page2 = $pdf->page();

$pdf->preferences(-firstpage => [2, -fit => 1]);

my $output = $pdf->stringify();

like($output,
     qr/OpenAction \[ 2 \/Fit \]/,
     q{-firstpage accepts a page number});

# -firstpage as page object (regression)

$pdf = PDF::Builder->new();
$page1 = $pdf->page();
$page2 = $pdf->page();

$pdf->preferences(-firstpage => [$page2, -fit => 1]);

$output = $pdf->stringify();

like($output,
     qr/OpenAction \[ \d+ 0 R \/Fit \]/,
     q{-firstpage accepts a page object});

1;
