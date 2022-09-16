#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;
use PDF::Builder::NamedDestination;

my $pdf = PDF::Builder->new();
my $page1 = $pdf->page();

my $dest = PDF::Builder::NamedDestination->new($pdf, $page1, 'fit');

my $string = $pdf->to_string();
like($string, qr{/D \[ \d+ 0 R /Fit \]},
     q{Basic named destination is recorded in the PDF});

done_testing();

1;
