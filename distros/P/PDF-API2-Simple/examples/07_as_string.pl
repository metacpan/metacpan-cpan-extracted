#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( );

$pdf->add_font( 'Verdana' );
$pdf->add_page();

$pdf->text( 'This PDF is printed to STDOUT!' );

print $pdf->stringify();

