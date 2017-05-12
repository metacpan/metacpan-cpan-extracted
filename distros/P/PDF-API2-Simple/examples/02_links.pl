#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( 
				  file => '02_links.pdf'
				  );

$pdf->add_font('Verdana');
$pdf->add_page();

$pdf->link( 'http://search.cpan.org', 'A Hyperlink',
	    x => ($pdf->width / 2),
	    y => ($pdf->height / 2),
	    align => 'left' );

$pdf->add_page();

$pdf->link( 'http://perlmonks.org', 'A fine link',
	    x => ($pdf->width / 2),
	    y => ($pdf->height / 2),
	    align => 'center' );

$pdf->add_page();

$pdf->link( 'http://pause.perl.org', 'Some other link',
	    x => ($pdf->width / 2),
	    y => ($pdf->height / 2),
	    align => 'right' );

$pdf->save();

