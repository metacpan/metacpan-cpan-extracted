#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( 
				  file => '01_barebones.pdf'
				  );

$pdf->add_font( 'Verdana' );
$pdf->add_page();


$pdf->save();

