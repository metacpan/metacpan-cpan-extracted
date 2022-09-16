#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;

my $pdf = PDF::Builder->new();

like($pdf->producer(), qr/PDF::Builder/,
     q{Producer is set on PDF creation});

$pdf->producer('Test');

is($pdf->producer(), 'Test',
   q{Producer can be changed});

$pdf->producer(undef);

ok(!$pdf->producer(),
   q{Producer can be cleared});

$pdf->created('D:20000101000000Z');

like($pdf->to_string(),
     qr{/CreationDate \(D:20000101000000Z\)},
     q{CreationDate is correctly encoded});

done_testing();
