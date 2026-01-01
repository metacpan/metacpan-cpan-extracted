#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PDF::Builder;
use PDF::Builder::NamedDestination;

my $pdf = PDF::Builder->new();
my $page1 = $pdf->page();

my $dest = PDF::Builder::NamedDestination->new($pdf);
$dest->goto($page1, 'fit');
$pdf->named_destination('Dests', 'foo', $dest);

my $string = $pdf->to_string();
 
# test 1: /Names entry in root Catalog
like($string, qr{/Names << /Dests << /Limits \[ \(foo\) \(foo\) \] /Names \[ \(foo\) \d+ 0 R \] >> >>},
     q{Root named destination entries are recorded});
 
# test 2: Named Destination associated with foo (referenced by test 1)
like($string, qr{/D \[ \d+ 0 R /Fit \] /S /GoTo},
     q{Basic named destination is recorded in the PDF});

done_testing();

1;
