#!/usr/bin/perl

BEGIN { push @INC, '../lib'; }

use PDF::API2::Simple;

my $page_num = 1;
my $pdf = PDF::API2::Simple->new( 
				  file => '04_headers.pdf',
				  header => \&header,
				  footer => \&footer
				  );

$pdf->add_font('VerdanaBold');
$pdf->add_font('Verdana');
$pdf->add_page();

for (my $i = 0; $i < 250; $i++) {
    my $text = "$i - All work and no play makes Jack a dull boy";

    $pdf->text( $text, 
		x => $pdf->margin_left,
		autoflow => 'on' );
}

$pdf->save();

sub header {
    my $strokecolor = $pdf->strokecolor;

    $pdf->stroke_color( '#0000FF' );

    $pdf->next_line;
    $pdf->text( 'Unix time of report: ' . time() );

    $pdf->y( $pdf->y - 5 );

    $pdf->line( to_x => $pdf->effective_width,
		to_y => $pdf->y,
		stroke => 'on',
		fill => 'off',
		width => 2 );

    $pdf->y( $pdf->height - 60 );

    $pdf->strokecolor( $strokecolor );
}

sub footer {
    my $fillcolor = $pdf->fill_color;
    my $font = $pdf->current_font;

    $pdf->fill_color( '#552F55' );

    $pdf->set_font( 'VerdanaBold' );
    $pdf->text( 'Page ' . $page_num++,
		x => $pdf->effective_width,
		y => 20,
		align => 'right' );

    $pdf->fill_color( $fillcolor );
    $pdf->current_font( $font );
}

