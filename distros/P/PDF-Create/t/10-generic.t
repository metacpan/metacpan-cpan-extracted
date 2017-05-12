#!/usr/bin/perl
#
# PDF::Create - Test Script
#
# Copyright 2010-     Markus Baertschi <markus@markus.org>
#
# Please see the CHANGES and Changes file for the detailed change log
#
# Generic Testing
#

use strict; use warnings;
use PDF::Create;
use Test::More;

my $pdfname = $0;
$pdfname =~ s/\.t/\.pdf/;

my $pdf = PDF::Create->new(
    'filename' => "$pdfname",
    'Version'  => 1.2,
    'PageMode' => 'UseOutlines',
    'Author'   => 'Markus Baertschi',
    'Title'    => 'Testing Basic Stuff',
);

ok(defined $pdf, "Create new PDF");

ok(defined $pdf->new_page('MediaBox' => $pdf->get_page_size('A4')), "Create page root");

eval { $pdf->new_page('Xxxx' => $pdf->get_page_size('A4')) };
like($@, qr/Received invalid key/);

ok (defined $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => 'Helvetica'
    ), "Define Font" );

eval {
    $pdf->font(
        'SubType'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => 'Helvetica');
};
like($@, qr/Received invalid key/);

eval {
    $pdf->font(
        'Subtype'  => 'Type6',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => 'Helvetica');
};
like($@, qr/Received invalid value/);

eval {
    $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding123',
        'BaseFont' => 'Helvetica');
};
like($@, qr/Received invalid value/);

eval {
    $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => 'Helvetica123');
};
like($@, qr/Received invalid value/);

eval { $pdf->get_page_size('AA') };
like($@, qr/Invalid page size name 'AA' received/);

foreach (qw/A0 A1 A2 A3 A4 A4L A5 A6
            LETTER BROADSHEET LEDGER TABLOID
            LEGAL EXECUTIVE 36X36/) {
    eval { $pdf->get_page_size($_) };
    is($@, '');
}

ok(!$pdf->close(), "Close PDF");

my %params = ('filenam' => "$pdfname",
              'Versin'  => 1.3,
              'PageMod' => 'UseOutlines',
              'Autho'   => 'Test Author',
              'Titl'    => 'Test Title',
              'Debg'    => 0,
              'Creatr'  => 'Test Creator',
              'Keyword' => 'Test Keywords');
foreach (keys %params) {
    eval { PDF::Create->new($_ => $params{$_}) };
    like($@, qr/Invalid constructor key '$_' received/);
}

eval { PDF::Create->new('PageMode' => 'UseOutline') };
like($@, qr/Invalid value for key 'PageMode' received 'UseOutline'/);

eval { PDF::Create->new('Debug' => 'abc') };
like($@, qr/Invalid value for key 'Debug' received 'abc'/);

done_testing();
