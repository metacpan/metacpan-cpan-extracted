#!/usr/bin/perl
use FindBin;
use lib $FindBin::Bin.'/../3rd/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Test::More tests => 2;
use PDF::Builder;
use_ok 'PDF::QRCode';

my $pdf = PDF::Builder->new();
$pdf->mediabox('a4');
$pdf->{forcecompress} = 0;
my $gfx = $pdf->page->gfx;
$gfx->qrcode(x => 100, y => 100, 
    level => 'L', size => 40, text => 'Hello World');

like($pdf->stringify, qr/14 0 1 -1 re 15 0 1 -1 re 16 0 1 -1.+e 6 -6 1 -1 re 8 -6 1 -1 re 10 -6 1 -1 re 12 -6 1 -1 re 14 -6/, 'PDF');