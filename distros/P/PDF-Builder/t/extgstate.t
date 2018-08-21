#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

use PDF::Builder;

# Dash

my $pdf = PDF::Builder->new('-compress' => 'none');
my $egs = $pdf->egstate();
$egs->dash(2, 1);
like($pdf->stringify, qr{<< /Type /ExtGState /D \[ \[ 2 1 \] 0 \] /Name /[\w]+ >>}, 'dash');

# Rendering Intent

$pdf = PDF::Builder->new('-compress' => 'none');
$egs = $pdf->egstate();
$egs->renderingintent('Perceptual');
like($pdf->stringify, qr{<< /Type /ExtGState /Name /[\w]+ /RI /Perceptual >>}, 'renderingintent');

1;
