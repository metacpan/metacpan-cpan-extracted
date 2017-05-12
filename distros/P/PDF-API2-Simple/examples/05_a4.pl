#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( 
				 file => '05_a4.pdf',
				 height => 842,
				 width => 595,
				 margin_top => 80
				);

$pdf->add_font( 'Verdana' );
$pdf->add_page();

$pdf->text( 'This is text on an A4 pdf', x => 50, y => $pdf->height - 50 );

$pdf->save();
