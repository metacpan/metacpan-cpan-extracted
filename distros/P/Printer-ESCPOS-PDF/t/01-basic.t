#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use XML::Printer::ESCPOS;
use Printer::ESCPOS::PDF;

# these are very basic tests ...

plan tests => 5;
 
my $printer = Printer::ESCPOS::PDF->new({ width => 815 });
is ref $printer, 'Printer::ESCPOS::PDF', 'Printer::ESCPOS::PDF object created.';

my $parser = XML::Printer::ESCPOS->new(
    printer => $printer,
);
is ref $parser, 'XML::Printer::ESCPOS', 'XML::Printer::ESCPOS object created.';

my $parsed = $parser->parse(q#
     <escpos>
        <qr version="4" moduleSize="4">Dont panic!</qr>
    </escpos>
#);
ok $parsed, 'parsed XML without errors';

my $pdf = $printer->get_pdf();
is substr($pdf, 0, 5), '%PDF-', 'it is a PDF file';
ok length($pdf) > 400, 'PDF length okay';
