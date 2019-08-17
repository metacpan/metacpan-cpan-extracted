#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;

my $pdf = PDF::Builder->new();

# this first test is the opposite of PDF::API2's, where there is
# no default Media Box
ok($pdf->mediabox(),
    q{Global media box exists on a new PDF});

$pdf->mediabox('letter');

is(join(',', $pdf->mediabox()),
   '0,0,612,792',
   q{Global media box can be read after being set});

my $string = $pdf->stringify();

like($string, qr{/MediaBox \[ 0 0 612 792 \]},
    q{Global media box is recorded in the PDF});

done_testing();

1;
