#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;

use PDF::Builder;

my $pdf = PDF::Builder->new(-outver => 1.5);
$pdf = PDF::Builder->open('t/resources/sample-xrefstm.pdf');

isa_ok($pdf,
       'PDF::Builder',
       q{PDF::Builder->open() on a PDF with a cross-reference stream returns a PDF::Builder object});

my $object = $pdf->{'pdf'}->read_objnum(9, 0);

ok($object,
   q{Read an object from an object stream});

my ($key) = grep { $_ =~ /^Helv/ } keys %$object;
ok($key,
   q{The compressed object contains an expected key});

$object = $pdf->{'pdf'}->read_objnum(11, 0);

ok($object,
   q{Read a number from an object stream});

1;
