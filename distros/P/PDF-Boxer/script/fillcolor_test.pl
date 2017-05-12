#!/usr/bin/perl
use PDF::API2;

# setting fillcolor with an undefined value
# breaks the PDF in Adobe Reader & Photoshop

my ($pdf, $page, $font, $text);
$pdf = PDF::API2->new( -file => 'test_fillcolor_ok.pdf' );
$page = $pdf->page;
$page->mediabox(0, 0, 595, 842);
$font = $pdf->corefont('Helvetica');
$text = $page->text;
$text->font($font, 14);
$text->text('ello dere');
$pdf->save;

$pdf = PDF::API2->new( -file => 'test_fillcolor_nok.pdf' );
$page = $pdf->page;
$page->mediabox(0, 0, 595, 842);
$font = $pdf->corefont('Helvetica');
$text = $page->text;
$text->fillcolor(undef); # ***
$text->font($font, 14);
$text->text('ello dere');
$pdf->save;


