#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;

my $pdf = PDF::Builder->new();

# 1
like($pdf->producer(), qr/PDF::Builder/,
     q{Producer is set on PDF creation});

$pdf->producer('Test');

# 2
is($pdf->producer(), 'Test',
   q{Producer can be changed});

# 3
$pdf->producer(undef);

ok(!$pdf->producer(),
   q{Producer can be cleared});

# 4
$pdf->created('D:20000101000000Z');

like($pdf->to_string(),
     qr{/CreationDate \(D:20000101000000Z\)},
     q{CreationDate is correctly encoded});

# 5
$pdf = PDF::Builder->new();  # not sure why have to get a fresh PDF object...
                             # did some test upstream corrupt it?
$pdf->modified("D:20230402144932-04'00");

like($pdf->to_string(),
     qr{/ModDate \(D:20230402144932-04'00\)},
     q{ModDate is correctly encoded});

done_testing();
