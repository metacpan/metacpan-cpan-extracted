#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $pdf = PDF::API2::Simple->new( 
				  file => '03_autoflow.pdf',
				  line_height => 20,
				  margin_left => 5,
				  margin_top => 5,
				  margin_right => 5,
				  margin_bottom => 5
				  );

$pdf->add_font('VerdanaBold');
$pdf->add_font('Verdana');
$pdf->add_page();

$pdf->next_line;

$pdf->text( 'Demonstrating Text', 
	    x => ($pdf->width / 2),
	    font => 'VerdanaBold',
	    font_size => 12,
	    align => 'center' );

$pdf->set_font( 'Verdana' );

$pdf->next_line;
$pdf->next_line;

for (my $i = 0; $i < 250; $i++) {
    my $text = "$i - All work and no play makes Jack a dull boy";

    $pdf->text($text, autoflow => 'on');
}

$pdf->save();

