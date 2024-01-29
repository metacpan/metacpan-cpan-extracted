#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use PDF::Builder;

my $pdf = PDF::Builder->open('t/resources/sample-xrefstm-index.pdf', 'outver'=>1.5);

isa_ok($pdf,
       'PDF::Builder',
       q{PDF::Builder->open() on a PDF with a cross-reference stream using an Index returns a PDF::Builder object});

my $object = $pdf->{'pdf'}->read_objnum(9, 0);

ok($object,
   q{Read the high object from an indexed object stream});

$object = $pdf->{'pdf'}->read_objnum(12, 0);

ok($object,
   q{Read the low object from an indexed object stream});

1;
