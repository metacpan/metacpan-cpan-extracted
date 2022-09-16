#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;

use PDF::Builder;

my $pdf = PDF::Builder->new();
$pdf->preferences(-simplex => 1);
like($pdf->to_string(), qr{/ViewerPreferences << [^>]*?/Duplex /Simplex}, q{Duplex => Simplex});

$pdf = PDF::Builder->new();
$pdf->preferences(-duplexfliplongedge => 1);
like($pdf->to_string(), qr{/ViewerPreferences << [^>]*?/Duplex /DuplexFlipLongEdge}, q{Duplex => DuplexFlipLongEdge});

$pdf = PDF::Builder->new();
$pdf->preferences(-duplexflipshortedge => 1);
like($pdf->to_string(), qr{/ViewerPreferences << [^>]*?/Duplex /DuplexFlipShortEdge}, q{Duplex => DuplexFlipShortEdge});

1;
